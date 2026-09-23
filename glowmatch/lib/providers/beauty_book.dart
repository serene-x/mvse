import '../data/repositories/personal_storage.dart';
import 'providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logic/beauty_book.dart';
import '../data/models/models.dart';
import '../data/catalog.dart';

class BeautyBook {
  final String season, depth, undertone;
  final List<WearNote> notes;
  const BeautyBook(
      {this.season = '',
      this.depth = '',
      this.undertone = '',
      this.notes = const []});
  factory BeautyBook.fromJson(Map<String, dynamic> j) => BeautyBook(
      season: j['season'] as String? ?? '',
      depth: j['depth'] as String? ?? '',
      undertone: j['undertone'] as String? ?? '',
      notes: (j['notes'] as List? ?? [])
          .whereType<Map>()
          .where((n) => n['product'] is String)
          .map((n) => WearNote.fromJson(Map<String, dynamic>.from(n)))
          .toList());
  Map<String, dynamic> toJson() => {
        'season': season,
        'depth': depth,
        'undertone': undertone,
        'notes': notes.map((n) => n.toJson()).toList()
      };
}

final beautyBookProvider =
    AsyncNotifierProvider<BeautyBookNotifier, BeautyBook>(
        BeautyBookNotifier.new);

class BeautyBookNotifier extends AsyncNotifier<BeautyBook> {
  static const key = 'mvse.beautyBook.v1';
  Future<void> _pending = Future.value();
  @override
  Future<BeautyBook> build() async {
    final uid = ref.watch(currentUserIdProvider);
    if (uid == null) return const BeautyBook();
    final storage = ref.watch(personalStorageProvider);
    return BeautyBook.fromJson(await storage.read(uid, 'book', key) ?? {});
  }

  Future<void> mutate(BeautyBook Function(BeautyBook) change) {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) {
      return Future.error(StateError('Sign in to save your profile.'));
    }
    final storage = ref.read(personalStorageProvider);
    final op = _pending.then((_) async {
      final current = await future;
      if (ref.read(currentUserIdProvider) != uid) {
        throw StateError('Account changed. Try again.');
      }
      final next = change(current);
      await storage.write(uid, 'book', key, next.toJson());
      if (ref.read(currentUserIdProvider) == uid) state = AsyncData(next);
    });
    _pending = op.catchError((Object _) {});
    return op;
  }

  Future<void> profile(
          {required String season,
          required String depth,
          required String undertone}) =>
      mutate((b) => BeautyBook(
          season: season, depth: depth, undertone: undertone, notes: b.notes));
  Future<void> note(WearNote note, {WearNote? replaces}) => mutate((b) =>
      BeautyBook(
          season: b.season,
          depth: b.depth,
          undertone: b.undertone,
          notes: [
            ...b.notes.where((n) =>
                !(n.productKey == note.productKey && n.shade == note.shade) &&
                !(replaces != null &&
                    n.productKey == replaces.productKey &&
                    n.shade == replaces.shade)),
            note
          ]));
  Future<void> importAccount(
          List<OwnedProduct> owned, List<ProductFeedback> feedback) =>
      mutate((b) {
        final imported = <String, WearNote>{};
        for (final item in owned) {
          final p = item.product;
          if (p == null) continue;
          final f = feedback.where((f) => f.productId == p.id).firstOrNull;
          final n = WearNote(
              productKey: BundledCatalog.key(p),
              shade: isSkincare(p.category) ? '' : item.shadeName ?? '',
              fit: !isSkincare(p.category) &&
                      (f?.shadeNotes.contains('great_match') ?? false)
                  ? 'Skin match'
                  : '',
              reaction: _reaction(f));
          imported['${n.productKey}|${n.shade}'] = n;
        }
        for (final f in feedback) {
          if (f.product == null ||
              owned.any((o) => o.productId == f.productId)) {
            continue;
          }
          final n = WearNote(
              productKey: BundledCatalog.key(f.product!),
              reaction: _reaction(f));
          imported['${n.productKey}|'] = n;
        }
        // More specific notes written here take priority over older account logs.
        for (final n in b.notes) {
          imported['${n.productKey}|${n.shade}'] = n;
        }
        return BeautyBook(
            season: b.season,
            depth: b.depth,
            undertone: b.undertone,
            notes: imported.values.toList());
      });
  String _reaction(ProductFeedback? f) {
    if (f == null) return '';
    if (f.otherNewProducts && f.reaction == 'breakout') return 'Unsure';
    return const {
          'none': 'Tolerated',
          'breakout': 'Breakout',
          'irritation': 'Irritation'
        }[f.reaction] ??
        '';
  }

  Future<void> remove(WearNote note) => mutate((b) => BeautyBook(
      season: b.season,
      depth: b.depth,
      undertone: b.undertone,
      notes: b.notes
          .where((n) =>
              !(n.productKey == note.productKey && n.shade == note.shade))
          .toList()));
}
