class WearNote {
  final String productKey, shade, fit, reaction, family, sourceUrl;
  final int frequency;
  const WearNote(
      {required this.productKey,
      this.shade = '',
      this.fit = '',
      this.reaction = '',
      this.family = '',
      this.frequency = 1,
      this.sourceUrl = ''});
  factory WearNote.fromJson(Map<String, dynamic> j) => WearNote(
      productKey: j['product'] as String,
      shade: j['shade'] as String? ?? '',
      fit: j['fit'] as String? ?? '',
      reaction: j['reaction'] as String? ?? '',
      family: j['family'] as String? ?? '',
      frequency: (j['frequency'] as num?)?.toInt() ?? 1,
      sourceUrl: j['source'] as String? ?? '');
  Map<String, dynamic> toJson() => {
        'product': productKey,
        'shade': shade,
        'fit': fit,
        'reaction': reaction,
        'family': family,
        'frequency': frequency,
        'source': sourceUrl
      };
}

const seasons = [
  'Light Spring',
  'True Spring',
  'Bright Spring',
  'Light Summer',
  'True Summer',
  'Soft Summer',
  'Soft Autumn',
  'True Autumn',
  'Deep Autumn',
  'Deep Winter',
  'True Winter',
  'Bright Winter'
];
const paletteFamilies = <String, List<String>>{
  'Peach / coral': ['Light Spring', 'True Spring'],
  'Warm, clear red': ['True Spring', 'Bright Spring'],
  'Soft rose / mauve': ['Soft Summer', 'True Summer'],
  'Light, cool pink': ['Light Summer', 'True Summer'],
  'Terracotta / warm brown': ['True Autumn', 'Deep Autumn'],
  'Muted beige / warm nude': ['Soft Autumn', 'True Autumn'],
  'Cool berry / plum': ['Deep Winter', 'True Winter'],
  'Bright pink / blue red': ['Bright Winter', 'True Winter'],
};
String familyFromDescription(String text) {
  final s = text.toLowerCase();
  if (s.contains('terracotta') || s.contains('warm chestnut')) {
    return 'Terracotta / warm brown';
  }
  if (s.contains('peach') || s.contains('coral')) return 'Peach / coral';
  if (s.contains('mauve') || s.contains('dusty rose')) {
    return 'Soft rose / mauve';
  }
  if (s.contains('cool pink')) return 'Light, cool pink';
  if (s.contains('berry') || s.contains('plum')) return 'Cool berry / plum';
  if (s.contains('hot pink') ||
      s.contains('bright pink') ||
      s.contains('blue red')) {
    return 'Bright pink / blue red';
  }
  if (s.contains('warm nude') || s.contains('beige nude')) {
    return 'Muted beige / warm nude';
  }
  return '';
}

List<String> seasonSuggestions(List<WearNote> notes) {
  // At most one vote per product. Repeated logs cannot manufacture confidence.
  final products = <String, WearNote>{};
  for (final n in notes) {
    if (n.fit == 'Flattering colour' &&
        n.shade.isNotEmpty &&
        paletteFamilies.containsKey(n.family)) {
      products[n.productKey] = n;
    }
  }
  if (products.length < 3) return [];
  final scores = <String, int>{};
  for (final n in products.values) {
    for (final s in paletteFamilies[n.family]!) {
      scores[s] = (scores[s] ?? 0) + n.frequency.clamp(1, 3);
    }
  }
  final ranked = scores.keys.toList()
    ..sort((a, b) => scores[b]!.compareTo(scores[a]!));
  // Mixed preferences should not force a season assignment.
  final total =
      products.values.fold<int>(0, (sum, n) => sum + n.frequency.clamp(1, 3));
  if (scores[ranked.first]! < total * .6) return [];
  return ranked.where((s) => scores[s]! >= total * .6).take(2).toList();
}

const ingredientRoles = <String, String>{
  'retinol':
      'A vitamin A ingredient used for uneven texture and signs of ageing. It can irritate skin.',
  'ascorbic acid':
      'Vitamin C. An antioxidant used in products for uneven tone.',
  'sodium ascorbyl phosphate':
      'A vitamin C derivative. Its effects depend on the formula.',
  'glycolic acid': 'An exfoliating acid that loosens dead surface skin cells.',
  'lactic acid': 'An exfoliating acid that also helps hold moisture.',
  'salicylic acid':
      'An exfoliating ingredient used in products for clogged pores.',
  'azelaic acid':
      'Used in products for blemishes and uneven tone. It can sting or irritate.',
  'ceramide np': 'A skin-like lipid used to support the moisture barrier.',
  'palmitoyl pentapeptide-4':
      'A peptide used in products aimed at fine lines. Results depend on the formulation.',
  'soluble collagen':
      'Helps condition the skin surface. It does not replace collagen within the skin.',
  'ferulic acid': 'An antioxidant often combined with vitamins C and E.',
  'linalool':
      'A fragrance component that can cause contact allergy in some people.',
  'limonene':
      'A fragrance component that can cause contact allergy in some people.',
  'cocos nucifera (coconut) oil':
      'An emollient that softens skin. Some acne-prone users find it does not suit them.',
  'benzoyl peroxide':
      'An acne-treatment ingredient. It may dry or irritate skin and can bleach fabric.',
  'bakuchiol':
      'Used in products aimed at fine lines and uneven tone. It is not a retinoid.',
  'centella asiatica extract': 'A plant extract used to condition skin.',
  'zinc pca':
      'Used in products for oily skin. Its effect depends on the formula.',
  'glycerin': 'Helps hold water in the skin.',
  'squalane': 'An emollient that softens skin and adds slip.',
  'sodium hyaluronate': 'A form of hyaluronic acid that holds water.',
  'panthenol': 'Helps skin retain moisture.',
  'niacinamide': 'Vitamin B3. Used to support the skin barrier.',
  'dimethicone': 'Adds slip and helps reduce moisture loss.',
  'silica': 'Helps absorb excess oil and changes the texture.',
  'mica': 'Adds light reflection and slip.',
  'caffeine':
      'Often included in under-eye formulas. Results depend on the formula.',
  'tocopherol': 'Vitamin E. Helps protect oils in the formula from oxidation.',
  'zinc oxide': 'A UV filter when used in a labeled sunscreen.',
  'titanium dioxide':
      'A pigment; also used as a UV filter in labeled sunscreens.',
  'fragrance': 'Added scent. Can irritate some people.',
  'parfum': 'Added scent. Can irritate some people.',
};

/// Historical ingredient-level signals. These never increase the personal
/// history score: raw-material results do not predict a finished formula.
