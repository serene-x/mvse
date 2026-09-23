import 'package:flutter_test/flutter_test.dart';
import 'package:mvse/data/models/models.dart';
import 'package:mvse/logic/safety.dart';

KeyIngredient _ki(String id,
    {bool preg = false,
    bool frag = false,
    int? comedo,
    String? family,
    String inci = 'X'}) {
  return KeyIngredient(
    id: id,
    productId: 'p',
    ingredientId: id,
    ingredient: Ingredient(
      id: id,
      inciName: inci,
      commonName: inci,
      pregnancyCaution: preg,
      isFragrance: frag,
      comedogenicRating: comedo,
      activeFamily: family,
    ),
  );
}

void main() {
  group('productSafetyFlags', () {
    test('pregnancy-caution ingredient produces a pregnancy flag', () {
      final flags = productSafetyFlags(
        keyIngredients: [_ki('retinol', preg: true, inci: 'Retinol')],
        categoryKey: 'serum',
      );
      expect(flags.any((f) => f.kind == SafetyKind.pregnancy), isTrue);
      expect(
          flags.first.detail.toLowerCase(), contains('check with your doctor'));
    });

    test('fragrance produces a gentle, non-alarmist flag', () {
      final flags = productSafetyFlags(
        keyIngredients: [_ki('parfum', frag: true, inci: 'Parfum')],
        categoryKey: 'moisturizer',
      );
      final f = flags.firstWhere((f) => f.kind == SafetyKind.fragrance);
      expect(f.detail.toLowerCase(), contains('most people'));
    });

    test('PRINCIPLE: user tolerance overrides a generic comedogenic warning',
        () {
      final flags = productSafetyFlags(
        keyIngredients: [_ki('coconut', comedo: 4, inci: 'Coconut Oil')],
        categoryKey: 'face_oil',
        userTolerated: {'coconut'},
      );
      final f = flags.firstWhere((f) => f.kind == SafetyKind.comedogenic);
      expect(f.detail.toLowerCase(), contains('doesn\'t apply'));
    });

    test('comedogenic flag without tolerance is labeled general & contested',
        () {
      final flags = productSafetyFlags(
        keyIngredients: [_ki('coconut', comedo: 4, inci: 'Coconut Oil')],
        categoryKey: 'face_oil',
      );
      final f = flags.firstWhere((f) => f.kind == SafetyKind.comedogenic);
      expect(f.detail.toLowerCase(), contains('contested'));
    });

    test('mineral sunscreen flags a possible white cast', () {
      final flags = productSafetyFlags(
        keyIngredients: [_ki('zinc', family: 'uv_filter', inci: 'Zinc Oxide')],
        categoryKey: 'sunscreen',
      );
      expect(flags.any((f) => f.kind == SafetyKind.whiteCast), isTrue);
    });

    test('non-sunscreen never gets a white-cast flag', () {
      final flags = productSafetyFlags(
        keyIngredients: [_ki('zinc', family: 'uv_filter', inci: 'Zinc Oxide')],
        categoryKey: 'moisturizer',
      );
      expect(flags.any((f) => f.kind == SafetyKind.whiteCast), isFalse);
    });
  });

  group('paoStatus', () {
    final now = DateTime(2026, 7, 1);

    test('untracked when data missing', () {
      expect(paoStatus(now: now).tracked, isFalse);
    });

    test('past PAO is flagged gently, not as unsafe', () {
      final s =
          paoStatus(openedAt: DateTime(2025, 1, 1), paoMonths: 6, now: now);
      expect(s.tracked, isTrue);
      expect(s.monthsLeft! < 0, isTrue);
      expect(s.message.toLowerCase(), contains('not necessarily unsafe'));
    });

    test('fresh product reports months left', () {
      final s =
          paoStatus(openedAt: DateTime(2026, 6, 1), paoMonths: 12, now: now);
      expect(s.tracked, isTrue);
      expect(s.monthsLeft! > 0, isTrue);
    });
  });
}
