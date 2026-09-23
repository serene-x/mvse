import '../../env.dart';
import '../catalog.dart';
import '../beauty_details.dart';
import '../../core/supabase_client.dart';
import '../models/models.dart';

class ProductRepository {
  Future<List<Product>>? _catalog;
  bool bundledOnly = !Env.backendAvailable;

  void refresh() {
    _catalog = null;
  }

  Future<List<Product>> catalog() => _catalog ??= _loadCatalog();

  Future<List<Product>> _loadCatalog() async {
    final local = await BundledCatalog.load();
    if (!Env.backendAvailable) return local;
    try {
      final rows = await sb
          .from('product_with_mention_count')
          .select()
          .order('name')
          .limit(1000)
          .timeout(const Duration(seconds: 5));
      final merged = {for (final p in local) BundledCatalog.key(p): p};
      for (final row in rows) {
        final p = Product.fromMap(row);
        merged[BundledCatalog.key(p)] = p;
      }
      bundledOnly = rows.isEmpty;
      return merged.values.toList();
    } catch (_) {
      bundledOnly = true;
      return local;
    }
  }

  Future<List<Product>> discoveryFeed(
      {ProductCategory? category, int limit = 1000}) async {
    final products = await catalog();
    return products
        .where((p) =>
            category == null ||
            (category == ProductCategory.skincare
                ? isSkincare(p.category)
                : p.category == category))
        .take(limit)
        .toList();
  }

  Future<Product?> fetchProduct(String id) async {
    final products = await catalog();
    for (final product in products) {
      if (product.id == id) return product;
    }
    // A bookmarked bundled URL also resolves when a live row replaces it.
    for (final product in await BundledCatalog.load()) {
      if (product.id == id) return product;
    }
    if (!Env.backendAvailable || BundledCatalog.isLocal(id)) return null;
    final row = await sb
        .from('product_with_mention_count')
        .select()
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : Product.fromMap(row);
  }

  Future<List<ProductShade>> fetchShades(String productId) async {
    final product = await fetchProduct(productId);
    if (product != null && isSkincare(product.category)) return [];
    final details = await loadBeautyDetails();
    final listed =
        product == null ? null : details[BundledCatalog.key(product)];
    if (listed != null && listed.shades.isNotEmpty) {
      return listed.shades
          .map((s) =>
              ProductShade(id: s.name, productId: productId, shadeName: s.name))
          .toList();
    }
    if (!Env.backendAvailable || BundledCatalog.isLocal(productId)) return [];
    final rows = await sb
        .from('product_shades')
        .select('id, product_id, shade_name, hex_color')
        .eq('product_id', productId)
        .order('shade_name');
    return (rows as List)
        .map((r) => ProductShade.fromMap(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  // Search across product name + brand. "hasMyShade" filter optionally
  // restricts to products with at least one shade entry that the user owns.
  Future<List<Product>> search({
    required String query,
    ProductCategory? category,
    String? userIdForOwnedShade,
  }) async {
    final words = query.toLowerCase().trim().split(RegExp(r'\s+'));
    final all = await discoveryFeed(category: category);
    final products = all.where((p) {
      final text =
          '${p.brand} ${p.name} ${categoryLabel(p.category)}'.toLowerCase();
      return words.every(text.contains);
    }).toList();

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
