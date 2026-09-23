import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_client.dart';

final personalStorageProvider = Provider((_) => PersonalStorage());

/// Personal data is account-only and isolated by the database's owner policy.
class PersonalStorage {
  Future<Map<String, dynamic>?> read(
      String? userId, String kind, String guestKey) async {
    if (userId == null) return null;
    final row = await sb
        .from('user_beauty_data')
        .select('data')
        .eq('user_id', userId)
        .eq('kind', kind)
        .maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row['data'] as Map);
  }

  Future<void> write(String? userId, String kind, String guestKey,
      Map<String, dynamic> data) async {
    if (userId == null) throw StateError('Sign in to save personal data.');
    await sb.from('user_beauty_data').upsert({
      'user_id': userId,
      'kind': kind,
      'data': data,
      'updated_at': DateTime.now().toUtc().toIso8601String()
    }, onConflict: 'user_id,kind');
  }
}
