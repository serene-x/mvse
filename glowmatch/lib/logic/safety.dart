// Ingredient flags, personal tolerance and period-after-opening reminders.

import '../data/models/models.dart';

enum SafetyKind { pregnancy, fragrance, comedogenic, whiteCast, allergen }

enum SafetyTone { neutral, gentle } // both soft; gentle = "worth knowing"

class SafetyFlag {
  final SafetyKind kind;
  final String label;
  final String detail;
  final SafetyTone tone;
  const SafetyFlag({
    required this.kind,
    required this.label,
    required this.detail,
    this.tone = SafetyTone.gentle,
  });
}

/// Personal tolerance can override general comedogenicity flags.
List<SafetyFlag> productSafetyFlags({
  required List<KeyIngredient> keyIngredients,
  required String categoryKey,
  Set<String> userTolerated = const {},
  Set<String> userTriggers = const {},
}) {
  final flags = <SafetyFlag>[];
  final ingredients =
      keyIngredients.map((k) => k.ingredient).whereType<Ingredient>().toList();

  final preg = ingredients.where((i) => i.pregnancyCaution).toList();
  if (preg.isNotEmpty) {
    flags.add(SafetyFlag(
      kind: SafetyKind.pregnancy,
      label: 'Often avoided during pregnancy',
      detail:
          'Contains ${_names(preg)} — commonly avoided during pregnancy or breastfeeding. This isn\'t medical advice; check with your doctor.',
    ));
  }

  final fragrance = ingredients
      .where((i) => i.isFragrance || i.isEssentialOil || i.commonAllergen)
      .toList();
  if (fragrance.isNotEmpty) {
    // If the user personally tolerates all of these, soften further.
    final allTolerated = fragrance.every((i) => userTolerated.contains(i.id));
    flags.add(SafetyFlag(
      kind: SafetyKind.fragrance,
      label: allTolerated
          ? 'Has fragrance (fine for you so far)'
          : 'Contains fragrance / essential oils',
      detail: allTolerated
          ? 'Contains ${_names(fragrance)}, which can bother sensitive skin — but your own logs suggest you tolerate it. Your data wins.'
          : 'Contains ${_names(fragrance)}. Fragrance is the most common cosmetic trigger for sensitive skin — most people are fine, but patch-test if you\'re reactive.',
    ));
  }

  for (final i in ingredients) {
    if ((i.comedogenicRating ?? 0) < 3) continue;
    if (userTolerated.contains(i.id)) {
      // The user's own data overrides the generic warning: say so.
      flags.add(SafetyFlag(
        kind: SafetyKind.comedogenic,
        tone: SafetyTone.neutral,
        label: '${i.displayName}: you tolerate it',
        detail:
            '${i.displayName} gets a generic "comedogenic" reputation, but you\'ve used it without trouble — so for you, that generic warning doesn\'t apply.',
      ));
    } else {
      flags.add(SafetyFlag(
        kind: SafetyKind.comedogenic,
        label: '${i.displayName}: sometimes called pore-clogging',
        detail:
            '${i.displayName} scores high on old comedogenicity scales — but that data is contested and doesn\'t predict individual skin well. It\'s a general note, not a verdict, and your own experience overrides it.',
      ));
    }
  }

  if (categoryKey == 'sunscreen') {
    final mineral = ingredients.where((i) =>
        i.activeFamily == 'uv_filter' ||
        i.inciName.toLowerCase().contains('zinc oxide') ||
        i.inciName.toLowerCase().contains('titanium dioxide'));
    if (mineral.isNotEmpty) {
      flags.add(const SafetyFlag(
        kind: SafetyKind.whiteCast,
        label: 'May leave a white cast',
        detail:
            'Mineral sunscreens like this can leave a white/grey cast, especially on medium-deep and deep skin tones. Worth checking reviews from people with your tone before buying.',
      ));
    }
  }

  return flags;
}

String _names(List<Ingredient> xs) {
  final names = xs.map((i) => i.displayName).toList();
  if (names.length == 1) return names.first;
  if (names.length == 2) return '${names[0]} and ${names[1]}';
  return '${names.sublist(0, names.length - 1).join(', ')}, and ${names.last}';
}

// Period-after-opening (PAO) helper

/// Result of a PAO check, framed as a gentle heads-up.
class PaoStatus {
  final bool tracked;
  final int? monthsLeft; // negative = past PAO
  final String message;
  const PaoStatus(
      {required this.tracked, this.monthsLeft, required this.message});
}

/// Compute PAO status from an opened date and the product's period-after-
/// opening in months. [now] is injected so this stays pure/testable.
PaoStatus paoStatus({
  DateTime? openedAt,
  int? paoMonths,
  required DateTime now,
}) {
  if (openedAt == null || paoMonths == null) {
    return const PaoStatus(
      tracked: false,
      message: 'Add when you opened it to track freshness.',
    );
  }
  final expiry =
      DateTime(openedAt.year, openedAt.month + paoMonths, openedAt.day);
  final daysLeft = expiry.difference(now).inDays;
  final monthsLeft = (daysLeft / 30).floor();
  if (daysLeft < 0) {
    return PaoStatus(
      tracked: true,
      monthsLeft: monthsLeft,
      message:
          'Past its period-after-opening (${paoMonths}M). Not necessarily unsafe, but it may be less effective — especially actives like vitamin C. Give it a sniff and a look.',
    );
  }
  if (daysLeft < 45) {
    return PaoStatus(
      tracked: true,
      monthsLeft: monthsLeft,
      message:
          'About ${daysLeft <= 30 ? 'a month' : '6 weeks'} left before its $paoMonths-month PAO.',
    );
  }
  return PaoStatus(
    tracked: true,
    monthsLeft: monthsLeft,
    message:
        'Fresh — about $monthsLeft months left before its $paoMonths-month PAO.',
  );
}
