import '../../core/supabase_client.dart';
import '../models/models.dart';

class ProfileRepository {
  Future<UserProfile?> fetchProfile(String userId) async {
    final row = await sb
        .from('users')
        .select('id, skin_tone_desc, undertone, onboarding_complete, '
            'skin_type, skin_type_source, concerns, concerns_source, '
            'goals, sensitivities, inference_notes')
        .eq('id', userId)
        .maybeSingle();
    if (row == null) return null;
    return UserProfile.fromMap(row);
  }

  Future<UserProfile> updateProfile({
    required String userId,
    String? skinToneDesc,
    Undertone? undertone,
    bool? onboardingComplete,
    List<String>? skinType,
    String? skinTypeSource,
    List<String>? concerns,
    String? concernsSource,
    List<String>? goals,
    List<Map<String, dynamic>>? sensitivities,
    List<Map<String, dynamic>>? inferenceNotes,
  }) async {
    final patch = <String, dynamic>{};
    if (skinToneDesc != null) patch['skin_tone_desc'] = skinToneDesc;
    if (undertone != null) patch['undertone'] = undertone.name;
    if (onboardingComplete != null) {
      patch['onboarding_complete'] = onboardingComplete;
    }
    if (skinType != null) patch['skin_type'] = skinType;
    if (skinTypeSource != null) patch['skin_type_source'] = skinTypeSource;
    if (concerns != null) patch['concerns'] = concerns;
    if (concernsSource != null) patch['concerns_source'] = concernsSource;
    if (goals != null) patch['goals'] = goals;
    if (sensitivities != null) patch['sensitivities'] = sensitivities;
    if (inferenceNotes != null) patch['inference_notes'] = inferenceNotes;

    final row =
        await sb.from('users').update(patch).eq('id', userId).select().single();
    return UserProfile.fromMap(row);
  }

  Future<List<OwnedProduct>> fetchOwnedProducts(String userId) async {
    final rows = await sb
        .from('user_owned_products')
        .select(
            'user_id, product_id, shade_name, hex_color, opened_at, pao_months, products(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => OwnedProduct.fromMap(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  /// Mark a product opened (for PAO tracking). Defaults PAO months to the
  /// product's category default when not given.
  Future<void> setOpened({
    required String userId,
    required String productId,
    String? shadeName,
    required DateTime openedAt,
    int? paoMonths,
  }) async {
    await sb
        .from('user_owned_products')
        .update({
          'opened_at': openedAt.toIso8601String().split('T').first,
          if (paoMonths != null) 'pao_months': paoMonths,
        })
        .eq('user_id', userId)
        .eq('product_id', productId)
        .eq('shade_name', shadeName ?? '');
  }

  // shade_name is part of the primary key and therefore NOT NULL in the DB;
  // '' means "no shade". The null↔'' translation lives here so the rest of
  // the app can keep thinking in nullable shade names.
  Future<void> addOwnedProduct({
    required String userId,
    required String productId,
    String? shadeName,
    String? hexColor,
  }) async {
    await sb.from('user_owned_products').upsert({
      'user_id': userId,
      'product_id': productId,
      'shade_name': shadeName ?? '',
      'hex_color': hexColor,
    }, onConflict: 'user_id,product_id,shade_name');
  }

  Future<void> removeOwnedProduct({
    required String userId,
    required String productId,
    String? shadeName,
  }) async {
    await sb
        .from('user_owned_products')
        .delete()
        .eq('user_id', userId)
        .eq('product_id', productId)
        .eq('shade_name', shadeName ?? '');
  }

  // shade_name is part of the composite primary key, so editing it is a
  // delete-then-insert. Hex-only edits patch the existing row in place.
  Future<void> updateOwnedProductShade({
    required String userId,
    required String productId,
    required String? oldShadeName,
    required String? newShadeName,
    String? hexColor,
  }) async {
    if ((oldShadeName ?? '') == (newShadeName ?? '')) {
      await sb
          .from('user_owned_products')
          .update({'hex_color': hexColor})
          .eq('user_id', userId)
          .eq('product_id', productId)
          .eq('shade_name', oldShadeName ?? '');
      return;
    }
    await removeOwnedProduct(
        userId: userId, productId: productId, shadeName: oldShadeName);
    await addOwnedProduct(
      userId: userId,
      productId: productId,
      shadeName: newShadeName,
      hexColor: hexColor,
    );
  }
}
