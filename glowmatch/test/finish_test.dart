import 'package:flutter_test/flutter_test.dart';
import 'package:mvse/logic/finish.dart';

void main() {
  group('inferFinishPreference', () {
    test('no signals → no recommendation', () {
      final r = inferFinishPreference([]);
      expect(r.hasSignal, isFalse);
      expect(r.recommendation, isNull);
    });

    test('consistent matte likes + dewy dislikes → matte preferred', () {
      final r = inferFinishPreference(const [
        FinishSignal(finish: 'matte', liked: true),
        FinishSignal(finish: 'soft matte', liked: true),
        FinishSignal(finish: 'dewy', liked: false),
      ]);
      expect(r.preferred, contains('matte'));
      expect(r.disliked, contains('dewy/radiant'));
      expect(r.recommendation, isNotNull);
      // hedged, not a rule
      expect(r.recommendation!.toLowerCase(), contains('not a hard rule'));
    });

    test('radiant/glow/dewy synonyms cluster together', () {
      final r = inferFinishPreference(const [
        FinishSignal(finish: 'radiant', liked: true),
        FinishSignal(finish: 'sheer glow', liked: true),
      ]);
      expect(r.preferred, contains('dewy/radiant'));
      expect(r.preferred.length, 1);
    });

    test('net-zero on a finish leaves it off both lists', () {
      final r = inferFinishPreference(const [
        FinishSignal(finish: 'satin', liked: true),
        FinishSignal(finish: 'satin', liked: false),
      ]);
      expect(r.preferred, isNot(contains('satin')));
      expect(r.disliked, isNot(contains('satin')));
    });
  });
}
