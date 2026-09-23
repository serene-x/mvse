// Estimates undertone and palette preferences from product feedback.

enum ShadeObservation {
  greatMatch,
  oxidizedOrange, // foundation turned orange on them
  turnedPink, // foundation went pink / rosy
  turnedGreyAshy, // foundation went grey / ashy / muted
  washedOut, // made them look washed out / sallow
  tooDark,
  tooLight,
}

const shadeObservationKeys = <ShadeObservation, String>{
  ShadeObservation.greatMatch: 'great_match',
  ShadeObservation.oxidizedOrange: 'oxidized_orange',
  ShadeObservation.turnedPink: 'turned_pink',
  ShadeObservation.turnedGreyAshy: 'turned_grey_ashy',
  ShadeObservation.washedOut: 'washed_out',
  ShadeObservation.tooDark: 'too_dark',
  ShadeObservation.tooLight: 'too_light',
};

String shadeObservationLabel(ShadeObservation o) {
  switch (o) {
    case ShadeObservation.greatMatch:
      return 'Great match';
    case ShadeObservation.oxidizedOrange:
      return 'Turned orange';
    case ShadeObservation.turnedPink:
      return 'Turned pink / rosy';
    case ShadeObservation.turnedGreyAshy:
      return 'Went grey / ashy';
    case ShadeObservation.washedOut:
      return 'Washed me out';
    case ShadeObservation.tooDark:
      return 'Too dark';
    case ShadeObservation.tooLight:
      return 'Too light';
  }
}

ShadeObservation? shadeObservationFromKey(String k) {
  for (final e in shadeObservationKeys.entries) {
    if (e.value == k) return e.key;
  }
  return null;
}

/// Blush/lip family the user liked or disliked: a strong undertone tell.
enum ColorFamily {
  coolPinkBerry,
  warmCoralPeach,
  neutralRose,
  brightBlueRed,
  warmBrick
}

const colorFamilyKeys = <ColorFamily, String>{
  ColorFamily.coolPinkBerry: 'family_cool_pink_berry',
  ColorFamily.warmCoralPeach: 'family_warm_coral_peach',
  ColorFamily.neutralRose: 'family_neutral_rose',
  ColorFamily.brightBlueRed: 'family_bright_blue_red',
  ColorFamily.warmBrick: 'family_warm_brick',
};

String colorFamilyLabel(ColorFamily f) {
  switch (f) {
    case ColorFamily.coolPinkBerry:
      return 'Cool pink / berry';
    case ColorFamily.warmCoralPeach:
      return 'Coral / peach';
    case ColorFamily.neutralRose:
      return 'Neutral rose';
    case ColorFamily.brightBlueRed:
      return 'Blue-red';
    case ColorFamily.warmBrick:
      return 'Brick / terracotta';
  }
}

ColorFamily? colorFamilyFromKey(String k) {
  for (final e in colorFamilyKeys.entries) {
    if (e.value == k) return e.key;
  }
  return null;
}

/// A liked/disliked makeup signal.
class MakeupSignal {
  final bool isFoundation;
  final bool liked;
  final List<ShadeObservation> observations; // foundation outcomes
  final ColorFamily? colorFamily; // for blush/lip
  const MakeupSignal({
    required this.isFoundation,
    required this.liked,
    this.observations = const [],
    this.colorFamily,
  });
}

enum UndertoneLean { warm, cool, neutral, olive }

enum ConfidenceBand { low, medium, high }

String confidenceLabel(ConfidenceBand c) {
  switch (c) {
    case ConfidenceBand.low:
      return 'low confidence';
    case ConfidenceBand.medium:
      return 'medium confidence';
    case ConfidenceBand.high:
      return 'fairly confident';
  }
}

class UndertoneInference {
  final UndertoneLean? lean; // null = not enough signal
  final ConfidenceBand confidence;
  final String? season; // e.g. "likely cool summer / winter"
  final String reasoning;
  final bool oliveDetected;
  const UndertoneInference({
    required this.lean,
    required this.confidence,
    this.season,
    required this.reasoning,
    this.oliveDetected = false,
  });
}

/// Infer undertone lean + likely season from makeup signals.
UndertoneInference inferUndertone(
  List<MakeupSignal> signals, {
  String? depthHint, // optional skin-depth description to shape the season
}) {
  if (signals.isEmpty) {
    return const UndertoneInference(
      lean: null,
      confidence: ConfidenceBand.low,
      reasoning:
          'Not enough makeup logged yet to read your undertone. Log a few foundations, blushes, or lippies you love or hate and this fills in.',
    );
  }

  var warm = 0.0, cool = 0.0, olive = 0.0;
  var orangeOutcome = false, pinkOutcome = false, ashyOutcome = false;

  for (final s in signals) {
    for (final o in s.observations) {
      switch (o) {
        case ShadeObservation.oxidizedOrange:
          orangeOutcome = true;
          // A foundation going orange means it was too warm for them → cool lean,
          // but it's also part of the olive pattern; both get a nudge.
          cool += 0.7;
          olive += 0.6;
          break;
        case ShadeObservation.turnedPink:
          pinkOutcome = true;
          warm += 0.6; // too cool for them → they lean warmer
          olive += 0.5;
          break;
        case ShadeObservation.turnedGreyAshy:
          ashyOutcome = true;
          olive += 1.2; // classic olive tell
          break;
        case ShadeObservation.washedOut:
          olive += 0.3;
          break;
        case ShadeObservation.greatMatch:
        case ShadeObservation.tooDark:
        case ShadeObservation.tooLight:
          break; // depth, not undertone
      }
    }

    if (s.colorFamily != null) {
      final w = s.liked ? 1.0 : -0.7; // disliking a family votes the other way
      switch (s.colorFamily!) {
        case ColorFamily.coolPinkBerry:
        case ColorFamily.brightBlueRed:
          cool += w;
          warm -= w * 0.5;
          break;
        case ColorFamily.warmCoralPeach:
        case ColorFamily.warmBrick:
          warm += w;
          cool -= w * 0.5;
          break;
        case ColorFamily.neutralRose:
          // neutral-leaning, weak signal both ways
          break;
      }
    }
  }

  //     result are the hallmark. Olive is its own category, so it overrides. ---
  final contradictory = orangeOutcome && pinkOutcome;
  if (ashyOutcome || contradictory || olive >= 1.5) {
    return UndertoneInference(
      lean: UndertoneLean.olive,
      confidence: (ashyOutcome && olive >= 1.5)
          ? ConfidenceBand.medium
          : ConfidenceBand.low,
      oliveDetected: true,
      season: null,
      reasoning:
          'These shade outcomes can have several causes, including depth, formula changes and lighting. Olive is one possibility to explore, not a conclusion. Olive skin can have a colour season. Use the shade book to record exact successful shades.',
    );
  }

  final diff = warm - cool;
  final magnitude = diff.abs();
  final signalCount = signals.length;

  UndertoneLean lean;
  if (magnitude < 0.6) {
    lean = UndertoneLean.neutral;
  } else if (diff > 0) {
    lean = UndertoneLean.warm;
  } else {
    lean = UndertoneLean.cool;
  }

  final confidence = (magnitude >= 2.0 && signalCount >= 3)
      ? ConfidenceBand.high
      : (magnitude >= 1.0 && signalCount >= 2)
          ? ConfidenceBand.medium
          : ConfidenceBand.low;

  return UndertoneInference(
    lean: lean,
    confidence: confidence,
    season: null,
    reasoning: _reasoning(lean, confidence, warm, cool),
  );
}

String _reasoning(
    UndertoneLean lean, ConfidenceBand c, double warm, double cool) {
  final leanWord = switch (lean) {
    UndertoneLean.warm => 'warm',
    UndertoneLean.cool => 'cool',
    UndertoneLean.neutral => 'fairly neutral',
    UndertoneLean.olive => 'olive',
  };
  final base =
      'From the shades you liked and disliked, you seem to lean $leanWord (${confidenceLabel(c)}).';
  const hedge =
      ' This is a best guess from your makeup history, not a colour analysis. Lighting and formula changes can affect the result. Record exact successful shades in your shade book.';
  return base + hedge;
}
