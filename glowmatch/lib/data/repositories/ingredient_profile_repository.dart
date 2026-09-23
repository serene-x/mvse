import '../../core/supabase_client.dart';
import '../../logic/personalization.dart';
import '../models/models.dart';

/// Loads reaction records and persists manual ingredient flags.
class IngredientProfileRepository {
  /// Build per-product reaction records: each logged product reduced to its
  /// key ingredients + whether it reacted / was tolerated.
  Future<List<ProductReactionRecord>> reactionRecords(String userId) async {
    final feedback = await sb
        .from('user_product_feedback')
        .select('product_id, liked, reaction')
        .eq('user_id', userId);

    final rows = (feedback as List)
        .map((r) => Map<String, dynamic>.from(r as Map))
        .toList();
    if (rows.isEmpty) return [];

    final productIds =
        rows.map((r) => r['product_id'] as String).toSet().toList();

    // key ingredients for all those products in one query
    final keyRows = await sb
        .from('product_key_ingredients')
        .select('product_id, ingredient_id')
        .inFilter('product_id', productIds);
    final byProduct = <String, List<String>>{};
    for (final r in (keyRows as List)) {
      final m = Map<String, dynamic>.from(r as Map);
      (byProduct[m['product_id'] as String] ??= [])
          .add(m['ingredient_id'] as String);
    }

    return rows.map((r) {
      final reaction = r['reaction'] as String?;
      final liked = r['liked'] as String?;
      final reacted = reaction != null && reaction != 'none';
      // "tolerated" = used with no problem: no reaction logged, and not disliked.
      final tolerated =
          !reacted && (reaction == 'none' || liked == 'yes' || liked == 'meh');
      return ProductReactionRecord(
        productId: r['product_id'] as String,
        ingredientIds: byProduct[r['product_id']] ?? const [],
        reacted: reacted,
        tolerated: tolerated,
      );
    }).toList();
  }

  Future<UserIngredientFlags> fetchFlags(String userId) async {
    final rows = await sb
        .from('user_ingredient_flags')
        .select('ingredient_id, flag')
        .eq('user_id', userId);
    final triggers = <String>{};
    final tolerated = <String>{};
    final dismissed = <String>{};
    for (final r in (rows as List)) {
      final m = Map<String, dynamic>.from(r as Map);
      final id = m['ingredient_id'] as String;
      switch (m['flag'] as String?) {
        case 'trigger':
          triggers.add(id);
          break;
        case 'tolerated':
          tolerated.add(id);
          break;
        case 'dismissed':
          dismissed.add(id);
          break;
      }
    }
    return UserIngredientFlags(
        triggers: triggers, tolerated: tolerated, dismissed: dismissed);
  }

  Future<void> setFlag({
    required String userId,
    required String ingredientId,
    required String flag, // 'trigger' | 'tolerated' | 'dismissed'
    String? note,
  }) async {
    await sb.from('user_ingredient_flags').upsert({
      'user_id': userId,
      'ingredient_id': ingredientId,
      'flag': flag,
      'note': note,
    }, onConflict: 'user_id,ingredient_id');
  }

  Future<void> clearFlag({
    required String userId,
    required String ingredientId,
  }) async {
    await sb
        .from('user_ingredient_flags')
        .delete()
        .eq('user_id', userId)
        .eq('ingredient_id', ingredientId);
  }

  /// Fetch ingredient rows for a set of ids (to render names on the profile).
  Future<Map<String, Ingredient>> fetchIngredientsByIds(
      List<String> ids) async {
    if (ids.isEmpty) return {};
    final rows = await sb.from('ingredients').select().inFilter('id', ids);
    final out = <String, Ingredient>{};
    for (final r in (rows as List)) {
      final ing = Ingredient.fromMap(Map<String, dynamic>.from(r as Map));
      out[ing.id] = ing;
    }
    return out;
  }
}
