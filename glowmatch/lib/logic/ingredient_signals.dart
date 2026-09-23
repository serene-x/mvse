import 'beauty_book.dart';
import 'ingredient_identity.dart';

// Watch list: historical ingredient tests, including borderline/variable results.
// Fulton 1989 Table I. Not a finished-formula rating or a complete list of causes.
const poreWatchList = <String>{
  'acetylated lanolin alcohol',
  'peg-16 lanolin',
  'laneth-10',
  'capric acid',
  'lauric acid',
  'myristic acid',
  'palmitic acid',
  'stearic acid',
  'ascorbyl palmitate',
  'butyl stearate',
  'cetyl acetate',
  'decyl oleate',
  'dioctyl malate',
  'dioctyl succinate',
  'ethylhexyl palmitate',
  'ethylhexyl pelargonate',
  'isodecyl oleate',
  'isopropyl isostearate',
  'isopropyl linolate',
  'isopropyl myristate',
  'isopropyl palmitate',
  'isostearyl neopentanoate',
  'isostearyl isostearate',
  'myristyl lactate',
  'myristyl myristate',
  'stearyl heptanoate',
  'myristyl alcohol',
  'cetyl alcohol',
  'isocetyl alcohol',
  'cetearyl alcohol',
  'oleyl alcohol',
  'stearyl alcohol',
  'ceteareth-20',
  'sorbitan oleate',
  'glyceryl stearate se',
  'polyglyceryl-3 diisostearate',
  'peg-8 stearate',
  'peg-100 distearate',
  'peg-150 distearate',
  'peg-200 dilaurate',
  'laureth-4',
  'laureth-23',
  'steareth-2',
  'steareth-10',
  'steareth-20',
  'oleth-3',
  'oleth-5',
  'oleth-10',
  'oleth-3 phosphate',
  'ppg-5-ceteth-10 phosphate',
  'ppg-2 myristyl propionate',
  'ppg-10 cetyl ether',
  'sulfated jojoba oil',
  'theobroma cacao (cocoa) seed butter',
  'cocos nucifera (coconut) oil',
  'hydrogenated vegetable oil',
  'tocopherol',
  'retinyl palmitate',
  'phytantriol',
};

enum IngredientSignalLevel { watch, overlap, repeated, tolerated, mixed }

class IngredientSignal {
  final String ingredient;
  final IngredientSignalLevel level;
  final bool historical;
  final List<String> breakoutProducts, toleratedProducts;
  const IngredientSignal(this.ingredient, this.level, this.historical,
      this.breakoutProducts, this.toleratedProducts);
  String get label => switch (level) {
        IngredientSignalLevel.watch => 'Watch list',
        IngredientSignalLevel.overlap => 'One breakout overlap',
        IngredientSignalLevel.repeated => 'Repeated breakout overlap',
        IngredientSignalLevel.tolerated => 'Previously tolerated',
        IngredientSignalLevel.mixed => 'Mixed history',
      };
  String get detail => switch (level) {
        IngredientSignalLevel.watch =>
          'Flagged in older ingredient tests. No personal evidence yet.',
        IngredientSignalLevel.overlap =>
          'In one product you marked Breakout. That does not identify the cause.',
        IngredientSignalLevel.repeated =>
          'In ${breakoutProducts.length} products marked Breakout and none marked Tolerated. A possible pattern, not a confirmed cause.',
        IngredientSignalLevel.tolerated =>
          'In ${toleratedProducts.length} product${toleratedProducts.length == 1 ? '' : 's'} you marked Tolerated. Other formulas can still behave differently.',
        IngredientSignalLevel.mixed =>
          'In ${breakoutProducts.length} breakout and ${toleratedProducts.length} tolerated products. The evidence is mixed.',
      };
}

List<IngredientSignal> ingredientSignals(
    String formula, List<WearNote> notes, Map<String, String> formulas,
    {String? excludeProduct}) {
  final target = formulaIngredients(formula);
  final bad = <String, Set<String>>{}, good = <String, Set<String>>{};
  // Each product counts once per outcome, even if several shades were logged.
  for (final note in notes) {
    if (note.productKey == excludeProduct) continue;
    final map = note.reaction == 'Breakout'
        ? bad
        : note.reaction == 'Tolerated'
            ? good
            : null;
    if (map == null) continue;
    for (final ingredient in formulaIngredients(formulas[note.productKey] ?? '')
        .intersection(target)) {
      if (ingredient == 'water') continue;
      (map[ingredient] ??= {}).add(note.productKey);
    }
  }
  return [
    for (final ingredient in target)
      if (poreWatchList.contains(ingredient) ||
          bad.containsKey(ingredient) ||
          good.containsKey(ingredient))
        IngredientSignal(
            ingredient,
            (bad[ingredient]?.isNotEmpty ?? false)
                ? ((good[ingredient]?.isNotEmpty ?? false)
                    ? IngredientSignalLevel.mixed
                    : bad[ingredient]!.length >= 2
                        ? IngredientSignalLevel.repeated
                        : IngredientSignalLevel.overlap)
                : (good[ingredient]?.isNotEmpty ?? false)
                    ? IngredientSignalLevel.tolerated
                    : IngredientSignalLevel.watch,
            poreWatchList.contains(ingredient),
            bad[ingredient]?.toList() ?? [],
            good[ingredient]?.toList() ?? [])
  ];
}
