// Profile options and initial estimates from owned products.

enum SkinType { dry, oily, combination, normal, sensitive }

const skinTypeKeys = <SkinType, String>{
  SkinType.dry: 'dry',
  SkinType.oily: 'oily',
  SkinType.combination: 'combination',
  SkinType.normal: 'normal',
  SkinType.sensitive: 'sensitive',
};

String skinTypeLabel(SkinType t) {
  switch (t) {
    case SkinType.dry:
      return 'Dry';
    case SkinType.oily:
      return 'Oily';
    case SkinType.combination:
      return 'Combination';
    case SkinType.normal:
      return 'Normal / balanced';
    case SkinType.sensitive:
      return 'Sensitive';
  }
}

SkinType? skinTypeFromKey(String k) {
  for (final e in skinTypeKeys.entries) {
    if (e.value == k) return e.key;
  }
  return null;
}

/// Concerns the user wants help with.
enum SkinConcern {
  acne,
  blackheads,
  redness,
  dryness,
  oiliness,
  texture,
  pigmentation,
  aging,
  dullness,
  largePores,
  darkCircles,
  sensitivity,
}

const concernKeys = <SkinConcern, String>{
  SkinConcern.acne: 'acne',
  SkinConcern.blackheads: 'blackheads',
  SkinConcern.redness: 'redness',
  SkinConcern.dryness: 'dryness',
  SkinConcern.oiliness: 'oiliness',
  SkinConcern.texture: 'texture',
  SkinConcern.pigmentation: 'pigmentation',
  SkinConcern.aging: 'aging',
  SkinConcern.dullness: 'dullness',
  SkinConcern.largePores: 'large_pores',
  SkinConcern.darkCircles: 'dark_circles',
  SkinConcern.sensitivity: 'sensitivity',
};

String concernLabel(SkinConcern c) {
  switch (c) {
    case SkinConcern.acne:
      return 'Breakouts / acne';
    case SkinConcern.blackheads:
      return 'Blackheads / congestion';
    case SkinConcern.redness:
      return 'Redness';
    case SkinConcern.dryness:
      return 'Dryness';
    case SkinConcern.oiliness:
      return 'Oiliness / shine';
    case SkinConcern.texture:
      return 'Texture';
    case SkinConcern.pigmentation:
      return 'Dark spots';
    case SkinConcern.aging:
      return 'Fine lines / aging';
    case SkinConcern.dullness:
      return 'Dullness';
    case SkinConcern.largePores:
      return 'Large-looking pores';
    case SkinConcern.darkCircles:
      return 'Dark circles';
    case SkinConcern.sensitivity:
      return 'Sensitivity / reactivity';
  }
}

SkinConcern? concernFromKey(String k) {
  for (final e in concernKeys.entries) {
    if (e.value == k) return e.key;
  }
  return null;
}

enum SkinGoal {
  clearBreakouts,
  evenTone,
  hydrate,
  calmRedness,
  smoothTexture,
  antiAge,
  simplify,
  protect
}

const goalKeys = <SkinGoal, String>{
  SkinGoal.clearBreakouts: 'clear_breakouts',
  SkinGoal.evenTone: 'even_tone',
  SkinGoal.hydrate: 'hydrate',
  SkinGoal.calmRedness: 'calm_redness',
  SkinGoal.smoothTexture: 'smooth_texture',
  SkinGoal.antiAge: 'anti_age',
  SkinGoal.simplify: 'simplify',
  SkinGoal.protect: 'protect',
};

String goalLabel(SkinGoal g) {
  switch (g) {
    case SkinGoal.clearBreakouts:
      return 'Fewer breakouts';
    case SkinGoal.evenTone:
      return 'More even tone';
    case SkinGoal.hydrate:
      return 'More hydration';
    case SkinGoal.calmRedness:
      return 'Calmer, less red';
    case SkinGoal.smoothTexture:
      return 'Smoother texture';
    case SkinGoal.antiAge:
      return 'Fine lines & firmness';
    case SkinGoal.simplify:
      return 'A simpler routine';
    case SkinGoal.protect:
      return 'Protect & maintain';
  }
}

SkinGoal? goalFromKey(String k) {
  for (final e in goalKeys.entries) {
    if (e.value == k) return e.key;
  }
  return null;
}

// Inference: the "I don't know: here's what I use" path.

class InferredFact {
  final String field; // 'skin_type' | 'concern' | 'sensitivity'
  final String value; // the vocabulary key
  final String reason; // plain-language "why"
  final double confidence; // 0..1
  const InferredFact({
    required this.field,
    required this.value,
    required this.reason,
    required this.confidence,
  });

  Map<String, dynamic> toJson() => {
        'field': field,
        'value': value,
        'reason': reason,
        'confidence': confidence,
      };

  factory InferredFact.fromJson(Map<String, dynamic> m) => InferredFact(
        field: m['field'] as String,
        value: m['value'] as String,
        reason: m['reason'] as String,
        confidence: (m['confidence'] as num?)?.toDouble() ?? 0,
      );
}

/// Minimal shape the inference needs about a product the user logged.
class ProfileSignal {
  final String productName;
  final String? category; // product category key
  final String? liked; // 'yes' | 'no' | 'meh'
  final String?
      reaction; // 'none' | 'breakout' | 'irritation' | 'dryness' | 'other'
  const ProfileSignal({
    required this.productName,
    this.category,
    this.liked,
    this.reaction,
  });
}

class InferredProfile {
  final Set<SkinType> skinTypes;
  final Set<SkinConcern> concerns;
  final List<InferredFact> facts;
  const InferredProfile({
    required this.skinTypes,
    required this.concerns,
    required this.facts,
  });

  bool get isEmpty => facts.isEmpty;
}

// Category groupings used by the inference rules.
const _exfoliantsAndAcneCats = {'exfoliant', 'treatment', 'toner', 'serum'};
const _hydrationCats = {'moisturizer', 'serum', 'face_oil', 'mist'};

/// Suggests a starting profile when multiple product signals agree.
InferredProfile inferProfile(List<ProfileSignal> signals) {
  final facts = <InferredFact>[];
  final types = <SkinType>{};
  final concerns = <SkinConcern>{};

  if (signals.isEmpty) {
    return const InferredProfile(skinTypes: {}, concerns: {}, facts: []);
  }

  final reacted =
      signals.where((s) => s.reaction != null && s.reaction != 'none').toList();
  final breakouts = signals.where((s) => s.reaction == 'breakout').toList();
  final irritations = signals
      .where((s) => s.reaction == 'irritation' || s.reaction == 'dryness')
      .toList();

  if (reacted.length >= 2) {
    types.add(SkinType.sensitive);
    concerns.add(SkinConcern.sensitivity);
    facts.add(InferredFact(
      field: 'skin_type',
      value: skinTypeKeys[SkinType.sensitive]!,
      reason:
          'You told us ${reacted.length} products reacted with your skin — that points toward sensitive/reactive skin. We\'ll narrow down the specific triggers as you log more.',
      confidence: reacted.length >= 3 ? 0.6 : 0.4,
    ));
  }
  if (breakouts.isNotEmpty) {
    concerns.add(SkinConcern.acne);
    facts.add(InferredFact(
      field: 'concern',
      value: concernKeys[SkinConcern.acne]!,
      reason:
          'You logged a breakout from ${breakouts.length == 1 ? 'a product' : '${breakouts.length} products'}, so we\'ve added breakouts as a concern to watch.',
      confidence: 0.5,
    ));
  }
  if (irritations.isNotEmpty) {
    concerns.add(SkinConcern.dryness);
    facts.add(InferredFact(
      field: 'concern',
      value: concernKeys[SkinConcern.dryness]!,
      reason:
          'A product left your skin irritated or dry, so we\'ve flagged dryness/barrier as something to keep an eye on.',
      confidence: 0.35,
    ));
  }

  final acneProducts = signals
      .where((s) =>
          s.category != null && _exfoliantsAndAcneCats.contains(s.category))
      .toList();
  if (acneProducts.length >= 2) {
    concerns.add(SkinConcern.texture);
    facts.add(InferredFact(
      field: 'concern',
      value: concernKeys[SkinConcern.texture]!,
      reason:
          'You already use exfoliating/active products — often a sign texture or congestion is on your mind.',
      confidence: 0.3,
    ));
  }

  final hydrators = signals
      .where((s) => s.category != null && _hydrationCats.contains(s.category))
      .toList();
  final likedHydrators = hydrators.where((s) => s.liked == 'yes').length;
  final dislikedRich = hydrators.where((s) => s.liked == 'no').length;
  if (likedHydrators >= 2 && dislikedRich == 0) {
    // leans dry if they love hydrating products
    types.add(SkinType.dry);
    facts.add(InferredFact(
      field: 'skin_type',
      value: skinTypeKeys[SkinType.dry]!,
      reason:
          'You like several hydrating products, which often (not always) means skin that leans dry. Easy to correct if that\'s not you.',
      confidence: 0.3,
    ));
  }

  // Leave the profile unknown when signals do not agree.
  return InferredProfile(skinTypes: types, concerns: concerns, facts: facts);
}
