import 'package:mvse/providers/providers.dart';
import 'support/memory_storage.dart';
import 'package:mvse/data/repositories/personal_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mvse/data/beauty_details.dart';
import 'package:mvse/logic/beauty_book.dart';
import 'package:mvse/logic/shade_matching.dart';
import 'package:mvse/providers/beauty_book.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  WearNote colour(String key, String family, {int frequency = 1}) => WearNote(
      productKey: key,
      shade: 'named shade',
      fit: 'Flattering colour',
      family: family,
      frequency: frequency);
  test(
      'season needs three distinct products, not repeat logs or foundation depth',
      () {
    expect(
        seasonSuggestions([
          colour('a', 'Peach / coral'),
          colour('a', 'Peach / coral'),
          colour('a', 'Peach / coral')
        ]),
        isEmpty);
    expect(
        seasonSuggestions(const [
          WearNote(productKey: 'a', shade: 'Deep warm', fit: 'Skin match'),
          WearNote(productKey: 'b', shade: 'Deep warm', fit: 'Skin match'),
          WearNote(productKey: 'c', shade: 'Deep warm', fit: 'Skin match')
        ]),
        isEmpty);
  });
  test('consistent flattering colours produce tentative palette candidates',
      () {
    expect(
        seasonSuggestions([
          colour('a', 'Peach / coral'),
          colour('b', 'Peach / coral'),
          colour('c', 'Warm, clear red')
        ]),
        contains('True Spring'));
  });
  test('mixed palettes abstain', () {
    expect(
        seasonSuggestions([
          colour('a', 'Peach / coral'),
          colour('b', 'Cool berry / plum'),
          colour('c', 'Muted beige / warm nude')
        ]),
        isEmpty);
  });
  const detail = BeautyDetails(
      url: 'https://example.com/product',
      shades: [BrandShade(name: 'Happy'), BrandShade(name: 'Joy')],
      shadeDescriptions: {'Happy': 'cool pink', 'Joy': 'muted peach'});
  test('manual season overrides inferred palette', () {
    final book = BeautyBook(season: 'Light Summer', notes: [
      colour('a', 'Peach / coral'),
      colour('b', 'Peach / coral'),
      colour('c', 'Peach / coral')
    ]);
    expect(
        recommendShades('blush', detail, book, complexion: false)
            .map((s) => s.shade),
        ['Happy']);
  });
  test('a personal poor match is never shortlisted', () {
    const book = BeautyBook(season: 'Light Summer', notes: [
      WearNote(productKey: 'blush', shade: 'Happy', fit: 'Poor match')
    ]);
    expect(recommendShades('blush', detail, book, complexion: false), isEmpty);
  });
  test(
      'a community report requires the exact known formula and successful shade',
      () {
    const correct = BeautyBook(notes: [
      WearNote(
          productKey: 'nars|sheer glow foundation',
          shade: 'Mont Blanc',
          fit: 'Skin match')
    ]);
    const incorrect = BeautyBook(notes: [
      WearNote(
          productKey: 'nars|light reflecting foundation',
          shade: 'Mont Blanc',
          fit: 'Skin match')
    ]);
    const key = 'armani beauty|luminous silk perfect glow flawless foundation';
    expect(
        recommendShades(key, const BeautyDetails(), correct, complexion: true)
            .single
            .shade,
        '2');
    expect(
        recommendShades(key, const BeautyDetails(), incorrect,
            complexion: true),
        isEmpty);
  });
  test('brand comparison requires both depth and undertone', () {
    const d = BeautyDetails(
        shades: [BrandShade(name: '1 N')],
        shadeDescriptions: {'1 N': 'Light with neutral undertones'});
    expect(
        recommendShades('base', d, const BeautyBook(depth: 'Light'),
            complexion: true),
        isEmpty);
    expect(
        recommendShades('base', d,
                const BeautyBook(depth: 'Light', undertone: 'Neutral'),
                complexion: true)
            .single
            .shade,
        '1 N');
  });
  test('profile and concurrent wear notes persist without overwriting',
      () async {
    final storage = MemoryStorage();
    final overrides = [
      currentUserIdProvider.overrideWithValue('account'),
      personalStorageProvider.overrideWithValue(storage)
    ];
    var c = ProviderContainer(overrides: overrides);
    await c.read(beautyBookProvider.future);
    final n = c.read(beautyBookProvider.notifier);
    await Future.wait([
      n.profile(season: 'Soft Autumn', depth: 'Medium', undertone: 'Olive'),
      n.note(const WearNote(productKey: 'a', shade: '2', fit: 'Skin match')),
      n.note(const WearNote(productKey: 'b', reaction: 'Tolerated'))
    ]);
    c.dispose();
    c = ProviderContainer(overrides: overrides);
    final b = await c.read(beautyBookProvider.future);
    expect(b.season, 'Soft Autumn');
    expect(b.notes.length, 2);
    await c.read(beautyBookProvider.notifier).remove(b.notes.first);
    expect((await c.read(beautyBookProvider.future)).notes.length, 1);
    c.dispose();
  });
  test('bundled shade data has provenance and excludes marketing from INCI',
      () async {
    final details = await loadBeautyDetails();
    expect(details.values.fold<int>(0, (n, d) => n + d.shades.length),
        greaterThan(1100));
    for (final d in details.values) {
      expect(d.shades.map((s) => s.name).toSet().length, d.shades.length);
      for (final s in d.shades) {
        expect(s.name, isNotEmpty);
      }
      for (final text in [d.ingredients]) {
        expect(text.toLowerCase(), isNot(contains('why we don')));
        expect(text.toLowerCase(), isNot(contains('what is it:')));
      }
    }
    final rare = details['rare beauty|soft pinch liquid blush']!;
    expect(rare.ingredients, isNotEmpty);
  });
  test('new reviewed reports contribute only with a known personal skin match',
      () {
    const reports = <Map<String, dynamic>>[
      {
        'source': 'https://www.tiktok.com/@creator/video/123',
        'person': '@creator',
        'shades': <String, String>{'base-a': '1N', 'base-b': '20'}
      }
    ];
    const good = BeautyBook(notes: [
      WearNote(productKey: 'base-a', shade: '1N', fit: 'Skin match')
    ]);
    final picks = recommendShades('base-b', const BeautyDetails(), good,
        complexion: true, groups: reports);
    expect(picks.single.shade, '20');
    expect(picks.single.source, 'https://www.tiktok.com/@creator/video/123');
    expect(
        recommendShades('base-b', const BeautyDetails(), const BeautyBook(),
            complexion: true, groups: reports),
        isEmpty);
  });
}
