/// Exact INCI aliases, not substring matches: an ester is not its parent oil.
String ingredientIdentity(String raw) {
  var name = raw
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '')
      .replaceAll(RegExp(r'^(?:active|inactive)?\s*ingredients?\s*:\s*'), '')
      .replaceAll(RegExp(r'\s+\(?\d+(?:\.\d+)?\s*%.*$'), '')
      .replaceAll(RegExp(r'\s*\((?:retinoid|vitamin [^)]*)\)'), '')
      .replaceAll(RegExp(r'\s*/\s*'), '/')
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'\.+$'), '');
  const aliases = {
    'aqua': 'water',
    'aqua (water)': 'water',
    'aqua/water/eau': 'water',
    'water/aqua/eau': 'water',
    'water (aqua/eau)': 'water',
    'water (aqua)': 'water',
    'aqua/water': 'water',
    'water/aqua': 'water',
    'water aqua eau': 'water',
    'purified water': 'water',
    'fragrance/parfum': 'fragrance',
    'fragrance (parfum)': 'fragrance',
    'parfum (fragrance)': 'fragrance',
    'parfum/fragrance': 'fragrance',
    'parfum': 'fragrance',
    'octyl palmitate': 'ethylhexyl palmitate',
    'coconut oil': 'cocos nucifera (coconut) oil',
    'cocos nucifera oil': 'cocos nucifera (coconut) oil',
    'cocoa butter': 'theobroma cacao (cocoa) seed butter',
    'theobroma cacao seed butter': 'theobroma cacao (cocoa) seed butter',
    'ceramide 3': 'ceramide np',
    'ceramide 6 ii': 'ceramide ap',
    'ceramide 1': 'ceramide eop',
    'alpha arbutin': 'alpha-arbutin',
    'edetate disodium': 'disodium edta',
    'peg 8 stearate': 'peg-8 stearate',
    'ceteareth 20': 'ceteareth-20',
    'cetearylalcohol': 'cetearyl alcohol',
    'xanthamgum': 'xanthan gum',
    'jojoba oil': 'simmondsia chinensis (jojoba) seed oil',
    'simmondsia chinensis seed oil': 'simmondsia chinensis (jojoba) seed oil',
    'tocopherol (vitamin e)': 'tocopherol',
  };
  return aliases[name] ?? name;
}

Set<String> formulaIngredients(String text) {
  final main = text
      .split(RegExp(r'may contain|peut contenir|\+/-|±', caseSensitive: false))
      .first;
  return main
      .replaceAll(
          RegExp(r'(?:active|inactive) ingredients?\s*:', caseSensitive: false),
          ',')
      .split(RegExp(r',(?!\d)(?![^()]*\))|[;•\n]'))
      .map(ingredientIdentity)
      .where((s) => s.length > 1 && !s.contains(':'))
      .toSet();
}
