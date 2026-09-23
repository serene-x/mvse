import '../../core/supabase_client.dart';
import '../models/models.dart';

/// Stores partial product-feedback updates.
class FeedbackRepository {
  Future<List<ProductFeedback>> fetchForUser(String userId) async {
    final rows = await sb
        .from('user_product_feedback')
        .select('*, products(*)')
        .eq('user_id', userId)
        .order('updated_at', ascending: false);
    return (rows as List)
        .map(
            (r) => ProductFeedback.fromMap(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  /// Upsert a feedback row. Only non-null args are written, so a caller can
  /// log "liked: yes" now and add a reaction later without clobbering.
  Future<void> upsertFeedback({
    required String userId,
    required String productId,
    String? liked,
    bool? stillUsing,
    Map<String, int>? attributeRatings,
    String? reaction,
    int? breakoutOnsetDays,
    String? breakoutLocation,
    String? breakoutType,
    String? breakoutDuration,
    List<String>? irritationKind,
    bool? otherNewProducts,
    List<String>? contextFlags,
    List<String>? shadeNotes,
    String? note,
  }) async {
    final row = <String, dynamic>{
      'user_id': userId,
      'product_id': productId,
    };
    if (liked != null) row['liked'] = liked;
    if (stillUsing != null) row['still_using'] = stillUsing;
    if (attributeRatings != null) row['attribute_ratings'] = attributeRatings;
    if (reaction != null) row['reaction'] = reaction;
    if (breakoutOnsetDays != null) {
      row['breakout_onset_days'] = breakoutOnsetDays;
    }
    if (breakoutLocation != null) row['breakout_location'] = breakoutLocation;
    if (breakoutType != null) row['breakout_type'] = breakoutType;
    if (breakoutDuration != null) row['breakout_duration'] = breakoutDuration;
    if (irritationKind != null) row['irritation_kind'] = irritationKind;
    if (otherNewProducts != null) row['other_new_products'] = otherNewProducts;
    if (contextFlags != null) row['context_flags'] = contextFlags;
    if (shadeNotes != null) row['shade_notes'] = shadeNotes;
    if (note != null) row['note'] = note;

    await sb
        .from('user_product_feedback')
        .upsert(row, onConflict: 'user_id,product_id');
  }

  Future<void> delete(
      {required String userId, required String productId}) async {
    await sb
        .from('user_product_feedback')
        .delete()
        .eq('user_id', userId)
        .eq('product_id', productId);
  }
}
