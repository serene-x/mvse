import 'package:flutter_test/flutter_test.dart';
import 'package:mvse/logic/personalization.dart';

void main() {
  group('classifyBreakout', () {
    test('active + early + usual zone + small + improving = likely purging',
        () {
      final r = classifyBreakout(const BreakoutSignal(
        hasCellTurnoverActive: true,
        activeName: 'salicylic acid',
        onsetDays: 10,
        location: 'usual',
        type: 'small_uniform',
        duration: 'improving',
      ));
      expect(r.verdict, BreakoutVerdict.likelyPurging);
      expect(r.reasoning, contains('salicylic acid'));
    });

    test('no active (moisturizer) cannot be purging', () {
      final r = classifyBreakout(const BreakoutSignal(
        hasCellTurnoverActive: false,
        onsetDays: 7,
        location: 'usual',
        type: 'small_uniform',
      ));
      expect(r.verdict, BreakoutVerdict.likelyReaction);
    });

    test('new areas flip an active product to likely reaction', () {
      final r = classifyBreakout(const BreakoutSignal(
        hasCellTurnoverActive: true,
        activeName: 'retinol',
        location: 'new',
        type: 'small_uniform',
      ));
      expect(r.verdict, BreakoutVerdict.likelyReaction);
    });

    test('cystic/painful triggers professional nudge', () {
      final r = classifyBreakout(const BreakoutSignal(
        hasCellTurnoverActive: true,
        type: 'cystic_painful',
      ));
      expect(r.seeProfessional, isTrue);
    });

    test('multiple new products at once = uncertain/confounded', () {
      final r = classifyBreakout(const BreakoutSignal(
        hasCellTurnoverActive: true,
        otherNewProducts: true,
        location: 'usual',
      ));
      expect(r.verdict, BreakoutVerdict.uncertain);
    });

    test('every assessment carries reasoning and guidance', () {
      final r =
          classifyBreakout(const BreakoutSignal(hasCellTurnoverActive: true));
      expect(r.reasoning, isNotEmpty);
      expect(r.guidance, isNotEmpty);
      expect(r.confidence, inInclusiveRange(0, 1));
    });
  });

  group('inferIngredientTriggers', () {
    test('two reactions sharing an ingredient (no tolerance) flags it', () {
      final signals = inferIngredientTriggers(const [
        ProductReactionRecord(
            productId: 'p1',
            ingredientIds: ['fragrance', 'glycerin'],
            reacted: true,
            tolerated: false),
        ProductReactionRecord(
            productId: 'p2',
            ingredientIds: ['fragrance', 'niacinamide'],
            reacted: true,
            tolerated: false),
      ]);
      final fragrance =
          signals.firstWhere((s) => s.ingredientId == 'fragrance');
      expect(fragrance.state, TriggerState.likelyTrigger);
      expect(fragrance.confidence, greaterThan(0));
    });

    test('KEY INSIGHT: an ingredient tolerated elsewhere is down-weighted', () {
      // "fragrance" reacts in 2 products but is tolerated in 3 others.
      final signals = inferIngredientTriggers(const [
        ProductReactionRecord(
            productId: 'p1',
            ingredientIds: ['fragrance'],
            reacted: true,
            tolerated: false),
        ProductReactionRecord(
            productId: 'p2',
            ingredientIds: ['fragrance'],
            reacted: true,
            tolerated: false),
        ProductReactionRecord(
            productId: 'p3',
            ingredientIds: ['fragrance'],
            reacted: false,
            tolerated: true),
        ProductReactionRecord(
            productId: 'p4',
            ingredientIds: ['fragrance'],
            reacted: false,
            tolerated: true),
        ProductReactionRecord(
            productId: 'p5',
            ingredientIds: ['fragrance'],
            reacted: false,
            tolerated: true),
      ]);
      final fragrance =
          signals.firstWhere((s) => s.ingredientId == 'fragrance');
      // 2 reactions - 0.5*3 tolerated = 0.5 effective suspicion < 1.5 → NOT flagged
      expect(fragrance.state, isNot(TriggerState.likelyTrigger));
    });

    test('a single reaction stays a quiet watch, not a trigger', () {
      final signals = inferIngredientTriggers(const [
        ProductReactionRecord(
            productId: 'p1',
            ingredientIds: ['x'],
            reacted: true,
            tolerated: false),
      ]);
      expect(signals.first.state, TriggerState.watch);
    });

    test('ingredient only in tolerated products is marked tolerated', () {
      final signals = inferIngredientTriggers(const [
        ProductReactionRecord(
            productId: 'p1',
            ingredientIds: ['squalane'],
            reacted: false,
            tolerated: true),
        ProductReactionRecord(
            productId: 'p2',
            ingredientIds: ['squalane'],
            reacted: false,
            tolerated: true),
      ]);
      expect(signals.first.state, TriggerState.tolerated);
    });

    test('user trigger flag wins over inference', () {
      final signals = inferIngredientTriggers(
        const [
          ProductReactionRecord(
              productId: 'p1',
              ingredientIds: ['x'],
              reacted: false,
              tolerated: true),
        ],
        flags: const UserIngredientFlags(triggers: {'x'}),
      );
      final x = signals.firstWhere((s) => s.ingredientId == 'x');
      expect(x.state, TriggerState.likelyTrigger);
      expect(x.userSet, isTrue);
    });

    test('dismissed ingredient never surfaces as a trigger', () {
      final signals = inferIngredientTriggers(
        const [
          ProductReactionRecord(
              productId: 'p1',
              ingredientIds: ['x'],
              reacted: true,
              tolerated: false),
          ProductReactionRecord(
              productId: 'p2',
              ingredientIds: ['x'],
              reacted: true,
              tolerated: false),
        ],
        flags: const UserIngredientFlags(dismissed: {'x'}),
      );
      final x = signals.firstWhere((s) => s.ingredientId == 'x');
      expect(x.state, isNot(TriggerState.likelyTrigger));
    });
  });

  group('annotateProduct', () {
    final profile = inferIngredientTriggers(const [
      ProductReactionRecord(
          productId: 'p1',
          ingredientIds: ['bad'],
          reacted: true,
          tolerated: false),
      ProductReactionRecord(
          productId: 'p2',
          ingredientIds: ['bad'],
          reacted: true,
          tolerated: false),
      ProductReactionRecord(
          productId: 'p3',
          ingredientIds: ['good'],
          reacted: false,
          tolerated: true),
      ProductReactionRecord(
          productId: 'p4',
          ingredientIds: ['good'],
          reacted: false,
          tolerated: true),
    ]);

    test('product with a flagged trigger → trigger annotation', () {
      final r =
          annotateProduct(productIngredientIds: ['bad'], profile: profile);
      expect(r.level, Compatibility.trigger);
      expect(r.flaggedIngredientIds, contains('bad'));
    });

    test('product with only tolerated ingredients → compatible', () {
      final r =
          annotateProduct(productIngredientIds: ['good'], profile: profile);
      expect(r.level, Compatibility.compatible);
    });

    test('empty profile → unknown, honest about it', () {
      final r =
          annotateProduct(productIngredientIds: ['good'], profile: const []);
      expect(r.level, Compatibility.unknown);
    });
  });
}
