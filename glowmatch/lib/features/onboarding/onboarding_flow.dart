import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/models.dart';
import '../../logic/skin_profile.dart';
import '../../providers/providers.dart';
import '../../theme.dart';
import 'about_skin_step.dart';
import 'owned_products_step.dart';
import 'skin_tone_step.dart';
import 'undertone_step.dart';

// Four-step onboarding controller. Holds state in memory; only writes to
// Supabase when the user completes the final step.
class OnboardingState {
  final String? skinToneDesc;
  final String? skinToneHex;
  final Undertone? undertone;
  final List<DraftOwnedProduct> ownedProducts;
  // "About your skin" step
  final Set<SkinType> skinType;
  final Set<SkinConcern> concerns;
  final Set<SkinGoal> goals;
  // If true, the user chose the "I don't know: figure it out from my
  // products" path, so we infer skin type/concerns instead of asking.
  final bool notSureAboutSkin;

  const OnboardingState({
    this.skinToneDesc,
    this.skinToneHex,
    this.undertone,
    this.ownedProducts = const [],
    this.skinType = const {},
    this.concerns = const {},
    this.goals = const {},
    this.notSureAboutSkin = false,
  });

  OnboardingState copyWith({
    String? skinToneDesc,
    String? skinToneHex,
    Undertone? undertone,
    List<DraftOwnedProduct>? ownedProducts,
    Set<SkinType>? skinType,
    Set<SkinConcern>? concerns,
    Set<SkinGoal>? goals,
    bool? notSureAboutSkin,
  }) =>
      OnboardingState(
        skinToneDesc: skinToneDesc ?? this.skinToneDesc,
        skinToneHex: skinToneHex ?? this.skinToneHex,
        undertone: undertone ?? this.undertone,
        ownedProducts: ownedProducts ?? this.ownedProducts,
        skinType: skinType ?? this.skinType,
        concerns: concerns ?? this.concerns,
        goals: goals ?? this.goals,
        notSureAboutSkin: notSureAboutSkin ?? this.notSureAboutSkin,
      );
}

class DraftOwnedProduct {
  final Product product;
  final String? shadeName;
  final String? hexColor;
  // Optional quick-feedback for the inference path.
  final String? liked; // 'yes' | 'no' | 'meh'
  final String?
      reaction; // 'none' | 'breakout' | 'irritation' | 'dryness' | 'other'
  const DraftOwnedProduct({
    required this.product,
    this.shadeName,
    this.hexColor,
    this.liked,
    this.reaction,
  });

  DraftOwnedProduct copyWith({String? liked, String? reaction}) =>
      DraftOwnedProduct(
        product: product,
        shadeName: shadeName,
        hexColor: hexColor,
        liked: liked ?? this.liked,
        reaction: reaction ?? this.reaction,
      );
}

class OnboardingController extends StateNotifier<OnboardingState> {
  OnboardingController() : super(const OnboardingState());

  void setSkinTone(String desc, String hex) =>
      state = state.copyWith(skinToneDesc: desc, skinToneHex: hex);

  void setUndertone(Undertone u) => state = state.copyWith(undertone: u);

  void toggleSkinType(SkinType t) {
    final next = {...state.skinType};
    next.contains(t) ? next.remove(t) : next.add(t);
    state = state.copyWith(skinType: next, notSureAboutSkin: false);
  }

  void toggleConcern(SkinConcern c) {
    final next = {...state.concerns};
    next.contains(c) ? next.remove(c) : next.add(c);
    state = state.copyWith(concerns: next, notSureAboutSkin: false);
  }

  void toggleGoal(SkinGoal g) {
    final next = {...state.goals};
    next.contains(g) ? next.remove(g) : next.add(g);
    state = state.copyWith(goals: next);
  }

  void setNotSure(bool v) => state = state.copyWith(
        notSureAboutSkin: v,
        skinType: v ? <SkinType>{} : state.skinType,
        concerns: v ? <SkinConcern>{} : state.concerns,
      );

  void addOwned(DraftOwnedProduct p) {
    if (state.ownedProducts.length >= 10) return;
    state = state.copyWith(ownedProducts: [...state.ownedProducts, p]);
  }

  void updateOwned(int i, DraftOwnedProduct p) {
    final next = [...state.ownedProducts]..[i] = p;
    state = state.copyWith(ownedProducts: next);
  }

  void removeOwned(int i) {
    final next = [...state.ownedProducts]..removeAt(i);
    state = state.copyWith(ownedProducts: next);
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingController, OnboardingState>(
        (_) => OnboardingController());

class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});
  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  static const _lastStep = 3;
  int _step = 0;
  bool _saving = false;
  String? _error;

  void _next() => setState(() => _step = (_step + 1).clamp(0, _lastStep));
  void _back() => setState(() => _step = (_step - 1).clamp(0, _lastStep));

  Future<void> _finish() async {
    final st = ref.read(onboardingProvider);
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final profileRepo = ref.read(profileRepositoryProvider);
      final feedbackRepo = ref.read(feedbackRepositoryProvider);

      // Save owned products (+ any quick feedback) first.
      for (final p in st.ownedProducts) {
        await profileRepo.addOwnedProduct(
          userId: uid,
          productId: p.product.id,
          shadeName: p.shadeName,
          hexColor: p.hexColor,
        );
        if (p.liked != null || p.reaction != null) {
          await feedbackRepo.upsertFeedback(
            userId: uid,
            productId: p.product.id,
            liked: p.liked,
            reaction: p.reaction,
          );
        }
      }

      // Build the profile: stated answers, or inferred from products if the
      // user took the "I'm not sure" path. Either way we record provenance.
      List<String> skinType = st.skinType.map((t) => skinTypeKeys[t]!).toList();
      List<String> concerns = st.concerns.map((c) => concernKeys[c]!).toList();
      String skinTypeSource = 'stated';
      String concernsSource = 'stated';
      List<Map<String, dynamic>> inferenceNotes = const [];

      final wantsInference =
          st.notSureAboutSkin || (skinType.isEmpty && concerns.isEmpty);
      if (wantsInference && st.ownedProducts.isNotEmpty) {
        final signals = st.ownedProducts
            .map((p) => ProfileSignal(
                  productName: p.product.name,
                  category: categoryToString(p.product.category),
                  liked: p.liked,
                  reaction: p.reaction,
                ))
            .toList();
        final inferred = inferProfile(signals);
        if (inferred.skinTypes.isNotEmpty) {
          skinType = inferred.skinTypes.map((t) => skinTypeKeys[t]!).toList();
          skinTypeSource = 'inferred';
        }
        if (inferred.concerns.isNotEmpty) {
          concerns = inferred.concerns.map((c) => concernKeys[c]!).toList();
          concernsSource = 'inferred';
        }
        inferenceNotes = inferred.facts.map((f) => f.toJson()).toList();
      }

      await profileRepo.updateProfile(
        userId: uid,
        skinToneDesc: st.skinToneDesc,
        undertone: st.undertone,
        onboardingComplete: true,
        skinType: skinType,
        skinTypeSource: skinTypeSource,
        concerns: concerns,
        concernsSource: concernsSource,
        goals: st.goals.map((g) => goalKeys[g]!).toList(),
        inferenceNotes: inferenceNotes,
      );

      // Await the updated profile before navigating, or the router redirects back to onboarding.
      ref.invalidate(currentUserProfileProvider);
      ref.invalidate(ownedProductsProvider);
      await ref.read(currentUserProfileProvider.future);
      if (mounted) context.go('/discovery');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(onboardingProvider);
    // Skin-tone/undertone are for shade matching; keep them required. The
    // About step is skippable via "I'm not sure". Products optional.
    final canForward = switch (_step) {
      0 => st.skinToneDesc != null,
      1 => st.undertone != null,
      _ => true,
    };

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Steps(active: _step),
              const SizedBox(height: 24),
              Expanded(
                child: IndexedStack(
                  index: _step,
                  children: const [
                    SkinToneStep(),
                    UndertoneStep(),
                    AboutSkinStep(),
                    OwnedProductsStep(),
                  ],
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_error!,
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 12)),
                ),
              Row(
                children: [
                  if (_step > 0)
                    OutlinedButton(onPressed: _back, child: const Text('Back')),
                  const Spacer(),
                  if (_step < _lastStep)
                    ElevatedButton(
                      onPressed: canForward ? _next : null,
                      child: const Text('Next'),
                    )
                  else
                    ElevatedButton(
                      onPressed: _saving ? null : _finish,
                      child: Text(_saving ? 'Saving…' : 'Finish'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Steps extends StatelessWidget {
  final int active;
  const _Steps({required this.active});

  @override
  Widget build(BuildContext context) {
    const labels = ['Skin tone', 'Undertone', 'Your skin', 'Products'];
    return Row(
      children: List.generate(labels.length, (i) {
        final on = i <= active;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < labels.length - 1 ? 8 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: on ? AppPalette.rose : AppPalette.stroke,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 6),
                Text(labels[i],
                    style: TextStyle(
                      fontSize: 11,
                      color: on ? AppPalette.text : AppPalette.textMuted,
                      fontWeight: on ? FontWeight.w600 : FontWeight.w400,
                    )),
              ],
            ),
          ),
        );
      }),
    );
  }
}
