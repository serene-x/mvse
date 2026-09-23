import '../../env.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../catalog.dart';
import '../../core/supabase_client.dart';
import '../models/models.dart';

class IngredientRepository {
  Future<List<KeyIngredient>> keyIngredientsFor(String productId,
      {Product? product}) async {
    if (product != null) {
      final bundle = jsonDecode(await rootBundle
          .loadString('assets/catalog/key_ingredients.json')) as Map;
      final rows = bundle[BundledCatalog.key(product)] as List?;
      if (rows != null) {
        return rows
            .map((r) => KeyIngredient.fromMap(Map<String, dynamic>.from(r)))
            .toList();
      }
    }
    if (!Env.backendAvailable || BundledCatalog.isLocal(productId)) return [];
    final rows = await sb
        .from('product_key_ingredients')
        .select('*, ingredients(*)')
        .eq('product_id', productId)
        .order('display_order');
    return (rows as List)
        .map((r) => KeyIngredient.fromMap(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  Future<Ingredient?> fetchIngredient(String id) async {
    if (!Env.backendAvailable) return null;
    final row =
        await sb.from('ingredients').select().eq('id', id).maybeSingle();
    return row == null ? null : Ingredient.fromMap(row);
  }

  Future<List<Ingredient>> listIngredients({String? query}) async {
    if (!Env.backendAvailable) return [];
    var q = sb.from('ingredients').select();
    final clean = query?.trim() ?? '';
    if (clean.isNotEmpty) {
      q = q.or('inci_name.ilike.%$clean%,common_name.ilike.%$clean%');
    }
    final rows = await q.order('common_name');
    return (rows as List)
        .map((r) => Ingredient.fromMap(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  Future<List<ProductClaim>> claimsForIngredient(String ingredientId) async {
    if (!Env.backendAvailable) return [];
    final rows =
        await sb.from('claims').select().eq('ingredient_id', ingredientId);
    return (rows as List)
        .map((r) => ProductClaim.fromMap(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  /// Active families used to order products and check routine combinations.
  Future<Map<String, ({Set<String> families, bool hasPotent})>>
      activeProfileByProduct(List<String> productIds) async {
    if (productIds.isEmpty) return {};
    final rows = await sb
        .from('product_key_ingredients')
        .select(
            'product_id, ingredients(active_family, is_cell_turnover_active)')
        .inFilter('product_id', productIds);

    final families = <String, Set<String>>{};
    final potent = <String, bool>{};
    for (final r in (rows as List)) {
      final m = Map<String, dynamic>.from(r as Map);
      final pid = m['product_id'] as String;
      final ing = m['ingredients'];
      if (ing is Map) {
        final fam = ing['active_family'] as String?;
        if (fam != null) (families[pid] ??= {}).add(fam);
        if (ing['is_cell_turnover_active'] == true) potent[pid] = true;
      }
    }
    return {
      for (final pid in productIds)
        pid: (
          families: families[pid] ?? <String>{},
          hasPotent: potent[pid] ?? false
        ),
    };
  }
}
