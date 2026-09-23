import '../data/beauty_details.dart';
import '../providers/beauty_book.dart';
import 'beauty_book.dart';

class ShadePick {
  final String shade, reason, source;
  const ShadePick(this.shade, this.reason, [this.source = '']);
}

// First-person reports, reviewed 2026-09-23. Exact formulas only.
// No synthetic TikTok data, inferred formula names, or transitive matches.
const communityGroups = [
  {
    'source':
        'https://www.reddit.com/r/Makeup/comments/1ql1xkw/difficulty_shadematching_haus_labs_foundation/',
    'person': 'SailorCutiee · January 2026',
    'shades': {
      'nars|sheer glow foundation': 'Mont Blanc',
      'armani beauty|luminous silk perfect glow flawless foundation': '2',
      'nars|light reflecting foundation': 'Yulong'
    }
  },
  {
    'source':
        'https://www.lemon8-app.com/@thaliaspage/7514938910485643819?region=us',
    'person': 'Thalia · June 2025',
    'shades': {
      'armani beauty|luminous silk perfect glow flawless foundation': '4.25',
      'estée lauder|double wear stay-in-place foundation': '4C1'
    }
  },
];
String shadeIdentity(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9.]'), '');
String depthFromDescription(String s) {
  s = s.toLowerCase();
  if (s.contains('very deep') || s.contains('rich deep')) return 'Very deep';
  if (s.contains('medium deep')) return 'Medium deep';
  if (s.contains('very light') || s.contains('fair')) return 'Fair';
  if (s.contains('light medium') || s.contains('light-medium')) {
    return 'Light medium';
  }
  if (s.contains('medium tan')) return 'Tan';
  if (s.contains('deep') || s.contains('dark')) return 'Deep';
  if (s.contains('tan')) return 'Tan';
  if (s.contains('medium')) return 'Medium';
  if (s.contains('light')) return 'Light';
  return '';
}

String undertoneFromDescription(String s) {
  s = s.toLowerCase();
  if (s.contains('olive')) return 'Olive';
  if (s.contains('neutral')) return 'Neutral';
  if (s.contains('cool')) return 'Cool';
  if (s.contains('warm') || s.contains('golden')) return 'Warm';
  return '';
}

List<ShadePick> recommendShades(
    String key, BeautyDetails details, BeautyBook book,
    {required bool complexion,
    Map<String, BeautyDetails> catalog = const {},
    List<Map<String, dynamic>> groups = communityGroups}) {
  final notes = book.notes.where((n) => n.productKey == key).toList();
  final rejected = notes
      .where((n) => n.fit == 'Poor match')
      .map((n) => shadeIdentity(n.shade))
      .toSet();
  final out = <ShadePick>[];
  for (final n in notes) {
    if ((n.fit == 'Skin match' || n.fit == 'Flattering colour') &&
        !rejected.contains(shadeIdentity(n.shade))) {
      out.add(
          ShadePick(n.shade, 'You recorded this as ${n.fit.toLowerCase()}.'));
    }
  }
  if (out.isNotEmpty) return out;
  if (complexion) {
    for (final g in groups) {
      final shades = g['shades'] as Map<String, String>;
      final target = shades[key];
      if (target == null || rejected.contains(shadeIdentity(target))) continue;
      final overlap = book.notes
          .where((n) =>
              n.fit == 'Skin match' &&
              n.productKey != key &&
              shadeIdentity(shades[n.productKey] ?? '') ==
                  shadeIdentity(n.shade) &&
              n.shade.isNotEmpty)
          .toList();
      if (overlap.isNotEmpty) {
        out.add(ShadePick(
            target,
            'Also worn by someone who matches your ${overlap.first.shade}. Worth swatching.',
            g['source'] as String));
      }
    }
    if (out.isNotEmpty) return out;
    var depth = book.depth, undertone = book.undertone;
    // Use a consensus of explicitly described, successful shades when the user
    // has not entered their own depth or undertone. Contradictions abstain.
    final depths = <String>{}, tones = <String>{};
    for (final n in book.notes.where((n) => n.fit == 'Skin match')) {
      for (final s in catalog[n.productKey]?.shades ?? <BrandShade>[]) {
        if (shadeIdentity(s.name) != shadeIdentity(n.shade)) continue;
        final d = depthFromDescription(
                catalog[n.productKey]!.description(s.name)),
            t = undertoneFromDescription(
                catalog[n.productKey]!.description(s.name));
        if (d.isNotEmpty) depths.add(d);
        if (t.isNotEmpty) tones.add(t);
      }
    }
    if (depth.isEmpty && depths.length == 1) depth = depths.single;
    if (undertone.isEmpty && tones.length == 1) undertone = tones.single;
    if (depth.isEmpty || undertone.isEmpty) return [];
    for (final s in details.shades) {
      if (rejected.contains(shadeIdentity(s.name))) continue;
      if (depthFromDescription(details.description(s.name)) == depth &&
          undertoneFromDescription(details.description(s.name)) == undertone) {
        out.add(ShadePick(
            s.name,
            'Worth swatching for your $depth / $undertone profile.',
            details.url));
      }
    }
  } else {
    final season =
        book.season; // Suggestions never assign a season for the user.
    if (season.isEmpty) return [];
    for (final s in details.shades) {
      if (rejected.contains(shadeIdentity(s.name))) continue;
      final family = familyFromDescription(details.description(s.name));
      if (paletteFamilies[family]?.any((s) =>
              s == season ||
              s.endsWith(' ${season == 'Fall' ? 'Autumn' : season}')) ??
          false) {
        out.add(ShadePick(s.name, 'A colour to try for $season.', details.url));
      }
    }
  }
  return out.take(3).toList();
}
