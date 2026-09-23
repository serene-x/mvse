import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mvse/app.dart';
import 'package:mvse/data/beauty_details.dart';
import 'package:mvse/data/models/models.dart';
import 'package:mvse/features/colour/season_browser_screen.dart';
import 'package:mvse/logic/beauty_book.dart';
import 'package:mvse/logic/shade_matching.dart';
import 'package:mvse/providers/beauty_book.dart';
import 'package:mvse/providers/providers.dart';
import 'package:mvse/router.dart';
import 'package:mvse/widgets/season_selector.dart';

const blush = Product(
    id: 'blush', name: 'Blush', brand: 'Test', category: ProductCategory.blush);
const details = BeautyDetails(ingredients: 'Glycerin', shades: [
  BrandShade(name: 'Coral'),
  BrandShade(name: 'Mauve'),
  BrandShade(name: 'Clay'),
  BrandShade(name: 'Berry')
], shadeDescriptions: {
  'Coral': 'peach',
  'Mauve': 'soft mauve',
  'Clay': 'terracotta',
  'Berry': 'cool berry'
});

void main() {
  test('four-season browsing requires a selection and does not save a profile',
      () async {
    final c = ProviderContainer(overrides: [
      currentUserIdProvider.overrideWithValue(null),
      discoveryFeedProvider(null).overrideWith((_) async => [blush]),
      beautyDetailsProvider.overrideWith((_) async => {'test|blush': details})
    ]);
    addTearDown(c.dispose);
    expect(c.read(browseSeasonProvider), isNull);
    expect(await c.read(seasonPicksProvider.future), isEmpty);
    for (final entry in {
      'Spring': 'Coral',
      'Summer': 'Mauve',
      'Fall': 'Clay',
      'Winter': 'Berry'
    }.entries) {
      c.read(browseSeasonProvider.notifier).state = entry.key;
      final picks = await c.read(seasonPicksProvider.future);
      expect(picks.single.$2.single.shade, entry.value);
      expect((await c.read(beautyBookProvider.future)).season, isEmpty);
      expect(await c.read(forYouFeedProvider.future), isEmpty);
    }
    c.read(browseSeasonProvider.notifier).state = null;
    expect(await c.read(seasonPicksProvider.future), isEmpty);
  });

  test('flattering shades can suggest a season without assigning it', () {
    final book = BeautyBook(notes: [
      for (final key in ['a', 'b', 'c'])
        WearNote(
            productKey: key,
            shade: 'Berry',
            fit: 'Flattering colour',
            family: 'Cool berry / plum')
    ]);
    expect(seasonSuggestions(book.notes), isNotEmpty);
    expect(recommendShades('test|blush', details, book, complexion: false),
        isEmpty);
    expect(book.season, isEmpty);
  });

  testWidgets(
      'guests can explore seasons and ingredients but personal routes require sign-in',
      (tester) async {
    final c = ProviderContainer(overrides: [
      currentUserIdProvider.overrideWithValue(null),
      discoveryFeedProvider(null).overrideWith((_) async => [blush]),
      productProvider('blush').overrideWith((_) async => blush),
      keyIngredientsProvider('blush').overrideWith((_) async => []),
      beautyDetailsProvider.overrideWith((_) async => {'test|blush': details})
    ]);
    addTearDown(c.dispose);
    await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const MvseApp()));
    await tester.pumpAndSettle();
    final router = c.read(routerProvider);
    router.go('/seasons');
    await tester.pumpAndSettle();
    expect(find.text('Find your palette.'), findsOneWidget);
    expect(c.read(browseSeasonProvider), isNull);
    await tester
        .tap(find.widgetWithText(DropdownMenu<String>, 'Choose a season'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Summer').last);
    await tester.pumpAndSettle();
    expect(find.text('Mauve'), findsOneWidget);
    await tester.tap(find.text('Test / Blush'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/product/blush');
    await tester.tap(find.text('Add wear note'));
    await tester.pumpAndSettle();
    expect(find.text('Continue browsing'), findsOneWidget);
    for (final path in ['/colour', '/for-you', '/twins', '/routine']) {
      router.go(path);
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/auth/sign-in');
    }
    expect(tester.takeException(), isNull);
  });
}
