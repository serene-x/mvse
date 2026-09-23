import 'package:flutter_test/flutter_test.dart';
import 'package:mvse/logic/pricing.dart';

CategoryPriceStat stat(double avg, {int n = 8, String unit = 'ml'}) =>
    CategoryPriceStat(category: 'serum', unit: unit, n: n, avgPerUnit: avg);

void main() {
  group('pricePerUnit', () {
    test('divides price by size', () {
      expect(pricePerUnit(30, 30), 1.0);
      expect(pricePerUnit(24, 48), 0.5);
    });
    test('null when inputs missing or size non-positive', () {
      expect(pricePerUnit(null, 30), isNull);
      expect(pricePerUnit(30, null), isNull);
      expect(pricePerUnit(30, 0), isNull);
    });
  });

  group('priceInsight', () {
    test('empty when price or size missing', () {
      final i = priceInsight(
        priceUsd: null,
        sizeValue: 30,
        sizeUnit: 'ml',
        categoryLabel: 'serum',
        stat: stat(1.0),
      );
      expect(i.verdict, ValueVerdict.unknown);
      expect(i.pricePerUnit, isNull);
    });

    test('no verdict (unknown) when too few peers, but still reports per-unit',
        () {
      final i = priceInsight(
        priceUsd: 30,
        sizeValue: 30,
        sizeUnit: 'ml',
        categoryLabel: 'serum',
        stat: stat(1.0, n: 2),
      );
      expect(i.pricePerUnit, 1.0);
      expect(i.verdict, ValueVerdict.unknown);
      expect(i.phrase, isNull);
    });

    test('KEY INSIGHT: cheaper-per-ml than the category average is called out',
        () {
      // $0.50/ml vs $1.00/ml average → clearly a better deal
      final i = priceInsight(
        priceUsd: 15,
        sizeValue: 30,
        sizeUnit: 'ml',
        categoryLabel: 'serum',
        stat: stat(1.0),
      );
      expect(i.verdict, ValueVerdict.cheaper);
      expect(i.phrase, contains('better deal'));
    });

    test('pricier when well above the average', () {
      final i = priceInsight(
        priceUsd: 60,
        sizeValue: 30,
        sizeUnit: 'ml',
        categoryLabel: 'serum',
        stat: stat(1.0),
      );
      expect(i.verdict, ValueVerdict.pricier);
      expect(i.phrase, contains('pricier'));
    });

    test('typical when within the ±band', () {
      final i = priceInsight(
        priceUsd: 30,
        sizeValue: 30,
        sizeUnit: 'ml',
        categoryLabel: 'serum',
        stat: stat(1.0),
      );
      expect(i.verdict, ValueVerdict.typical);
      expect(i.phrase, contains('about average'));
    });

    test('never compares across mismatched units', () {
      final i = priceInsight(
        priceUsd: 30,
        sizeValue: 30,
        sizeUnit: 'ml',
        categoryLabel: 'serum',
        stat: stat(1.0, unit: 'g'),
      );
      expect(i.verdict, ValueVerdict.unknown);
      expect(i.phrase, isNull);
    });
  });

  group('formatting', () {
    test('per-unit price shows extra precision for cheap products', () {
      expect(formatPricePerUnit(0.05, 'ml'), '\$0.050/ml');
      expect(formatPricePerUnit(1.2, 'g'), '\$1.20/g');
    });
    test('formatPrice keeps whole dollars clean', () {
      expect(formatPrice(24), '\$24');
      expect(formatPrice(8.5), '\$8.50');
    });
    test('provenance names the source and the snapshot month', () {
      final p = priceProvenance('retailer', DateTime(2026, 8, 1));
      expect(p, 'typical retail · Aug 2026');
      expect(priceProvenance(null, null), 'approx. retail');
    });
  });
}
