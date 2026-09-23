// Orders products into morning and evening routines and checks active combinations.

class RoutineProduct {
  final String id;
  final String name;
  final String category; // product category key
  final Set<String>
      activeFamilies; // e.g. {'retinoid','bha'} from key ingredients
  final bool hasPotentActive; // any cell-turnover active present
  const RoutineProduct({
    required this.id,
    required this.name,
    required this.category,
    this.activeFamilies = const {},
    this.hasPotentActive = false,
  });
}

enum RoutineTime { am, pm, either }

class RoutineSlot {
  final RoutineProduct product;
  final int order; // step order within the routine
  final RoutineTime time; // where we placed it
  final String stepLabel; // "Cleanse", "Treat", "Moisturize", "SPF"...
  const RoutineSlot({
    required this.product,
    required this.order,
    required this.time,
    required this.stepLabel,
  });
}

enum GuidanceKind { conflict, synergy, coaching }

class RoutineGuidance {
  final GuidanceKind kind;
  final String title;
  final String detail; // plain-language reasoning
  const RoutineGuidance(
      {required this.kind, required this.title, required this.detail});
}

class RoutinePlan {
  final List<RoutineSlot> am;
  final List<RoutineSlot> pm;
  final List<RoutineGuidance> guidance;
  const RoutinePlan(
      {required this.am, required this.pm, required this.guidance});
}

const _stepOrder = <String, int>{
  'cleanser': 0,
  'toner': 1,
  'exfoliant': 2,
  'treatment': 3,
  'serum': 4,
  'face_oil': 6,
  'eye_cream': 5,
  'mist': 1,
  'moisturizer': 7,
  'sunscreen': 8,
};

String _stepLabel(String category) {
  switch (category) {
    case 'cleanser':
      return 'Cleanse';
    case 'toner':
      return 'Tone';
    case 'mist':
      return 'Prep';
    case 'exfoliant':
      return 'Exfoliate';
    case 'treatment':
      return 'Treat';
    case 'serum':
      return 'Serum';
    case 'eye_cream':
      return 'Eye care';
    case 'moisturizer':
      return 'Moisturize';
    case 'face_oil':
      return 'Face oil';
    case 'sunscreen':
      return 'SPF';
    default:
      return 'Apply';
  }
}

int _order(String category) => _stepOrder[category] ?? 4;

// Which time of day a product prefers.
RoutineTime _preferredTime(RoutineProduct p) {
  if (p.category == 'sunscreen') return RoutineTime.am;
  if (p.activeFamilies.contains('retinoid')) return RoutineTime.pm;
  if (p.activeFamilies.contains('vitamin_c')) return RoutineTime.am;
  if (p.activeFamilies.contains('aha') || p.activeFamilies.contains('bha')) {
    return RoutineTime.pm; // exfoliants at night to avoid daytime sensitivity
  }
  return RoutineTime.either;
}

/// Build an AM/PM routine from a set of products and surface guidance.
RoutinePlan buildRoutine(List<RoutineProduct> products) {
  final am = <RoutineSlot>[];
  final pm = <RoutineSlot>[];

  for (final p in products) {
    final t = _preferredTime(p);
    final slot = RoutineSlot(
        product: p,
        order: _order(p.category),
        time: t,
        stepLabel: _stepLabel(p.category));
    switch (t) {
      case RoutineTime.am:
        am.add(slot);
        break;
      case RoutineTime.pm:
        pm.add(slot);
        break;
      case RoutineTime.either:
        // Cleanser/moisturizer/etc. belong in both; add to both routines.
        am.add(slot);
        pm.add(slot);
        break;
    }
  }

  am.sort((a, b) => a.order.compareTo(b.order));
  pm.sort((a, b) => a.order.compareTo(b.order));

  return RoutinePlan(
    am: am,
    pm: pm,
    guidance: _guidance(products),
  );
}

List<RoutineGuidance> _guidance(List<RoutineProduct> products) {
  final out = <RoutineGuidance>[];

  // gather which products carry each active family
  final byFamily = <String, List<RoutineProduct>>{};
  for (final p in products) {
    for (final f in p.activeFamilies) {
      (byFamily[f] ??= []).add(p);
    }
  }
  bool has(String f) => byFamily.containsKey(f);
  List<RoutineProduct> of(String f) => byFamily[f] ?? const [];

  if (has('vitamin_c') && has('retinoid')) {
    out.add(const RoutineGuidance(
      kind: GuidanceKind.conflict,
      title: 'Keep vitamin C and retinol in separate routines',
      detail:
          'They prefer very different pH levels and can each blunt the other while adding up to more irritation. The easy fix: vitamin C in the morning, retinol at night.',
    ));
  }

  if (has('benzoyl_peroxide') && has('retinoid')) {
    out.add(const RoutineGuidance(
      kind: GuidanceKind.conflict,
      title: 'Benzoyl peroxide can deactivate retinol',
      detail:
          'Used at the same time they cancel each other out. Put benzoyl peroxide in the morning and retinol at night, or alternate days.',
    ));
  }
  if (has('benzoyl_peroxide') && has('vitamin_c')) {
    out.add(const RoutineGuidance(
      kind: GuidanceKind.conflict,
      title: 'Benzoyl peroxide oxidizes vitamin C',
      detail:
          'Layered together, benzoyl peroxide degrades vitamin C before it can work. Keep them in separate routines.',
    ));
  }

  // multiple exfoliants → over-exfoliation
  final exfoliants = <RoutineProduct>{...of('aha'), ...of('bha')};
  // count exfoliating products (also treat dedicated 'exfoliant' category)
  final exfoliantProducts = {
    ...exfoliants,
    ...products.where((p) => p.category == 'exfoliant'),
  };
  if (exfoliantProducts.length >= 2) {
    out.add(RoutineGuidance(
      kind: GuidanceKind.conflict,
      title: 'Go easy — that\'s more than one exfoliant',
      detail:
          'You have ${exfoliantProducts.length} exfoliating products (${exfoliantProducts.map((p) => p.name).join(', ')}). Using them together is a fast track to over-exfoliation. Alternate days, and let your skin tell you if it\'s too much.',
    ));
  }

  // two strong actives (retinoid + an exfoliant) same night
  if (has('retinoid') && exfoliantProducts.isNotEmpty) {
    out.add(const RoutineGuidance(
      kind: GuidanceKind.conflict,
      title: 'Don\'t stack a retinoid and an exfoliant the same night',
      detail:
          'Both push cell turnover, so together they can overwhelm your barrier. Alternate nights instead — retinoid one night, exfoliant another.',
    ));
  }

  if (has('azelaic') && has('retinoid')) {
    out.add(const RoutineGuidance(
      kind: GuidanceKind.synergy,
      title: 'Azelaic acid and your retinoid tend to work well together',
      detail:
          'Azelaic can calm the redness and irritation a retinoid causes, while both work on texture and post-blemish marks. A commonly recommended pairing.',
    ));
  }
  if (has('retinoid') && (has('humectant') || has('vitamin_b3'))) {
    out.add(const RoutineGuidance(
      kind: GuidanceKind.synergy,
      title: 'Nice — you\'ve got buffers for your retinoid',
      detail:
          'Hyaluronic acid and niacinamide help cushion retinoid irritation, so they pair well. Layer the hydrator under or after the retinoid.',
    ));
  }
  if (has('vitamin_c') && has('antioxidant')) {
    out.add(const RoutineGuidance(
      kind: GuidanceKind.synergy,
      title: 'Your vitamin C has antioxidant backup',
      detail:
          'Vitamin E and ferulic acid stabilize vitamin C and boost its antioxidant effect — the classic reinforcing trio.',
    ));
  }

  final potent = products.where((p) => p.hasPotentActive).toList();
  if (potent.isNotEmpty) {
    out.add(RoutineGuidance(
      kind: GuidanceKind.coaching,
      title: 'Ease potent actives in slowly',
      detail:
          'You\'ve got ${potent.length == 1 ? 'a strong active' : 'strong actives'} (${potent.map((p) => p.name).join(', ')}). Start 1–2 nights a week and build up, introduce only one new active at a time, and patch-test first. Going slow is gentler on your skin — and it gives us cleaner signal about what actually works for you.',
    ));
  }

  return out;
}
