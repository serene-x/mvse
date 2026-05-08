import '../../core/supabase_client.dart';
import '../models/models.dart';

class ShadeTwinRepository {
  Future<List<ShadeTwinMatch>> matchesForUser({required String userId, int limit = 10}) async {
    final rows = await sb.rpc('match_user_to_creators', params: {
      'p_user_id': userId,
      'p_limit': limit,
    });
    return (rows as List)
        .map((r) => ShadeTwinMatch.fromMap(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  // Products mentioned by a specific creator that the user doesn't own.
  Future<List<Product>> creatorRecommendationsFor({
    required String userId,
    required String creatorId,
    int limit = 30,
  }) async {
    final mentions = await sb
        .from('tiktok_mentions')
        .select('product_id, tiktok_videos!inner(creator_id)')
        .eq('tiktok_videos.creator_id', creatorId);

    final productIds = (mentions as List)
        .map((r) => Map<String, dynamic>.from(r as Map)['product_id'] as String)
        .toSet();

    if (productIds.isEmpty) return [];

    final owned = await sb
        .from('user_owned_products')
        .select('product_id')
        .eq('user_id', userId);
    final ownedIds = (owned as List)
        .map((r) => Map<String, dynamic>.from(r as Map)['product_id'] as String)
        .toSet();

    final candidateIds = productIds.difference(ownedIds).toList();
    if (candidateIds.isEmpty) return [];

    final products = await sb
        .from('product_with_mention_count')
        .select('id, name, brand, category, sephora_url, ulta_url, mention_count')
        .inFilter('id', candidateIds)
        .order('mention_count', ascending: false)
        .limit(limit);

    return (products as List)
        .map((r) => Product.fromMap(Map<String, dynamic>.from(r as Map)))
        .toList();
  }
}
