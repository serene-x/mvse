import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/catalog.dart';
import '../data/models/models.dart';
import '../data/repositories/personal_storage.dart';
import 'providers.dart';

final savedProductsProvider =
    AsyncNotifierProvider<SavedProducts, Set<String>>(SavedProducts.new);

class SavedProducts extends AsyncNotifier<Set<String>> {
  static const storageKey = 'mvse.savedProducts.v1';
  Future<void> _pending = Future.value();
  @override
  Future<Set<String>> build() async {
    final uid = ref.watch(currentUserIdProvider);
    if (uid == null) return <String>{};
    final data =
        await ref.watch(personalStorageProvider).read(uid, 'shelf', storageKey);
    return (data?['keys'] as List? ?? []).whereType<String>().toSet();
  }

  Future<void> toggle(Product product) {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) {
      return Future.error(StateError('Sign in to save products.'));
    }
    final storage = ref.read(personalStorageProvider);
    final op = _pending.then((_) async {
      final updated = {...await future};
      if (ref.read(currentUserIdProvider) != uid) {
        throw StateError('Account changed. Try again.');
      }
      final key = BundledCatalog.key(product);
      if (!updated.remove(key)) updated.add(key);
      await storage.write(uid, 'shelf', storageKey, {'keys': updated.toList()});
      if (ref.read(currentUserIdProvider) == uid) state = AsyncData(updated);
    });
    _pending = op.catchError((Object _) {});
    return op;
  }
}
