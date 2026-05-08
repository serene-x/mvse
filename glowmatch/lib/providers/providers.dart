import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/models.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/product_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/shade_twin_repository.dart';

final authRepositoryProvider = Provider((_) => AuthRepository());
final profileRepositoryProvider = Provider((_) => ProfileRepository());
final productRepositoryProvider = Provider((_) => ProductRepository());
final shadeTwinRepositoryProvider = Provider((_) => ShadeTwinRepository());

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

final discoveryFeedProvider =
    FutureProvider.family<List<Product>, ProductCategory?>((ref, category) async {
  return ref.watch(productRepositoryProvider).discoveryFeed(category: category);
});

final forYouFeedProvider = FutureProvider<List<Product>>((ref) async {
  final id = ref.watch(currentUserIdProvider);
  if (id == null) return [];
  return ref.watch(productRepositoryProvider).forYouFeed(userId: id);
});

final productProvider = FutureProvider.family<Product?, String>((ref, id) {
  return ref.watch(productRepositoryProvider).fetchProduct(id);
});

final productMentionsProvider =
    FutureProvider.family<List<TikTokMention>, String>((ref, id) {
  return ref.watch(productRepositoryProvider).fetchMentions(id, limit: 3);
});

final productSentimentsProvider =
    FutureProvider.family<List<SentimentTag>, String>((ref, id) {
  return ref.watch(productRepositoryProvider).fetchTopSentiments(id, top: 5);
});

final yourShadeProvider = FutureProvider.family<YourShade?, String>((ref, productId) async {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return null;
  return ref.watch(productRepositoryProvider).fetchYourShade(userId: uid, productId: productId);
});

final shadeTwinsProvider = FutureProvider<List<ShadeTwinMatch>>((ref) async {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return [];
  return ref.watch(shadeTwinRepositoryProvider).matchesForUser(userId: uid);
});

final twinRecommendationsProvider =
    FutureProvider.family<List<Product>, String>((ref, creatorId) async {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return [];
  return ref
      .watch(shadeTwinRepositoryProvider)
      .creatorRecommendationsFor(userId: uid, creatorId: creatorId);
});

class SearchArgs {
  final String query;
  final ProductCategory? category;
  final bool hasMyShade;
  const SearchArgs({required this.query, this.category, this.hasMyShade = false});

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
