import '../../core/supabase_client.dart';
import '../models/models.dart';

class ProfileRepository {
  Future<UserProfile?> fetchProfile(String userId) async {
    final row = await sb
        .from('users')
        .select('id, skin_tone_desc, undertone, onboarding_complete')
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
  }) async {
    final patch = <String, dynamic>{};
    if (skinToneDesc != null)        patch['skin_tone_desc'] = skinToneDesc;
    if (undertone != null)           patch['undertone']      = undertone.name;
    if (onboardingComplete != null)  patch['onboarding_complete'] = onboardingComplete;

    final row = await sb
        .from('users')
        .update(patch)
        .eq('id', userId)
        .select()
        .single();
    return UserProfile.fromMap(row);
  }

  Future<List<OwnedProduct>> fetchOwnedProducts(String userId) async {
    final rows = await sb
        .from('user_owned_products')
        .select('user_id, product_id, shade_name, hex_color, products(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => OwnedProduct.fromMap(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  Future<void> addOwnedProduct({
    required String userId,
    required String productId,
    String? shadeName,
    String? hexColor,
  }) async {
    await sb.from('user_owned_products').upsert({
      'user_id': userId,
      'product_id': productId,
      'shade_name': shadeName,
      'hex_color': hexColor,
    }, onConflict: 'user_id,product_id,shade_name');
  }

  Future<void> removeOwnedProduct({
    required String userId,
    required String productId,
    String? shadeName,
  }) async {
    var q = sb.from('user_owned_products').delete()
        .eq('user_id', userId)
        .eq('product_id', productId);
    q = shadeName != null
        ? q.eq('shade_name', shadeName)
        : q.filter('shade_name', 'is', null);
    await q;
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
    if (oldShadeName == newShadeName) {
      var u = sb.from('user_owned_products')
          .update({'hex_color': hexColor})
          .eq('user_id', userId)
          .eq('product_id', productId);
      u = oldShadeName != null
          ? u.eq('shade_name', oldShadeName)
          : u.filter('shade_name', 'is', null);
      await u;
      return;
    }
    await removeOwnedProduct(userId: userId, productId: productId, shadeName: oldShadeName);
    await addOwnedProduct(
      userId: userId,
      productId: productId,
      shadeName: newShadeName,
      hexColor: hexColor,
    );
  }
}
