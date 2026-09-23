// Aggregates makeup finish preferences from product feedback.

class FinishSignal {
  final String finish; // e.g. "matte", "dewy", "radiant", "satin"
  final bool liked; // finish attribute rated up (true) or down (false)
  const FinishSignal({required this.finish, required this.liked});
}

class FinishPreference {
  final List<String> preferred; // finishes they consistently like
  final List<String> disliked; // finishes they consistently dislike
  final String? recommendation; // plain-language suggestion, null if unclear
  const FinishPreference({
    this.preferred = const [],
    this.disliked = const [],
    this.recommendation,
  });

  bool get hasSignal => preferred.isNotEmpty || disliked.isNotEmpty;
}

FinishPreference inferFinishPreference(List<FinishSignal> signals) {
  if (signals.isEmpty) return const FinishPreference();

  final score = <String, int>{}; // net likes per normalized finish
  for (final s in signals) {
    final f = _normalize(s.finish);
    if (f.isEmpty) continue;
    score[f] = (score[f] ?? 0) + (s.liked ? 1 : -1);
  }

  final preferred = <String>[];
  final disliked = <String>[];
  score.forEach((f, net) {
    if (net > 0) preferred.add(f);
    if (net < 0) disliked.add(f);
  });
  preferred.sort((a, b) => (score[b]!).compareTo(score[a]!));
  disliked.sort((a, b) => (score[a]!).compareTo(score[b]!));

  if (preferred.isEmpty && disliked.isEmpty) {
    return const FinishPreference();
  }

  final parts = <String>[];
  if (preferred.isNotEmpty) {
    parts.add('you tend to like ${_join(preferred)} finishes');
  }
  if (disliked.isNotEmpty) {
    parts.add('and lean away from ${_join(disliked)}');
  }
  final rec =
      'Based on your logs, ${parts.join(' ')}. Worth favoring that when you\'re picking a new base — a soft preference, not a hard rule.';

  return FinishPreference(
      preferred: preferred, disliked: disliked, recommendation: rec);
}

// Collapse near-synonyms so "sheer glow"/"radiant"/"dewy" cluster sensibly.
String _normalize(String finish) {
  final f = finish.toLowerCase().trim();
  if (f.contains('matte')) return 'matte';
  if (f.contains('dewy') || f.contains('glow') || f.contains('radiant')) {
    return 'dewy/radiant';
  }
  if (f.contains('satin')) return 'satin';
  if (f.contains('natural')) return 'natural';
  return f;
}

String _join(List<String> xs) {
  if (xs.length == 1) return xs.first;
  if (xs.length == 2) return '${xs[0]} and ${xs[1]}';
  return '${xs.sublist(0, xs.length - 1).join(', ')}, and ${xs.last}';
}
