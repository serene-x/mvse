import '../data/beauty_details.dart';
import '../logic/shade_matching.dart';
import 'beauty_book.dart';
import 'shade_reports.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/models.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/feedback_repository.dart';
import '../data/repositories/ingredient_profile_repository.dart';
import '../data/repositories/ingredient_repository.dart';
import '../data/repositories/product_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../logic/finish.dart';
import '../logic/personalization.dart';
import '../logic/routine.dart';
import '../logic/undertone.dart';

final authRepositoryProvider = Provider((_) => AuthRepository());
final enabledSocialProvidersProvider =
    FutureProvider<Set<OAuthProvider>>((ref) {
  return ref.watch(authRepositoryProvider).enabledSocialProviders();
});

final profileRepositoryProvider = Provider((_) => ProfileRepository());
final productRepositoryProvider = Provider((_) => ProductRepository());
final ingredientRepositoryProvider = Provider((_) => IngredientRepository());
final feedbackRepositoryProvider = Provider((_) => FeedbackRepository());
final ingredientProfileRepositoryProvider =
    Provider((_) => IngredientProfileRepository());

final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final currentUserIdProvider = Provider<String?>((ref) {
  ref.watch(authStateChangesProvider);
  return ref.watch(authRepositoryProvider).currentUser?.id;
});

final currentUserProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final id = ref.watch(currentUserIdProvider);
  if (id == null) return null;
  return ref.watch(profileRepositoryProvider).fetchProfile(id);
});

final ownedProductsProvider = FutureProvider<List<OwnedProduct>>((ref) async {
  final id = ref.watch(currentUserIdProvider);
  if (id == null) return [];
  return ref.watch(profileRepositoryProvider).fetchOwnedProducts(id);
});

final userFeedbackProvider = FutureProvider<List<ProductFeedback>>((ref) async {
  final id = ref.watch(currentUserIdProvider);
  if (id == null) return [];
  return ref.watch(feedbackRepositoryProvider).fetchForUser(id);
});

final ingredientProfileProvider =
    FutureProvider<List<IngredientSignal>>((ref) async {
  final id = ref.watch(currentUserIdProvider);
  if (id == null) return const [];
  final repo = ref.watch(ingredientProfileRepositoryProvider);
  final records = await repo.reactionRecords(id);
  final flags = await repo.fetchFlags(id);
  return inferIngredientTriggers(records, flags: flags);
});

/// Ingredient rows keyed by id for anything in the profile: so the UI can
/// render names without another round-trip per row.
final profileIngredientNamesProvider =
    FutureProvider<Map<String, Ingredient>>((ref) async {
  final signals = await ref.watch(ingredientProfileProvider.future);
  if (signals.isEmpty) return const {};
  return ref
      .watch(ingredientProfileRepositoryProvider)
      .fetchIngredientsByIds(signals.map((s) => s.ingredientId).toList());
});

/// Compares a product’s key ingredients with the saved ingredient profile.
final productCompatibilityProvider =
    FutureProvider.family<CompatibilityResult, String>((ref, productId) async {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) {
    return const CompatibilityResult(level: Compatibility.unknown, message: '');
  }
  final profile = await ref.watch(ingredientProfileProvider.future);
  final keys = await ref.watch(keyIngredientsProvider(productId).future);
  return annotateProduct(
    productIngredientIds: keys.map((k) => k.ingredientId).toList(),
    profile: profile,
  );
});

/// Builds the AM/PM routine + conflict/synergy/coaching guidance from the
/// user's owned products.
final routinePlanProvider = FutureProvider<RoutinePlan>((ref) async {
  final owned = await ref.watch(ownedProductsProvider.future);
  final products = owned.where((o) => o.product != null).toList();
  if (products.isEmpty) {
    return const RoutinePlan(am: [], pm: [], guidance: []);
  }
  final ids = products.map((o) => o.productId).toList();
  final actives =
      await ref.watch(ingredientRepositoryProvider).activeProfileByProduct(ids);

  final routineProducts = products.map((o) {
    final p = o.product!;
    final a = actives[p.id];
    return RoutineProduct(
      id: p.id,
      name: p.name,
      category: categoryToString(p.category),
      activeFamilies: a?.families ?? const {},
      hasPotentActive: a?.hasPotent ?? false,
    );
  }).toList();

  return buildRoutine(routineProducts);
});

const _makeupCategories = {
  'foundation',
  'concealer',
  'blush',
  'bronzer',
  'highlighter',
  'eyeshadow',
  'eyeliner',
  'mascara',
  'brow',
  'lip',
  'setting_product',
};

/// Infer undertone + likely season from the user's makeup feedback (foundation
/// shade observations + blush/lip color-family taps).
final undertoneInferenceProvider =
    FutureProvider<UndertoneInference>((ref) async {
  final feedback = await ref.watch(userFeedbackProvider.future);
  final profile = ref.watch(currentUserProfileProvider).valueOrNull;

  final signals = <MakeupSignal>[];
  for (final f in feedback) {
    final cat = f.product?.category;
    if (cat == null || !_makeupCategories.contains(categoryToString(cat))) {
      continue;
    }
    final isFoundation = categoryToString(cat) == 'foundation';
    final obs = f.shadeNotes
        .map(shadeObservationFromKey)
        .whereType<ShadeObservation>()
        .toList();
    final families =
        f.shadeNotes.map(colorFamilyFromKey).whereType<ColorFamily>().toList();
    final family = families.isEmpty ? null : families.first;
    if (obs.isEmpty && family == null) continue;
    signals.add(MakeupSignal(
      isFoundation: isFoundation,
      liked: f.liked == 'yes',
      observations: obs,
      colorFamily: family,
    ));
  }

  return inferUndertone(signals, depthHint: profile?.skinToneDesc);
});

/// Learn finish preferences from makeup feedback (the 'finish' attribute rating
/// paired with each product's finish).
final finishPreferenceProvider = FutureProvider<FinishPreference>((ref) async {
  final feedback = await ref.watch(userFeedbackProvider.future);
  final signals = <FinishSignal>[];
  for (final f in feedback) {
    final finish = f.product?.finish;
    if (finish == null) continue;
    final rating = f.attributeRatings['finish'];
    if (rating == null || rating == 0) continue;
    signals.add(FinishSignal(finish: finish, liked: rating > 0));
  }
  return inferFinishPreference(signals);
});

final discoveryFeedProvider =
    FutureProvider.family<List<Product>, ProductCategory?>(
        (ref, category) async {
  return ref.watch(productRepositoryProvider).discoveryFeed(category: category);
});

final forYouFeedProvider = FutureProvider<List<Product>>((ref) async {
  if (ref.watch(currentUserIdProvider) == null) return [];
  final book = await ref.watch(beautyBookProvider.future);
  final details = await ref.watch(beautyDetailsProvider.future);
  final reports = await ref.watch(reviewedShadeReportsProvider.future);
  final catalog = await ref.watch(productRepositoryProvider).catalog();
  return catalog
      .where((p) =>
          !isSkincare(p.category) &&
          recommendShades('${p.brand.toLowerCase()}|${p.name.toLowerCase()}',
                  detailsFor(p, details), book,
                  complexion: [
                    ProductCategory.foundation,
                    ProductCategory.concealer
                  ].contains(p.category),
                  catalog: details,
                  groups: reports)
              .isNotEmpty)
      .take(30)
      .toList();
});

final productProvider = FutureProvider.family<Product?, String>((ref, id) {
  return ref.watch(productRepositoryProvider).fetchProduct(id);
});

final keyIngredientsProvider =
    FutureProvider.family<List<KeyIngredient>, String>((ref, productId) async {
  final product = await ref.watch(productProvider(productId).future);
  return ref
      .watch(ingredientRepositoryProvider)
      .keyIngredientsFor(productId, product: product);
});

final ingredientProvider =
    FutureProvider.family<Ingredient?, String>((ref, id) {
  return ref.watch(ingredientRepositoryProvider).fetchIngredient(id);
});

final ingredientListProvider =
    FutureProvider.family<List<Ingredient>, String>((ref, query) {
  return ref.watch(ingredientRepositoryProvider).listIngredients(query: query);
});

final ingredientClaimsProvider =
    FutureProvider.family<List<ProductClaim>, String>((ref, ingredientId) {
  return ref
      .watch(ingredientRepositoryProvider)
      .claimsForIngredient(ingredientId);
});

class SearchArgs {
  final String query;
  final ProductCategory? category;
  final bool hasMyShade;
  const SearchArgs(
      {required this.query, this.category, this.hasMyShade = false});

  @override
  bool operator ==(Object other) =>
      other is SearchArgs &&
      other.query == query &&
      other.category == category &&
      other.hasMyShade == hasMyShade;

  @override
  int get hashCode => Object.hash(query, category, hasMyShade);
}

final searchProvider =
    FutureProvider.family<List<Product>, SearchArgs>((ref, args) async {
  final uid = args.hasMyShade ? ref.watch(currentUserIdProvider) : null;
  return ref.watch(productRepositoryProvider).search(
        query: args.query,
        category: args.category,
        userIdForOwnedShade: uid,
      );
});
