import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/beauty_details.dart';
import '../../data/catalog.dart';
import '../../data/models/models.dart';
import '../../logic/shade_matching.dart';
import '../../providers/beauty_book.dart';
import '../../providers/providers.dart';
import '../../widgets/season_selector.dart';
import '../../theme.dart';

final seasonPicksProvider =
    FutureProvider<List<(Product, List<ShadePick>)>>((ref) async {
  final season = ref.watch(browseSeasonProvider);
  if (season == null) return [];
  final products = await ref.watch(discoveryFeedProvider(null).future);
  final details = await ref.watch(beautyDetailsProvider.future);
  return [
    for (final p in products)
      if ([
        ProductCategory.blush,
        ProductCategory.lip,
        ProductCategory.eyeshadow
      ].contains(p.category))
        (
          p,
          recommendShades(BundledCatalog.key(p), detailsFor(p, details),
              BeautyBook(season: season),
              complexion: false)
        )
  ].where((item) => item.$2.isNotEmpty).toList();
});

class SeasonBrowserScreen extends ConsumerWidget {
  const SeasonBrowserScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final season = ref.watch(browseSeasonProvider);
    return Scaffold(
        appBar: AppBar(title: const Text('MVSE / COLOUR EDIT')),
        body: Center(
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: ListView(padding: const EdgeInsets.all(24), children: [
                  Text('Find your palette.',
                      style: editorialTitle.copyWith(fontSize: 36)),
                  const SizedBox(height: 12),
                  const Text(
                      'Choose a season to explore lip, cheek and eye shades.'),
                  const SizedBox(height: 24),
                  const SeasonSelector(),
                  const SizedBox(height: 24),
                  if (season != null)
                    ref.watch(seasonPicksProvider).when(
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => TextButton(
                            onPressed: () =>
                                ref.invalidate(seasonPicksProvider),
                            child:
                                const Text('Could not load shades. Try again')),
                        data: (items) => items.isEmpty
                            ? const Text(
                                'No shades with enough colour information yet.')
                            : Column(children: [
                                for (final item in items)
                                  ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 8),
                                      title: Text(
                                          '${item.$1.brand} / ${item.$1.name}'),
                                      subtitle: Text(item.$2
                                          .map((p) => p.shade)
                                          .join(' · ')),
                                      trailing: const Icon(Icons.arrow_outward,
                                          size: 18),
                                      onTap: () => context
                                          .push('/product/${item.$1.id}')),
                              ])),
                  const SizedBox(height: 20),
                  if (ref.watch(currentUserIdProvider) == null)
                    Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                            onPressed: () => context.push('/auth/sign-up'),
                            child: const Text(
                                'Create an account for personal matches'))),
                ]))));
  }
}
