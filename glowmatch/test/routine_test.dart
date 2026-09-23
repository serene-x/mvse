import 'package:flutter_test/flutter_test.dart';
import 'package:mvse/logic/routine.dart';

RoutineProduct p(String name, String cat,
        {Set<String> fam = const {}, bool potent = false}) =>
    RoutineProduct(
        id: name,
        name: name,
        category: cat,
        activeFamilies: fam,
        hasPotentActive: potent);

void main() {
  group('buildRoutine ordering', () {
    test('sunscreen is AM-only and comes last in the morning', () {
      final plan = buildRoutine([
        p('SPF', 'sunscreen'),
        p('Cleanser', 'cleanser'),
        p('Moisturizer', 'moisturizer'),
      ]);
      expect(plan.am.last.product.name, 'SPF');
      expect(plan.pm.any((s) => s.product.name == 'SPF'), isFalse);
    });

    test('cleanser appears in both AM and PM', () {
      final plan = buildRoutine([p('Cleanser', 'cleanser')]);
      expect(plan.am.any((s) => s.product.name == 'Cleanser'), isTrue);
      expect(plan.pm.any((s) => s.product.name == 'Cleanser'), isTrue);
    });

    test('retinoid is placed at night, vitamin C in the morning', () {
      final plan = buildRoutine([
        p('Retinol', 'serum', fam: {'retinoid'}, potent: true),
        p('Vit C', 'serum', fam: {'vitamin_c'}, potent: true),
      ]);
      expect(plan.pm.any((s) => s.product.name == 'Retinol'), isTrue);
      expect(plan.am.any((s) => s.product.name == 'Vit C'), isTrue);
    });
  });

  group('conflict rules', () {
    test('vitamin C + retinol → separate-routines guidance', () {
      final plan = buildRoutine([
        p('Retinol', 'serum', fam: {'retinoid'}, potent: true),
        p('Vit C', 'serum', fam: {'vitamin_c'}, potent: true),
      ]);
      expect(
        plan.guidance.any((g) =>
            g.kind == GuidanceKind.conflict &&
            g.title.contains('vitamin C and retinol')),
        isTrue,
      );
    });

    test('benzoyl peroxide + retinoid → deactivation warning', () {
      final plan = buildRoutine([
        p('BP', 'treatment', fam: {'benzoyl_peroxide'}),
        p('Retinol', 'serum', fam: {'retinoid'}, potent: true),
      ]);
      expect(
          plan.guidance
              .any((g) => g.title.contains('Benzoyl peroxide can deactivate')),
          isTrue);
    });

    test('two exfoliants → over-exfoliation caution', () {
      final plan = buildRoutine([
        p('AHA toner', 'exfoliant', fam: {'aha'}, potent: true),
        p('BHA liquid', 'exfoliant', fam: {'bha'}, potent: true),
      ]);
      expect(
          plan.guidance.any((g) => g.title.contains('more than one exfoliant')),
          isTrue);
    });

    test('MYTH RETIRED: niacinamide + vitamin C produces NO conflict', () {
      final plan = buildRoutine([
        p('Niacinamide', 'serum', fam: {'vitamin_b3'}),
        p('Vit C', 'serum', fam: {'vitamin_c'}, potent: true),
      ]);
      final texts =
          plan.guidance.map((g) => '${g.title} ${g.detail}'.toLowerCase());
      expect(
          texts.any((t) => t.contains('niacinamide') && t.contains('cancel')),
          isFalse);
    });
  });

  group('synergies & coaching', () {
    test('azelaic + retinoid → recommended pairing', () {
      final plan = buildRoutine([
        p('Azelaic', 'treatment', fam: {'azelaic'}, potent: true),
        p('Retinol', 'serum', fam: {'retinoid'}, potent: true),
      ]);
      expect(
          plan.guidance.any((g) =>
              g.kind == GuidanceKind.synergy && g.title.contains('Azelaic')),
          isTrue);
    });

    test('a potent active triggers slow-introduction coaching', () {
      final plan = buildRoutine([
        p('Retinol', 'serum', fam: {'retinoid'}, potent: true)
      ]);
      expect(plan.guidance.any((g) => g.kind == GuidanceKind.coaching), isTrue);
    });

    test('gentle-only routine produces no coaching or conflicts', () {
      final plan = buildRoutine([
        p('Cleanser', 'cleanser'),
        p('Moisturizer', 'moisturizer'),
      ]);
      expect(plan.guidance, isEmpty);
    });
  });
}
