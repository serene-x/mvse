import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/models.dart';
import '../../providers/providers.dart';
import '../../theme.dart';
import 'owned_products_step.dart';
import 'skin_tone_step.dart';
import 'undertone_step.dart';

// Three-step onboarding controller. Holds state in memory; only writes to
// Supabase when the user completes the final step.
class OnboardingState {
  final String? skinToneDesc;
  final String? skinToneHex;
  final Undertone? undertone;
  final List<DraftOwnedProduct> ownedProducts;

  const OnboardingState({
    this.skinToneDesc,
    this.skinToneHex,
    this.undertone,
    this.ownedProducts = const [],
  });

  OnboardingState copyWith({
    String? skinToneDesc,
    String? skinToneHex,
    Undertone? undertone,
    List<DraftOwnedProduct>? ownedProducts,
  }) =>
      OnboardingState(
        skinToneDesc: skinToneDesc ?? this.skinToneDesc,
        skinToneHex: skinToneHex ?? this.skinToneHex,
        undertone: undertone ?? this.undertone,
        ownedProducts: ownedProducts ?? this.ownedProducts,
      );
}

class DraftOwnedProduct {
  final Product product;
  final String? shadeName;
  final String? hexColor;
  const DraftOwnedProduct({required this.product, this.shadeName, this.hexColor});
}

class OnboardingController extends StateNotifier<OnboardingState> {
  OnboardingController() : super(const OnboardingState());

  void setSkinTone(String desc, String hex) =>
      state = state.copyWith(skinToneDesc: desc, skinToneHex: hex);

  void setUndertone(Undertone u) => state = state.copyWith(undertone: u);

  void addOwned(DraftOwnedProduct p) {
    if (state.ownedProducts.length >= 10) return;
    state = state.copyWith(ownedProducts: [...state.ownedProducts, p]);
  }

  void removeOwned(int i) {
    final next = [...state.ownedProducts]..removeAt(i);
    state = state.copyWith(ownedProducts: next);
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingController, OnboardingState>((_) => OnboardingController());

class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});
  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  int _step = 0;
  bool _saving = false;
  String? _error;

  void _next() => setState(() => _step = (_step + 1).clamp(0, 2));
  void _back() => setState(() => _step = (_step - 1).clamp(0, 2));

  Future<void> _finish() async {
    final st = ref.read(onboardingProvider);
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;

    setState(() { _saving = true; _error = null; });
    try {
      final profileRepo = ref.read(profileRepositoryProvider);
      await profileRepo.updateProfile(
        userId: uid,
        skinToneDesc: st.skinToneDesc,
        undertone: st.undertone,
        onboardingComplete: true,
      );
      for (final p in st.ownedProducts) {
        await profileRepo.addOwnedProduct(
          userId: uid,
          productId: p.product.id,
          shadeName: p.shadeName,
          hexColor: p.hexColor,
        );
      }
      // Refresh profile so router redirect lets us through.
      ref.invalidate(currentUserProfileProvider);
      ref.invalidate(ownedProductsProvider);
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
    final canForwardFromStep0 = st.skinToneDesc != null;
    final canForwardFromStep1 = st.undertone != null;

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
                    OwnedProductsStep(),
                  ],
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                ),
              Row(
                children: [
                  if (_step > 0)
                    OutlinedButton(onPressed: _back, child: const Text('Back')),
                  const Spacer(),
                  if (_step == 0)
                    ElevatedButton(
                      onPressed: canForwardFromStep0 ? _next : null,
                      child: const Text('Next'),
                    )
                  else if (_step == 1)
                    ElevatedButton(
                      onPressed: canForwardFromStep1 ? _next : null,
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
    final labels = const ['Skin tone', 'Undertone', 'Your products'];
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
