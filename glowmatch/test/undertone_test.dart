import 'package:flutter_test/flutter_test.dart';
import 'package:mvse/logic/undertone.dart';

void main() {
  group('inferUndertone', () {
    test('no signals → honest "not enough yet"', () {
      final r = inferUndertone([]);
      expect(r.lean, isNull);
      expect(r.reasoning, contains('Not enough'));
    });

    test("brief's example: cool berry worked, coral didn't → cool lean", () {
      final r = inferUndertone(const [
        MakeupSignal(
            isFoundation: false,
            liked: true,
            colorFamily: ColorFamily.coolPinkBerry),
        MakeupSignal(
            isFoundation: false,
            liked: false,
            colorFamily: ColorFamily.warmCoralPeach),
      ]);
      expect(r.lean, UndertoneLean.cool);
      expect(r.oliveDetected, isFalse);
    });

    test('liked coral + warm brick, disliked cool berry → warm lean', () {
      final r = inferUndertone(const [
        MakeupSignal(
            isFoundation: false,
            liked: true,
            colorFamily: ColorFamily.warmCoralPeach),
        MakeupSignal(
            isFoundation: false,
            liked: true,
            colorFamily: ColorFamily.warmBrick),
        MakeupSignal(
            isFoundation: false,
            liked: false,
            colorFamily: ColorFamily.coolPinkBerry),
      ]);
      expect(r.lean, UndertoneLean.warm);
    });

    test('OLIVE: foundation goes grey/ashy → olive, its own category', () {
      final r = inferUndertone(const [
        MakeupSignal(
            isFoundation: true,
            liked: false,
            observations: [ShadeObservation.turnedGreyAshy]),
      ]);
      expect(r.lean, UndertoneLean.olive);
      expect(r.oliveDetected, isTrue);
      expect(r.reasoning.toLowerCase(), contains('olive'));
    });

    test('OLIVE: contradictory orange AND pink outcomes → olive', () {
      final r = inferUndertone(const [
        MakeupSignal(
            isFoundation: true,
            liked: false,
            observations: [ShadeObservation.oxidizedOrange]),
        MakeupSignal(
            isFoundation: true,
            liked: false,
            observations: [ShadeObservation.turnedPink]),
      ]);
      expect(r.lean, UndertoneLean.olive);
      expect(r.oliveDetected, isTrue);
    });

    test('olive result never claims a firm warm/cool season', () {
      final r = inferUndertone(const [
        MakeupSignal(
            isFoundation: true,
            liked: false,
            observations: [ShadeObservation.turnedGreyAshy]),
      ]);
      expect(r.season, isNot(contains('spring')));
      expect(r.season, isNull);
    });

    test('every result hedges and never states a verdict', () {
      final r = inferUndertone(const [
        MakeupSignal(
            isFoundation: false,
            liked: true,
            colorFamily: ColorFamily.coolPinkBerry),
      ]);
      expect(r.reasoning.toLowerCase(),
          anyOf(contains('guess'), contains('read'), contains('not a')));
    });

    test('skin depth does not determine a colour season', () {
      final r = inferUndertone(const [
        MakeupSignal(
            isFoundation: false,
            liked: true,
            colorFamily: ColorFamily.warmCoralPeach),
        MakeupSignal(
            isFoundation: false,
            liked: true,
            colorFamily: ColorFamily.warmBrick),
      ], depthHint: 'deep');
      expect(r.season, isNull);
    });
  });
}
