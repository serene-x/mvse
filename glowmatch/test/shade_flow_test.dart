import 'support/memory_storage.dart';
import 'package:mvse/data/repositories/personal_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mvse/data/models/models.dart';
import 'package:mvse/data/beauty_details.dart';
import 'package:mvse/features/product/product_screen.dart';
import 'package:mvse/providers/providers.dart';
import 'package:mvse/providers/beauty_book.dart';
import 'package:mvse/theme.dart';
import 'package:mvse/widgets/product_image.dart';

void main() {
  testWidgets(
      'account selects a shade, records wear, and sees a personal recommendation at 320px',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const p = Product(
        id: 'test-product',
        name: 'Test Blush',
        brand: 'Test Brand',
        category: ProductCategory.blush);
    final c = ProviderContainer(overrides: [
      currentUserIdProvider.overrideWithValue('test-account'),
      personalStorageProvider.overrideWithValue(MemoryStorage()),
      productProvider(p.id).overrideWith((ref) async => p),
      keyIngredientsProvider(p.id).overrideWith((ref) async => []),
      beautyDetailsProvider.overrideWith((ref) async => {
            'test brand|test blush': const BeautyDetails(
                url: 'https://example.com/blush',
                checked: '2026-09-23',
                ingredients: 'Glycerin, Squalane',
                shadeDescriptions: {'Hope': 'nude mauve'},
                shades: [BrandShade(name: 'Hope')])
          })
    ]);
    addTearDown(c.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
            theme: buildTheme(),
            home: const ProductScreen(productId: 'test-product'))));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.widgetWithText(DropdownMenu<String>, 'Select your shade'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(
        find.widgetWithText(DropdownMenu<String>, 'Select your shade'));
    await tester.pumpAndSettle();
    await tester
        .tap(find.widgetWithText(DropdownMenu<String>, 'Select your shade'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hope').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Add wear note'), -200,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Add wear note'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add wear note'));
    await tester.pumpAndSettle();
    expect(find.textContaining('TikTok'), findsNothing);
    expect(find.text('Review link (optional)'), findsNothing);
    expect(
        tester
            .widget<DropdownMenu<String>>(
                find.widgetWithText(DropdownMenu<String>, 'Shade name'))
            .initialSelection,
        'Hope');
    await tester.tap(find.widgetWithText(
        DropdownButtonFormField<String>, 'How does this shade look on you?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Flattering colour').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save wear note'));
    await tester.tap(find.text('Save wear note'));
    await tester.pumpAndSettle();
    final book = await c.read(beautyBookProvider.future);
    expect(book.notes.single.shade, 'Hope');
    expect(book.notes.single.family, 'Soft rose / mauve');
    await tester.scrollUntilVisible(
        find.text('You recorded this as flattering colour.'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(
        find.text('You recorded this as flattering colour.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('shade changes keep the product photo and ingredient list',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const p = Product(
        id: 'blush',
        name: 'Blush',
        brand: 'Test',
        category: ProductCategory.blush);
    final c = ProviderContainer(overrides: [
      currentUserIdProvider.overrideWithValue('test-account'),
      personalStorageProvider.overrideWithValue(MemoryStorage()),
      productProvider(p.id).overrideWith((ref) async => p),
      keyIngredientsProvider(p.id).overrideWith((ref) async => []),
      beautyDetailsProvider.overrideWith((ref) async => {
            'test|blush': const BeautyDetails(
                ingredients: 'Glycerin, Squalane, Isopropyl Myristate',
                shades: [BrandShade(name: 'Rose'), BrandShade(name: 'Peach')])
          })
    ]);
    addTearDown(c.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
            theme: buildTheme(), home: ProductScreen(productId: p.id))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Full ingredient list'));
    await tester.pumpAndSettle();
    for (final name in ['Rose', 'Peach']) {
      await tester
          .tap(find.widgetWithText(DropdownMenu<String>, 'Select your shade'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(name).last);
      await tester.pumpAndSettle();
      expect(
          find.text('Glycerin, Squalane, Isopropyl Myristate'), findsOneWidget);
      expect(find.text('isopropyl myristate'), findsOneWidget);
      expect(find.byType(ProductImage), findsOneWidget);
      expect(tester.widget<ProductImage>(find.byType(ProductImage)).product.id,
          p.id);
      expect(find.text('Brand ingredient lists by shade'), findsNothing);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'skincare has no shade controls or recommendations and saves a skin response',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const p = Product(
        id: 'cream',
        name: 'Cream',
        brand: 'Test',
        category: ProductCategory.moisturizer);
    final c = ProviderContainer(overrides: [
      currentUserIdProvider.overrideWithValue('test-account'),
      personalStorageProvider.overrideWithValue(MemoryStorage()),
      productProvider(p.id).overrideWith((ref) async => p),
      keyIngredientsProvider(p.id).overrideWith((ref) async => []),
      beautyDetailsProvider.overrideWith((ref) async => {
            'test|cream': const BeautyDetails(
                ingredients: 'Glycerin, Squalane',
                shades: [BrandShade(name: 'Invalid legacy shade')])
          })
    ]);
    addTearDown(c.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
            theme: buildTheme(), home: ProductScreen(productId: p.id))));
    await tester.pumpAndSettle();
    expect(find.text('Choose a shade'), findsNothing);
    expect(find.text('Your shade shortlist'), findsNothing);
    expect(find.widgetWithText(DropdownMenu<String>, 'Select your shade'),
        findsNothing);
    expect(find.text('Key ingredients'), findsOneWidget);
    await tester.tap(find.text('Add wear note'));
    await tester.pumpAndSettle();
    expect(find.text('Shade name'), findsNothing);
    expect(find.text('How does this shade look on you?'), findsNothing);
    expect(find.text('Colour family (check against your shade)'), findsNothing);
    await tester.tap(find.widgetWithText(
        DropdownButtonFormField<String>, 'Your skin’s response'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tolerated').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save wear note'));
    await tester.pumpAndSettle();
    final note = (await c.read(beautyBookProvider.future)).notes.single;
    expect(note.shade, isEmpty);
    expect(note.fit, isEmpty);
    expect(note.family, isEmpty);
    expect(note.reaction, 'Tolerated');
    expect(tester.takeException(), isNull);
  });
}
