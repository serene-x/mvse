import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/catalog.dart';
import '../../data/models/models.dart';
import '../../logic/beauty_book.dart';
import '../../widgets/season_selector.dart';
import '../../providers/beauty_book.dart';
import '../../providers/providers.dart';
import '../../theme.dart';
import 'wear_note_sheet.dart';

class ColourScreen extends ConsumerWidget {
  const ColourScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(beautyBookProvider),
        products =
            ref.watch(discoveryFeedProvider(null)).valueOrNull ?? <Product>[];
    return Scaffold(
        appBar: AppBar(
            title: const Text('MVSE / SHADE BOOK',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1))),
        body: state.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) =>
                const Center(child: Text('Could not open your shade book.')),
            data: (book) {
              final guesses = seasonSuggestions(book.notes);
              return Center(
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: ListView(
                          padding: const EdgeInsets.all(24),
                          children: [
                            const Text('A record of what works.',
                                style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -1.5)),
                            const SizedBox(height: 14),
                            const Text(
                                'Keep your favourite shades and skin reactions in one place.',
                                style: TextStyle(height: 1.6)),
                            const SizedBox(height: 28),
                            Container(
                                color: AppPalette.beige,
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('YOUR COLOUR PROFILE',
                                          style: TextStyle(
                                              fontSize: 11,
                                              letterSpacing: 1.5,
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 16),
                                      Text(
                                          book.season.isEmpty
                                              ? 'Season not set'
                                              : book.season,
                                          style: const TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 8),
                                      Text([book.depth, book.undertone]
                                          .where((s) => s.isNotEmpty)
                                          .join(' / ')),
                                      const SizedBox(height: 12),
                                      OutlinedButton(
                                          onPressed: () => showDialog<void>(
                                              context: context,
                                              builder: (_) =>
                                                  _ProfileEditor(book: book)),
                                          child:
                                              const Text('Edit colour profile'))
                                    ])),
                            const SizedBox(height: 28),
                            const Text('A season to explore',
                                style: TextStyle(
                                    fontSize: 23, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 10),
                            Text(
                                guesses.isEmpty
                                    ? 'Log three flattering lip, cheek or eye shades with their colour families to explore a season.'
                                    : 'Your most-worn flattering colours lean toward ${guesses.join(' or ')}.',
                                style: const TextStyle(height: 1.6)),
                            const SizedBox(height: 8),
                            const Text(
                                'A suggestion based on your preferences. Your selected season takes priority.',
                                style: TextStyle(
                                    fontSize: 13,
                                    height: 1.6,
                                    color: AppPalette.textMuted)),
                            const SizedBox(height: 32),
                            Row(children: [
                              const Expanded(
                                  child: Text('Your wear notes',
                                      style: TextStyle(
                                          fontSize: 23,
                                          fontWeight: FontWeight.w600))),
                              TextButton.icon(
                                  onPressed: () => context.push('/search'),
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Add product'))
                            ]),
                            const Divider(),
                            if (ref.watch(currentUserIdProvider) != null)
                              Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton.icon(
                                      icon: const Icon(Icons.download_outlined,
                                          size: 18),
                                      label: const Text(
                                          'Use my account shelf & feedback'),
                                      onPressed: () async {
                                        try {
                                          final owned = await ref.read(
                                              ownedProductsProvider.future);
                                          final feedback = await ref.read(
                                              userFeedbackProvider.future);
                                          await ref
                                              .read(beautyBookProvider.notifier)
                                              .importAccount(owned, feedback);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                                    content: Text(
                                                        'Account records added.')));
                                          }
                                        } catch (_) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                                    content: Text(
                                                        'Could not load account records. Please try again.')));
                                          }
                                        }
                                      })),
                            if (book.notes.isEmpty)
                              const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Text(
                                      'Open a product and tap “Add wear note”.',
                                      style: TextStyle(height: 1.6))),
                            for (final n in book.notes.reversed)
                              Builder(builder: (context) {
                                final p = products
                                    .where((p) =>
                                        BundledCatalog.key(p) == n.productKey)
                                    .firstOrNull;
                                return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: Text(p?.name ??
                                              n.productKey.split('|').last),
                                          subtitle: Text(
                                              '${p?.brand ?? ''}${n.shade.isEmpty ? '' : ' / ${n.shade}'}\n${[
                                            n.fit,
                                            n.reaction,
                                            n.family
                                          ].where((s) => s.isNotEmpty).join(' · ')}'),
                                          isThreeLine: true,
                                          onTap: p == null
                                              ? null
                                              : () => context
                                                  .push('/product/${p.id}'),
                                          trailing: PopupMenuButton<String>(
                                              tooltip: 'Edit or remove note',
                                              onSelected: (v) async {
                                                if (v == 'edit' && p != null) {
                                                  await showWearNote(
                                                      context, ref, p, null,
                                                      note: n);
                                                } else if (v == 'remove') {
                                                  try {
                                                    await ref
                                                        .read(beautyBookProvider
                                                            .notifier)
                                                        .remove(n);
                                                  } catch (_) {
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                              const SnackBar(
                                                                  content: Text(
                                                                      'Could not remove this note.')));
                                                    }
                                                  }
                                                }
                                              },
                                              itemBuilder: (_) => [
                                                    if (p != null)
                                                      const PopupMenuItem(
                                                          value: 'edit',
                                                          child: Text(
                                                              'Edit note')),
                                                    const PopupMenuItem(
                                                        value: 'remove',
                                                        child:
                                                            Text('Remove note'))
                                                  ])),
                                      const Divider()
                                    ]);
                              }),
                            const SizedBox(height: 24),
                            const Text('Saved to your account.',
                                style: TextStyle(
                                    fontSize: 12, color: AppPalette.textMuted)),
                            const SizedBox(height: 24),
                          ])));
            }));
  }
}

class _ProfileEditor extends ConsumerStatefulWidget {
  final BeautyBook book;
  const _ProfileEditor({required this.book});
  @override
  ConsumerState<_ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends ConsumerState<_ProfileEditor> {
  late String season, depth, undertone;
  bool busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    season = widget.book.season;
    depth = widget.book.depth;
    undertone = widget.book.undertone;
  }

  Widget field(String label, String value, List<String> list,
          void Function(String) set) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: DropdownButtonFormField<String>(
              initialValue: list.contains(value) ? value : '',
              isExpanded: true,
              decoration: InputDecoration(labelText: label),
              items: [
                const DropdownMenuItem(
                    value: '', child: Text('Not sure / not set')),
                for (final s in list) DropdownMenuItem(value: s, child: Text(s))
              ],
              onChanged: (s) => set(s ?? '')));
  @override
  Widget build(BuildContext context) => AlertDialog(
          title: const Text('Your colour profile'),
          content: SizedBox(
              width: 430,
              child: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                field('Colour season', season, [...browseSeasons, ...seasons],
                    (s) => season = s),
                field(
                    'Complexion depth',
                    depth,
                    [
                      'Fair',
                      'Light',
                      'Light medium',
                      'Medium',
                      'Tan',
                      'Medium deep',
                      'Deep',
                      'Very deep'
                    ],
                    (s) => depth = s),
                field('Foundation undertone', undertone,
                    ['Cool', 'Neutral', 'Warm', 'Olive'], (s) => undertone = s),
                if (error != null) Text(error!),
              ]))),
          actions: [
            TextButton(
                onPressed: busy ? null : () => Navigator.pop(context),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: busy
                    ? null
                    : () async {
                        setState(() => busy = true);
                        try {
                          await ref.read(beautyBookProvider.notifier).profile(
                              season: season,
                              depth: depth,
                              undertone: undertone);
                          if (context.mounted) Navigator.pop(context);
                        } catch (_) {
                          setState(() {
                            busy = false;
                            error = 'Could not save. Please try again.';
                          });
                        }
                      },
                child: Text(busy ? 'Saving…' : 'Save profile'))
          ]);
}
