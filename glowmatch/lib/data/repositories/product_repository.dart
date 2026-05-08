import '../../core/supabase_client.dart';
import '../models/models.dart';

class ProductRepository {
  // Discovery feed: products sorted by mention count, optional category filter.
  Future<List<Product>> discoveryFeed({
    ProductCategory? category,
    int limit = 50,
  }) async {
    var q = sb
        .from('product_with_mention_count')
        .select('id, name, brand, category, sephora_url, ulta_url, mention_count');
    if (category != null && category != ProductCategory.other) {
      q = q.eq('category', category.name);
    }
    final rows = await q.order('mention_count', ascending: false).limit(limit);
    return (rows as List)
        .map((r) => Product.fromMap(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  // For You: products from user's twin creators that the user doesn't own.
  Future<List<Product>> forYouFeed({required String userId, int limit = 50}) async {
    final rows = await sb.rpc('recommended_products_for_user', params: {
      'p_user_id': userId,
      'p_limit': limit,
    });
    return (rows as List).map((r) {
      final m = Map<String, dynamic>.from(r as Map);
      return Product(
        id: m['id'] as String,
        name: m['name'] as String,
        brand: m['brand'] as String,
        category: categoryFromString(m['category'] as String?),
        sephoraUrl: m['sephora_url'] as String?,
        ultaUrl: m['ulta_url'] as String?,
        mentionCount: (m['total_mentions'] as int?) ?? 0,
      );
    }).toList();
  }

  Future<Product?> fetchProduct(String id) async {
    final row = await sb
        .from('product_with_mention_count')
        .select('id, name, brand, category, sephora_url, ulta_url, mention_count')
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : Product.fromMap(row);
  }

  Future<List<ProductShade>> fetchShades(String productId) async {
    final rows = await sb
        .from('product_shades')
        .select('id, product_id, shade_name, hex_color')
        .eq('product_id', productId)
        .order('shade_name');
    return (rows as List)
        .map((r) => ProductShade.fromMap(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  Future<List<TikTokMention>> fetchMentions(String productId, {int limit = 3}) async {
    final rows = await sb
        .from('tiktok_mentions')
        .select('id, product_id, video_url, sentiment_tags, view_count, thumbnail_url, created_at')
        .eq('product_id', productId)
        .order('view_count', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((r) => TikTokMention.fromMap(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  Future<List<SentimentTag>> fetchTopSentiments(String productId, {int top = 5}) async {
    final rows = await sb
        .from('product_top_sentiments')
        .select('tag, cnt')
        .eq('product_id', productId)
        .order('cnt', ascending: false)
        .limit(top);
    return (rows as List)
        .map((r) {
          final m = Map<String, dynamic>.from(r as Map);
          return SentimentTag(tag: m['tag'] as String, count: (m['cnt'] as int?) ?? 0);
        })
        .toList();
  }

  Future<YourShade?> fetchYourShade({required String userId, required String productId}) async {
    final rows = await sb.rpc('your_shade_for_product', params: {
      'p_user_id': userId,
      'p_product_id': productId,
    });
    final list = rows as List;
    if (list.isEmpty) return null;
    return YourShade.fromMap(Map<String, dynamic>.from(list.first as Map));
  }

  // Search across product name + brand. "hasMyShade" filter optionally
  // restricts to products with at least one shade entry that the user owns.
  Future<List<Product>> search({
    required String query,
    ProductCategory? category,
    String? userIdForOwnedShade,
  }) async {
    var q = sb
        .from('product_with_mention_count')
        .select('id, name, brand, category, sephora_url, ulta_url, mention_count');
    final clean = query.trim();
    if (clean.isNotEmpty) {
      // Postgres ilike OR pattern for name/brand.
      q = q.or('name.ilike.%$clean%,brand.ilike.%$clean%');
    }
    if (category != null && category != ProductCategory.other) {
      q = q.eq('category', category.name);
    }
    final rows = await q.order('mention_count', ascending: false).limit(80);
    final products = (rows as List)
        .map((r) => Product.fromMap(Map<String, dynamic>.from(r as Map)))
        .toList();

    if (userIdForOwnedShade == null) return products;

    // "Has my shade": keep products where the user owns at least one shade.
    final owned = await sb
        .from('user_owned_products')
        .select('product_id')
        .eq('user_id', userIdForOwnedShade);
    final ownedIds = (owned as List)
        .map((r) => Map<String, dynamic>.from(r as Map)['product_id'] as String)
        .toSet();
    return products.where((p) => ownedIds.contains(p.id)).toList();
  }
}
