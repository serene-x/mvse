import 'package:flutter_test/flutter_test.dart';
import 'package:mvse/logic/skin_profile.dart';

void main() {
  group('inferProfile', () {
    test('empty input yields no conclusions', () {
      final result = inferProfile([]);
      expect(result.isEmpty, isTrue);
      expect(result.skinTypes, isEmpty);
      expect(result.concerns, isEmpty);
    });

    test('multiple reactions point to sensitive skin', () {
      final result = inferProfile(const [
        ProfileSignal(
            productName: 'A', category: 'serum', reaction: 'irritation'),
        ProfileSignal(
            productName: 'B', category: 'moisturizer', reaction: 'dryness'),
      ]);
      expect(result.skinTypes, contains(SkinType.sensitive));
      // every conclusion carries a reason and a bounded confidence
      for (final f in result.facts) {
        expect(f.reason, isNotEmpty);
        expect(f.confidence, inInclusiveRange(0, 1));
      }
    });

    test('a logged breakout adds acne as a concern', () {
      final result = inferProfile(const [
        ProfileSignal(
            productName: 'A', category: 'sunscreen', reaction: 'breakout'),
      ]);
      expect(result.concerns, contains(SkinConcern.acne));
    });

    test('a single non-reacting product does not over-conclude', () {
      final result = inferProfile(const [
        ProfileSignal(
            productName: 'A',
            category: 'moisturizer',
            liked: 'yes',
            reaction: 'none'),
      ]);
      expect(result.skinTypes.contains(SkinType.sensitive), isFalse);
    });

    test('vocabulary round-trips through keys', () {
      for (final t in SkinType.values) {
        expect(skinTypeFromKey(skinTypeKeys[t]!), t);
      }
      for (final c in SkinConcern.values) {
        expect(concernFromKey(concernKeys[c]!), c);
      }
      for (final g in SkinGoal.values) {
        expect(goalFromKey(goalKeys[g]!), g);
      }
    });
  });
}
