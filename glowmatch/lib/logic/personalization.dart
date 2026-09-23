// Reaction classification and ingredient overlap scoring.

enum BreakoutVerdict { likelyPurging, likelyReaction, uncertain }

class BreakoutAssessment {
  final BreakoutVerdict verdict;
  final double confidence; // 0..1
  final String headline; // short "this looks like…"
  final String reasoning; // plain-language why
  final String guidance; // what to do
  final bool seeProfessional; // Whether symptoms warrant professional advice
  const BreakoutAssessment({
    required this.verdict,
    required this.confidence,
    required this.headline,
    required this.reasoning,
    required this.guidance,
    this.seeProfessional = false,
  });
}

/// Inputs the classifier needs about a logged breakout.
class BreakoutSignal {
  /// Whether the formula contains an active associated with increased cell turnover.
  final bool hasCellTurnoverActive;
  final String? activeName; // for the copy, e.g. "salicylic acid"
  final int? onsetDays; // days after starting that it began
  final String? location; // 'usual' | 'new' | 'both'
  final String? type; // 'small_uniform' | 'cystic_painful' | 'mixed'
  final String?
      duration; // 'improving' | 'persistent' | 'worsening' | 'resolved'
  final bool otherNewProducts; // confounder
  const BreakoutSignal({
    required this.hasCellTurnoverActive,
    this.activeName,
    this.onsetDays,
    this.location,
    this.type,
    this.duration,
    this.otherNewProducts = false,
  });
}

/// Classifies reported symptoms; the result is not a diagnosis.
BreakoutAssessment classifyBreakout(BreakoutSignal s) {
  final active = s.activeName ?? 'active ingredients';

  // Painful cystic breakouts warrant professional advice.
  final clinical = s.type == 'cystic_painful';

  // Multiple new products prevent attribution to one formula.
  if (s.otherNewProducts) {
    return BreakoutAssessment(
      verdict: BreakoutVerdict.uncertain,
      confidence: 0.3,
      headline: 'Hard to say — a few things changed at once',
      reasoning:
          'You started other new products around the same time, so it\'s genuinely difficult to pin this on any single one.',
      guidance:
          'If you can, pause the new products and reintroduce them one at a time, a couple of weeks apart. That gives us much cleaner signal about what your skin actually reacts to.',
      seeProfessional: clinical,
    );
  }

  // No cell-turnover active → purging isn't a plausible mechanism.
  if (!s.hasCellTurnoverActive) {
    return BreakoutAssessment(
      verdict: BreakoutVerdict.likelyReaction,
      confidence: 0.6,
      headline: 'This looks more like a reaction than purging',
      reasoning:
          'This product doesn\'t contain the kind of actives (retinoids, AHAs, BHAs, vitamin C) that speed up cell turnover — and purging only happens with those. So a moisturizer, oil, or sunscreen breaking you out points to a genuine reaction rather than purging.',
      guidance:
          'Worth stopping this one and seeing if things settle. If a specific ingredient keeps coming up across products, we\'ll flag it in your ingredient profile.',
      seeProfessional: clinical,
    );
  }

  // Has an active. Score the classic purging pattern.
  final onsetOk =
      s.onsetDays == null || s.onsetDays! <= 21; // within ~1–3 weeks
  final usualZone = s.location == null || s.location == 'usual';
  final smallUniform = s.type == null || s.type == 'small_uniform';
  final trendingBetter = s.duration == null ||
      s.duration == 'improving' ||
      s.duration == 'resolved';

  // Strong "genuine reaction" overrides even with an active present.
  final newArea = s.location == 'new';
  final persistingLong = s.duration == 'worsening' ||
      (s.duration == 'persistent' && (s.onsetDays ?? 0) > 42); // past ~6 weeks

  if (clinical || newArea || persistingLong) {
    final reasons = <String>[];
    if (clinical) reasons.add('the spots are painful or cystic');
    if (newArea) {
      reasons.add('they\'re showing up in areas you don\'t usually break out');
    }
    if (persistingLong) {
      reasons.add('they\'re not settling after about six weeks');
    }
    return BreakoutAssessment(
      verdict: BreakoutVerdict.likelyReaction,
      confidence: 0.6,
      headline: 'This leans toward a genuine reaction',
      reasoning:
          'Even though $active can cause temporary purging, ${_joinReasons(reasons)} — and those patterns point away from purging.',
      guidance:
          'Consider stopping this product. Purging should stay in your usual spots, look small and uniform, and improve within about six weeks; this doesn\'t fit that.',
      seeProfessional: clinical,
    );
  }

  // Purging pattern.
  final purgingScore =
      [onsetOk, usualZone, smallUniform, trendingBetter].where((b) => b).length;
  if (purgingScore >= 3) {
    return BreakoutAssessment(
      verdict: BreakoutVerdict.likelyPurging,
      confidence: purgingScore == 4 ? 0.65 : 0.5,
      headline: 'This may be purging, not a true breakout',
      reasoning:
          'Products with $active can push existing congestion to the surface faster, so a wave of small breakouts early on — in your usual spots, improving over a few weeks — often means it\'s working, not failing.',
      guidance:
          'It usually settles within 4–6 weeks, so it\'s worth giving it a bit more time. But stop if it worsens, spreads to new areas, or starts to hurt.',
      seeProfessional: false,
    );
  }

  // Active present but pattern ambiguous.
  return const BreakoutAssessment(
    verdict: BreakoutVerdict.uncertain,
    confidence: 0.3,
    headline: 'This one\'s genuinely hard to call',
    reasoning:
        'There\'s an active that could cause purging, but the pattern isn\'t a clear match for either purging or a reaction.',
    guidance:
        'Give it a little time while watching closely. If it spreads, worsens, or hurts, treat it as a reaction and stop. Logging how it changes over the next couple of weeks will make this clearer.',
    seeProfessional: false,
  );
}

String _joinReasons(List<String> r) {
  if (r.isEmpty) return '';
  if (r.length == 1) return r.first;
  if (r.length == 2) return '${r[0]} and ${r[1]}';
  return '${r.sublist(0, r.length - 1).join(', ')}, and ${r.last}';
}

// 2. Ingredient-level trigger inference

/// One product the user has logged, reduced to what the inference needs.
class ProductReactionRecord {
  final String productId;
  final List<String> ingredientIds; // the product's notable/key ingredients
  final bool reacted; // reaction != none/null
  final bool tolerated; // used with no problem (liked and no reaction)
  const ProductReactionRecord({
    required this.productId,
    required this.ingredientIds,
    required this.reacted,
    required this.tolerated,
  });
}

enum TriggerState { tolerated, likelyTrigger, watch }

class IngredientSignal {
  final String ingredientId;
  final TriggerState state;
  final double confidence; // 0..1, for likelyTrigger
  final int reactedCount; // reacting products containing it
  final int toleratedCount; // tolerated products containing it
  final String reasoning; // plain-language explanation
  final bool userSet; // came from a manual user flag
  const IngredientSignal({
    required this.ingredientId,
    required this.state,
    required this.confidence,
    required this.reactedCount,
    required this.toleratedCount,
    required this.reasoning,
    this.userSet = false,
  });
}

/// Manual user overrides: flag -> set of ingredientIds.
class UserIngredientFlags {
  final Set<String> triggers; // user-confirmed triggers / allergies
  final Set<String> tolerated; // user-confirmed safe
  final Set<String> dismissed; // "stop suggesting this"
  const UserIngredientFlags({
    this.triggers = const {},
    this.tolerated = const {},
    this.dismissed = const {},
  });
}

/// Minimum reacting-product count before we'll call something a "likely
/// trigger" (below this it's a quiet "watch" item).
const int kTriggerMinReactions = 2;

/// Infer per-user ingredient sensitivities from logged reactions.
///
///  * Each reacting product adds suspect weight to its ingredients.
///  * Each tolerated product adds tolerated weight to its ingredients.
///  * An ingredient that also appears in several tolerated products is
///    down-weighted as a suspect: if you tolerate it elsewhere, it's probably
///    not the culprit here.
///  * We only surface "likely trigger" once the signal crosses a confidence
///    threshold based on sample size; below that it's a quiet "watch".
///  * User flags always win.
List<IngredientSignal> inferIngredientTriggers(
  List<ProductReactionRecord> records, {
  UserIngredientFlags flags = const UserIngredientFlags(),
}) {
  final reacted = <String, int>{};
  final tolerated = <String, int>{};
  final all = <String>{};

  for (final r in records) {
    for (final ing in r.ingredientIds) {
      all.add(ing);
      if (r.reacted) reacted[ing] = (reacted[ing] ?? 0) + 1;
      if (r.tolerated) tolerated[ing] = (tolerated[ing] ?? 0) + 1;
    }
  }

  // Union with any ingredients the user flagged manually.
  all
    ..addAll(flags.triggers)
    ..addAll(flags.tolerated);

  final out = <IngredientSignal>[];
  for (final ing in all) {
    final rc = reacted[ing] ?? 0;
    final tc = tolerated[ing] ?? 0;

    if (flags.triggers.contains(ing)) {
      out.add(IngredientSignal(
        ingredientId: ing,
        state: TriggerState.likelyTrigger,
        confidence: 1.0,
        reactedCount: rc,
        toleratedCount: tc,
        userSet: true,
        reasoning:
            'You told us this is a personal trigger, so we treat it as one.',
      ));
      continue;
    }
    if (flags.tolerated.contains(ing)) {
      out.add(IngredientSignal(
        ingredientId: ing,
        state: TriggerState.tolerated,
        confidence: 1.0,
        reactedCount: rc,
        toleratedCount: tc,
        userSet: true,
        reasoning:
            'You told us this one is fine for you — that overrides any generic warning.',
      ));
      continue;
    }

    // Down-weight suspicion by how often the user tolerates it elsewhere.
    // effectiveSuspicion = reactions - 0.5 per tolerated appearance.
    final effectiveSuspicion = rc - 0.5 * tc;

    if (rc == 0 && tc > 0) {
      out.add(IngredientSignal(
        ingredientId: ing,
        state: TriggerState.tolerated,
        confidence: (tc / (tc + 1)).clamp(0.0, 0.9),
        reactedCount: rc,
        toleratedCount: tc,
        reasoning: tc == 1
            ? 'Appears in a product you\'ve used without trouble.'
            : 'Appears in $tc products you\'ve used without trouble — looks fine for you so far.',
      ));
      continue;
    }

    // Dismissed guesses stay as "watch" at most, never surface as trigger.
    final dismissed = flags.dismissed.contains(ing);

    if (!dismissed && rc >= kTriggerMinReactions && effectiveSuspicion >= 1.5) {
      // Confidence grows with reactions, shrinks with tolerated appearances
      // and small samples.
      final base = effectiveSuspicion / (rc + tc + 1);
      final sampleBoost = (rc / (rc + 2));
      final confidence = (0.35 + 0.5 * base * sampleBoost).clamp(0.3, 0.85);
      out.add(IngredientSignal(
        ingredientId: ing,
        state: TriggerState.likelyTrigger,
        confidence: confidence,
        reactedCount: rc,
        toleratedCount: tc,
        reasoning: _triggerReasoning(rc, tc),
      ));
      continue;
    }

    // Everything else: a quiet watch item.
    if (rc > 0) {
      out.add(IngredientSignal(
        ingredientId: ing,
        state: TriggerState.watch,
        confidence: 0.0,
        reactedCount: rc,
        toleratedCount: tc,
        reasoning: dismissed
            ? 'You dismissed this as a trigger, so we\'re keeping quiet about it — just tracking in the background.'
            : tc > 0
                ? 'Showed up in a reaction, but you also tolerate it elsewhere, so it\'s probably not the culprit. Watching quietly.'
                : 'Showed up in one reaction — not enough to draw a conclusion yet. Watching quietly.',
      ));
    }
  }

  // Most actionable first: triggers, then watch, then tolerated.
  int rank(TriggerState s) => switch (s) {
        TriggerState.likelyTrigger => 0,
        TriggerState.watch => 1,
        TriggerState.tolerated => 2,
      };
  out.sort((a, b) {
    final r = rank(a.state).compareTo(rank(b.state));
    if (r != 0) return r;
    return b.confidence.compareTo(a.confidence);
  });
  return out;
}

String _triggerReasoning(int rc, int tc) {
  final base =
      'You\'ve reacted to $rc products that all contain this ingredient';
  if (tc == 0) {
    return '$base. That\'s enough of a pattern to flag it as a possible personal trigger — worth patch-testing before you try products with it.';
  }
  return '$base, though you\'ve also been fine with it in $tc other product${tc == 1 ? '' : 's'}, so it\'s not clear-cut. Might be a personal trigger — patch-test to be safe.';
}

enum Compatibility { compatible, caution, trigger, unknown }

class CompatibilityResult {
  final Compatibility level;
  final String message;
  final List<String> flaggedIngredientIds;
  const CompatibilityResult({
    required this.level,
    required this.message,
    this.flaggedIngredientIds = const [],
  });
}

/// Compares key ingredients with the user’s inferred and manual flags.
CompatibilityResult annotateProduct({
  required List<String> productIngredientIds,
  required List<IngredientSignal> profile,
}) {
  if (productIngredientIds.isEmpty || profile.isEmpty) {
    return const CompatibilityResult(
      level: Compatibility.unknown,
      message:
          'Not enough of your history yet to say how this suits you personally. Log a few products and this gets smarter.',
    );
  }

  final byId = {for (final s in profile) s.ingredientId: s};
  final triggers = <String>[];
  final cautions = <String>[];
  var anyTolerated = false;

  for (final ing in productIngredientIds) {
    final sig = byId[ing];
    if (sig == null) continue;
    switch (sig.state) {
      case TriggerState.likelyTrigger:
        // Already passed the inference threshold (or is user-confirmed) to
        // reach this state, so it surfaces as a trigger; the confidence is
        // conveyed in the message wording, not by re-gating here.
        triggers.add(ing);
        break;
      case TriggerState.watch:
        cautions.add(ing);
        break;
      case TriggerState.tolerated:
        anyTolerated = true;
        break;
    }
  }

  if (triggers.isNotEmpty) {
    return CompatibilityResult(
      level: Compatibility.trigger,
      flaggedIngredientIds: triggers,
      message:
          'Heads up — this contains ${triggers.length == 1 ? 'an ingredient' : 'ingredients'} that your history flags as a possible personal trigger. Products can be hard to predict, so if you try it, patch-test first.',
    );
  }
  if (cautions.isNotEmpty) {
    return CompatibilityResult(
      level: Compatibility.caution,
      flaggedIngredientIds: cautions,
      message:
          'This has something we\'re still watching in your history — it\'s shown up in a reaction before but isn\'t clear-cut. Worth a patch test.',
    );
  }
  if (anyTolerated) {
    return const CompatibilityResult(
      level: Compatibility.compatible,
      message:
          'Looks compatible with your history — its key ingredients are ones you\'ve tolerated before. Still a best guess, not a promise.',
    );
  }
  return const CompatibilityResult(
    level: Compatibility.unknown,
    message: 'Nothing in your history stands out for or against this one yet.',
  );
}
