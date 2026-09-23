import 'support/memory_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mvse/data/repositories/personal_storage.dart';
import 'package:mvse/providers/beauty_book.dart';
import 'package:mvse/providers/providers.dart';
import 'package:mvse/providers/saved_products.dart';
import 'package:mvse/data/models/models.dart';

void main() {
  test(
      'switching accounts isolates profiles and saves; returning restores them',
      () async {
    final user = StateProvider<String?>((_) => null);
    final storage = MemoryStorage();
    final c = ProviderContainer(overrides: [
      currentUserIdProvider.overrideWith((ref) => ref.watch(user)),
      personalStorageProvider.overrideWithValue(storage)
    ]);
    addTearDown(c.dispose);
    const p = Product(
        id: 'one',
        brand: 'Test',
        name: 'Product',
        category: ProductCategory.blush);
    storage.data['null:book'] = {'season': 'True Winter'};
    storage.data['null:shelf'] = {
      'keys': ['test|product']
    };
    expect((await c.read(beautyBookProvider.future)).season, isEmpty);
    expect(await c.read(savedProductsProvider.future), isEmpty);
    await expectLater(
        c
            .read(beautyBookProvider.notifier)
            .profile(season: 'Winter', depth: '', undertone: ''),
        throwsStateError);
    await expectLater(
        c.read(savedProductsProvider.notifier).toggle(p), throwsStateError);
    c.read(user.notifier).state = 'account-a';
    expect((await c.read(beautyBookProvider.future)).season, isEmpty);
    await c
        .read(beautyBookProvider.notifier)
        .profile(season: 'Soft Autumn', depth: '', undertone: '');
    await c.read(savedProductsProvider.notifier).toggle(p);
    c.read(user.notifier).state = 'account-b';
    expect((await c.read(beautyBookProvider.future)).season, isEmpty);
    expect(await c.read(savedProductsProvider.future), isEmpty);
    await c
        .read(beautyBookProvider.notifier)
        .profile(season: 'True Winter', depth: '', undertone: '');
    c.read(user.notifier).state = 'account-a';
    expect((await c.read(beautyBookProvider.future)).season, 'Soft Autumn');
    expect(await c.read(savedProductsProvider.future), {'test|product'});
    c.read(user.notifier).state = null;
    expect((await c.read(beautyBookProvider.future)).season, isEmpty);
    expect(await c.read(savedProductsProvider.future), isEmpty);
  });
  test('a failed account write is not shown as saved', () async {
    final storage = MemoryStorage();
    final c = ProviderContainer(overrides: [
      currentUserIdProvider.overrideWithValue('account-a'),
      personalStorageProvider.overrideWithValue(storage)
    ]);
    addTearDown(c.dispose);
    await c.read(beautyBookProvider.future);
    storage.fail = true;
    await expectLater(
        c
            .read(beautyBookProvider.notifier)
            .profile(season: 'True Winter', depth: '', undertone: ''),
        throwsStateError);
    expect((await c.read(beautyBookProvider.future)).season, isEmpty);
  });
}
