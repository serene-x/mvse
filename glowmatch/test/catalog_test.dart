import 'package:mvse/providers/providers.dart';
import 'support/memory_storage.dart';
import 'package:mvse/data/repositories/personal_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mvse/data/catalog.dart';
import 'package:mvse/data/models/models.dart';
import 'package:mvse/data/repositories/product_repository.dart';
import 'package:mvse/providers/saved_products.dart';
import 'package:mvse/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('bundled catalog has 185 unique products across 22 categories',
      () async {
    final products = await BundledCatalog.load();
    expect(products.length, 185);
    expect(products.map((p) => p.id).toSet().length, products.length);
    expect(products.map(BundledCatalog.key).toSet().length, products.length);
    expect(
        products.every((p) => p.name.isNotEmpty && p.brand.isNotEmpty), isTrue);
    expect(products.map((p) => p.category).toSet().length, 22);
  });
  test('search handles punctuation, multiple words, and category groups',
      () async {
    final repo = ProductRepository();
    expect(await repo.search(query: 'e.l.f. mascara'), isNotEmpty);
    expect(await repo.search(query: '  RARE beauty '), isNotEmpty);
    expect(await repo.search(query: '%,()'), isEmpty);
    final skincare =
        await repo.search(query: '', category: ProductCategory.skincare);
    expect(skincare, isNotEmpty);
    expect(skincare.every((p) => isSkincare(p.category)), isTrue);
    final mascara =
        await repo.search(query: '', category: ProductCategory.mascara);
    expect(mascara.every((p) => p.category == ProductCategory.mascara), isTrue);
    expect(await repo.fetchProduct(mascara.first.id), isNotNull);
    expect(await repo.fetchProduct('catalog-missing'), isNull);
  });
  test('saved products survive a new provider container and can be removed',
      () async {
    final product = (await BundledCatalog.load()).first;
    final storage = MemoryStorage();
    final overrides = [
      currentUserIdProvider.overrideWithValue('account'),
      personalStorageProvider.overrideWithValue(storage)
    ];
    var container = ProviderContainer(overrides: overrides);
    await container.read(savedProductsProvider.future);
    await container.read(savedProductsProvider.notifier).toggle(product);
    container.dispose();
    container = ProviderContainer(overrides: overrides);
    expect(await container.read(savedProductsProvider.future),
        contains(BundledCatalog.key(product)));
    await container.read(savedProductsProvider.notifier).toggle(product);
    expect(await container.read(savedProductsProvider.future), isEmpty);
    container.dispose();
  });
  testWidgets(
      'guest launches without Supabase and must sign in to save a shelf',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MvseApp()));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();
    expect(find.text('Your shades,\nin one place.'), findsOneWidget);
    await tester.tap(find.text('My shelf'));
    await tester.pumpAndSettle();
    expect(find.text('Your beauty shelf.'), findsNothing);
    expect(find.text('Continue browsing'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  test('simultaneous saves do not overwrite one another', () async {
    final products = await BundledCatalog.load();
    final container = ProviderContainer(overrides: [
      currentUserIdProvider.overrideWithValue('account'),
      personalStorageProvider.overrideWithValue(MemoryStorage())
    ]);
    addTearDown(container.dispose);
    await container.read(savedProductsProvider.future);
    final notifier = container.read(savedProductsProvider.notifier);
    await Future.wait(
        [notifier.toggle(products[0]), notifier.toggle(products[1])]);
    expect((await container.read(savedProductsProvider.future)).length, 2);
  });
  for (final width in [320.0, 390.0, 1280.0]) {
    testWidgets('catalog fits a $width pixel viewport', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const ProviderScope(child: MvseApp()));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();
      // Flutter reports layout errors at the end of the test.
    });
  }
}
