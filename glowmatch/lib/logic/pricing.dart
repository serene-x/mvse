// Compares dated retail prices within the same category and unit.

const int _minPeers = 3;

enum ValueVerdict { cheaper, typical, pricier, unknown }

class CategoryPriceStat {
  final String category;
  final String unit; // 'ml' | 'g'
  final int n;
  final double avgPerUnit;
  const CategoryPriceStat({
    required this.category,
    required this.unit,
    required this.n,
    required this.avgPerUnit,
  });
}

class PriceInsight {
  final double? pricePerUnit; // price / size, in $/ml or $/g
  final String? unit;
  final ValueVerdict verdict;
  final double? categoryAvgPerUnit;
  final String? phrase; // "about average for a serum", or null when unknown
  const PriceInsight({
    required this.pricePerUnit,
    required this.unit,
    required this.verdict,
    required this.categoryAvgPerUnit,
    required this.phrase,
  });

  static const empty = PriceInsight(
    pricePerUnit: null,
    unit: null,
    verdict: ValueVerdict.unknown,
    categoryAvgPerUnit: null,
    phrase: null,
  );
}

double? pricePerUnit(double? priceUsd, double? sizeValue) {
  if (priceUsd == null || sizeValue == null || sizeValue <= 0) return null;
  return priceUsd / sizeValue;
}

/// Build the value insight for a product. [categoryLabel] is a lowercase
/// singular noun ("serum", "foundation") used only for phrasing. [stat] is the
/// matching (category, unit) row from category_price_stats, or null.
PriceInsight priceInsight({
  required double? priceUsd,
  required double? sizeValue,
  required String? sizeUnit,
  required String categoryLabel,
  required CategoryPriceStat? stat,
}) {
  final ppu = pricePerUnit(priceUsd, sizeValue);
  if (ppu == null || sizeUnit == null) return PriceInsight.empty;

  // No trustworthy comparison set → show the per-unit price with no verdict.
  if (stat == null ||
      stat.unit != sizeUnit ||
      stat.n < _minPeers ||
      stat.avgPerUnit <= 0) {
    return PriceInsight(
      pricePerUnit: ppu,
      unit: sizeUnit,
      verdict: ValueVerdict.unknown,
      categoryAvgPerUnit: stat?.avgPerUnit,
      phrase: null,
    );
  }

  final ratio = ppu / stat.avgPerUnit;
  final ValueVerdict verdict;
  final String phrase;
  if (ratio < 0.8) {
    verdict = ValueVerdict.cheaper;
    phrase = 'a better deal per $sizeUnit than a typical $categoryLabel';
  } else if (ratio > 1.25) {
    verdict = ValueVerdict.pricier;
    phrase = 'pricier per $sizeUnit than a typical $categoryLabel';
  } else {
    verdict = ValueVerdict.typical;
    phrase = 'about average per $sizeUnit for a $categoryLabel';
  }
  return PriceInsight(
    pricePerUnit: ppu,
    unit: sizeUnit,
    verdict: verdict,
    categoryAvgPerUnit: stat.avgPerUnit,
    phrase: phrase,
  );
}

/// "$0.85/ml", "$1.20/g". Small values get an extra digit so cheap products
/// don't all round to "$0.0/ml".
String formatPricePerUnit(double perUnit, String unit) {
  // Cheap products get an extra digit so they don't all round to "$0.0/ml".
  final digits = perUnit < 0.1 ? 3 : 2;
  return '\$${perUnit.toStringAsFixed(digits)}/$unit';
}

// Imperial conversions: US shoppers price-check in ounces. Liquids convert to
// fluid ounces, powders/creams (grams) to (weight) ounces.
const double _mlPerFlOz = 29.5735;
const double _gPerOz = 28.3495;

/// The imperial counterpart label for a metric size unit ('ml' -> 'fl oz').
String imperialUnit(String unit) => unit == 'ml' ? 'fl oz' : 'oz';

/// Convert a $/ml or $/g figure to its $/fl-oz or $/oz equivalent.
double pricePerImperial(double perUnit, String unit) =>
    perUnit * (unit == 'ml' ? _mlPerFlOz : _gPerOz);

/// "$49/fl oz", "$34/oz". Ounce prices are ~29× the per-ml figure, so they
/// need fewer decimals to read cleanly.
String formatPricePerImperial(double perUnit, String unit) {
  final imp = pricePerImperial(perUnit, unit);
  final digits = imp < 10 ? 1 : 0;
  return '\$${imp.toStringAsFixed(digits)}/${imperialUnit(unit)}';
}

/// Both price-per figures together: "$1.67/ml · $49/fl oz".
String formatPricePerBoth(double perUnit, String unit) =>
    '${formatPricePerUnit(perUnit, unit)} · ${formatPricePerImperial(perUnit, unit)}';

/// "$24" or "$8.50": whole dollars stay clean, cents show when present.
String formatPrice(double priceUsd) {
  return priceUsd == priceUsd.roundToDouble()
      ? '\$${priceUsd.toStringAsFixed(0)}'
      : '\$${priceUsd.toStringAsFixed(2)}';
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Formats the source and date of a retail-price snapshot.
String priceProvenance(String? priceSource, DateTime? asOf) {
  final srcLabel = switch (priceSource) {
    'retailer' => 'typical retail',
    'brand' => 'brand price',
    'msrp' => 'list price',
    _ => 'approx. retail',
  };
  if (asOf == null) return srcLabel;
  return '$srcLabel · ${_months[asOf.month - 1]} ${asOf.year}';
}
