import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase_client.dart';
import '../env.dart';
import '../logic/shade_matching.dart';

final reviewedShadeReportsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final reports = <Map<String, dynamic>>[...communityGroups];
  if (!Env.backendAvailable) return reports;
  try {
    final rows = await sb
        .from('reviewed_shade_reports')
        .select('source_url,person,shades')
        .timeout(const Duration(seconds: 6));
    for (final row in rows) {
      final shades = Map<String, String>.from(row['shades'] as Map);
      if (shades.length >= 2) {
        reports.add({
          'source': row['source_url'],
          'person': row['person'],
          'shades': shades
        });
      }
    }
  } catch (_) {/* Bundled reviewed sources remain available offline. */}
  return reports;
});
