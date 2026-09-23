import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/models.dart';
import '../../logic/safety.dart';
import '../../logic/skin_profile.dart';
import '../../logic/undertone.dart';
import '../../providers/providers.dart';
import '../../theme.dart';
import '../../widgets/shade_swatch.dart';
import '../../widgets/undertone_picker.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  // Refresh account-dependent views after a profile change.
  void _invalidateAll(WidgetRef ref) {
    ref.invalidate(currentUserProfileProvider);
    ref.invalidate(ownedProductsProvider);
    ref.invalidate(forYouFeedProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final ownedAsync = ref.watch(ownedProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) context.go('/auth/sign-in');
            },
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: Colors.redAccent))),
        data: (profile) {
          if (profile == null) return const Center(child: Text('No profile.'));
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const _SectionHeader('Skin tone'),
              _SkinToneEditor(
                current: profile.skinToneDesc,
                onSave: (label, hex) async {
                  await ref.read(profileRepositoryProvider).updateProfile(
                        userId: profile.id,
                        skinToneDesc: label,
                      );
                  _invalidateAll(ref);
                },
              ),
              const SizedBox(height: 28),
              const _SectionHeader('Undertone'),
              UndertonePicker(
                selected: profile.undertone,
                onChanged: (u) async {
                  await ref.read(profileRepositoryProvider).updateProfile(
                        userId: profile.id,
                        undertone: u,
                      );
                  _invalidateAll(ref);
                },
              ),
              const SizedBox(height: 12),
              const _UndertoneInsight(),
              const _FinishInsight(),
              const SizedBox(height: 28),
              Row(
                children: [
                  const Expanded(child: _SectionHeader('Your skin')),
                  TextButton.icon(
                    onPressed: () => context.push('/skin-profile'),
                    icon: const Icon(Icons.science_outlined, size: 18),
                    label: const Text('Ingredient profile'),
                  ),
                ],
              ),
              _SkinProfileEditor(
                profile: profile,
                onSave: (
                    {skinType,
                    skinTypeSource,
                    concerns,
                    concernsSource,
                    goals}) async {
                  await ref.read(profileRepositoryProvider).updateProfile(
                        userId: profile.id,
                        skinType: skinType,
                        skinTypeSource: skinTypeSource,
                        concerns: concerns,
                        concernsSource: concernsSource,
                        goals: goals,
                      );
                  ref.invalidate(currentUserProfileProvider);
                },
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  const Expanded(child: _SectionHeader('Your products')),
                  TextButton.icon(
                    onPressed: () => _openAddSheet(context, ref, profile.id),
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ],
              ),
              ownedAsync.when(
                loading: () => const _Loader(),
                error: (e, _) => Text('Error: $e',
                    style: const TextStyle(color: Colors.redAccent)),
                data: (owned) {
                  if (owned.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'No products yet. Add some to power your shade twin matches.',
                        style: TextStyle(color: AppPalette.textMuted),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (final op in owned)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _OwnedProductRow(
                            owned: op,
                            onRemove: () async {
                              await ref
                                  .read(profileRepositoryProvider)
                                  .removeOwnedProduct(
                                    userId: profile.id,
                                    productId: op.productId,
                                    shadeName: op.shadeName,
                                  );
                              _invalidateAll(ref);
                            },
                            onSaveShade: (newShade) async {
                              await ref
                                  .read(profileRepositoryProvider)
                                  .updateOwnedProductShade(
                                    userId: profile.id,
                                    productId: op.productId,
                                    oldShadeName: op.shadeName,
                                    newShadeName: newShade,
                                  );
                              _invalidateAll(ref);
                            },
                            onMarkOpened: () async {
                              await ref
                                  .read(profileRepositoryProvider)
                                  .setOpened(
                                    userId: profile.id,
                                    productId: op.productId,
                                    shadeName: op.shadeName,
                                    openedAt: DateTime.now(),
                                    paoMonths: op.paoMonths ??
                                        op.product?.defaultPaoMonths,
                                  );
                              ref.invalidate(ownedProductsProvider);
                            },
                          ),
                        ),
                    ],
                  );
                },
              ),
              Text(
                  '${ownedAsync.valueOrNull?.length ?? 0} / 10 — keep adding for sharper matches',
                  style: const TextStyle(
                      color: AppPalette.textMuted, fontSize: 12)),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openAddSheet(
      BuildContext context, WidgetRef ref, String userId) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppPalette.warmWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: _AddProductSheet(
            userId: userId,
            onAdded: () => _invalidateAll(ref),
          ),
        ),
      ),
    );
  }
}

class _SkinToneEditor extends StatefulWidget {
  final String? current;
  final void Function(String label, String hex) onSave;
  const _SkinToneEditor({required this.current, required this.onSave});

  @override
  State<_SkinToneEditor> createState() => _SkinToneEditorState();
}

class _SkinToneEditorState extends State<_SkinToneEditor> {
  late int _idx = kSkinToneScale.indexWhere((t) => t.label == widget.current);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkinToneScale(
          tones: kSkinToneScale.map((t) => t.color).toList(),
          selectedIndex: _idx,
          onSelected: (i) {
            setState(() => _idx = i);
            final t = kSkinToneScale[i];
            widget.onSave(t.label, t.hex);
          },
        ),
        const SizedBox(height: 8),
        Text(
          _idx >= 0
              ? 'Selected: ${kSkinToneScale[_idx].label}'
              : 'No tone set yet.',
          style: const TextStyle(color: AppPalette.textMuted, fontSize: 12),
        ),
      ],
    );
  }
}

class _OwnedProductRow extends StatefulWidget {
  final OwnedProduct owned;
  final VoidCallback onRemove;
  final Future<void> Function(String? newShade) onSaveShade;
  final Future<void> Function() onMarkOpened;
  const _OwnedProductRow({
    required this.owned,
    required this.onRemove,
    required this.onSaveShade,
    required this.onMarkOpened,
  });

  @override
  State<_OwnedProductRow> createState() => _OwnedProductRowState();
}

class _OwnedProductRowState extends State<_OwnedProductRow> {
  bool _editing = false;
  bool _saving = false;
  late final _ctrl = TextEditingController(text: widget.owned.shadeName ?? '');

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.owned.product;
    return Container(
      decoration: BoxDecoration(
        color: AppPalette.surface,
        border: Border.all(color: AppPalette.stroke),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (p != null &&
                  !isSkincare(p.category) &&
                  widget.owned.hexColor != null)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ShadeSwatch(color: widget.owned.hexColor, size: 20),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (p != null)
                      Text(p.brand.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppPalette.textMuted,
                            letterSpacing: 0.6,
                            fontWeight: FontWeight.w600,
                          )),
                    Text(p?.name ?? '(deleted product)',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (p != null &&
                        !isSkincare(p.category) &&
                        !_editing &&
                        widget.owned.shadeName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text('Shade: ${widget.owned.shadeName}',
                            style: const TextStyle(
                                color: AppPalette.textMuted, fontSize: 12)),
                      ),
                  ],
                ),
              ),
              if (p != null && !isSkincare(p.category))
                IconButton(
                  tooltip: _editing ? 'Cancel' : 'Edit shade',
                  icon: Icon(_editing ? Icons.close : Icons.edit, size: 18),
                  onPressed: () => setState(() => _editing = !_editing),
                ),
              IconButton(
                tooltip: 'Remove',
                icon: const Icon(Icons.delete_outline, size: 18),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Remove product?'),
                      content: Text(
                          'Remove ${p?.name ?? 'this product'} from your list?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel')),
                        TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Remove')),
                      ],
                    ),
                  );
                  if (ok == true) widget.onRemove();
                },
              ),
            ],
          ),
          _PaoLine(owned: widget.owned, onMarkOpened: widget.onMarkOpened),
          if (_editing) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _ctrl,
              decoration: const InputDecoration(labelText: 'Shade name'),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: _saving
                      ? null
                      : () async {
                          setState(() => _saving = true);
                          try {
                            final newShade = _ctrl.text.trim();
                            await widget.onSaveShade(
                                newShade.isEmpty ? null : newShade);
                            if (mounted) {
                              setState(() {
                                _editing = false;
                                _saving = false;
                              });
                            }
                          } catch (_) {
                            if (mounted) setState(() => _saving = false);
                            rethrow;
                          }
                        },
                  child: Text(_saving ? 'Saving…' : 'Save'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PaoLine extends StatelessWidget {
  final OwnedProduct owned;
  final Future<void> Function() onMarkOpened;
  const _PaoLine({required this.owned, required this.onMarkOpened});

  @override
  Widget build(BuildContext context) {
    final status = paoStatus(
      openedAt: owned.openedAt,
      paoMonths: owned.paoMonths ?? owned.product?.defaultPaoMonths,
      now: DateTime.now(),
    );
    if (!status.tracked) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: onMarkOpened,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: const Icon(Icons.lock_clock_outlined, size: 15),
          label: const Text('Mark as opened', style: TextStyle(fontSize: 12)),
        ),
      );
    }
    final past = (status.monthsLeft ?? 0) < 0;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(past ? Icons.hourglass_bottom : Icons.check_circle_outline,
              size: 14,
              color: past ? AppPalette.roseDeep : AppPalette.positive),
          const SizedBox(width: 6),
          Expanded(
            child: Text(status.message,
                style: const TextStyle(
                    fontSize: 11.5, color: AppPalette.textMuted, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _AddProductSheet extends ConsumerStatefulWidget {
  final String userId;
  final VoidCallback onAdded;
  const _AddProductSheet({required this.userId, required this.onAdded});

  @override
  ConsumerState<_AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends ConsumerState<_AddProductSheet> {
  final _query = TextEditingController();
  String? _picking; // productId currently expanded for shade pick
  String? _pickedShade;
  String? _pickedHex;

  @override
  Widget build(BuildContext context) {
    final searchAsync =
        ref.watch(searchProvider(SearchArgs(query: _query.text)));

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add a product',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          TextField(
            controller: _query,
            autofocus: true,
            onChanged: (_) => setState(() => _picking = null),
            decoration: const InputDecoration(
              labelText: 'Search products & brands',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: searchAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Text('$e', style: const TextStyle(color: Colors.redAccent)),
              data: (products) {
                if (_query.text.trim().isEmpty) {
                  return const Center(
                    child: Text('Search to find products to add.',
                        style: TextStyle(color: AppPalette.textMuted)),
                  );
                }
                if (products.isEmpty) {
                  return const Center(
                      child: Text('No matches.',
                          style: TextStyle(color: AppPalette.textMuted)));
                }
                return ListView.separated(
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final p = products[i];
                    final isPicking = _picking == p.id;
                    return _AddRow(
                      product: p,
                      expanded: isPicking,
                      pickedShade: isPicking ? _pickedShade : null,
                      onToggle: () => setState(() {
                        _picking = isPicking ? null : p.id;
                        _pickedShade = null;
                        _pickedHex = null;
                      }),
                      onShadeChosen: (s) => setState(() {
                        _pickedShade = s.shadeName;
                        _pickedHex = s.hexColor != null
                            ? '#${s.hexColor!.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}'
                            : null;
                      }),
                      onAdd: () async {
                        await ref
                            .read(profileRepositoryProvider)
                            .addOwnedProduct(
                              userId: widget.userId,
                              productId: p.id,
                              shadeName: _pickedShade,
                              hexColor: _pickedHex,
                            );
                        widget.onAdded();
                        if (context.mounted) Navigator.of(context).pop();
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AddRow extends ConsumerWidget {
  final Product product;
  final bool expanded;
  final String? pickedShade;
  final VoidCallback onToggle;
  final ValueChanged<ProductShade> onShadeChosen;
  final VoidCallback onAdd;
  const _AddRow({
    required this.product,
    required this.expanded,
    required this.pickedShade,
    required this.onToggle,
    required this.onShadeChosen,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppPalette.surface,
        border: Border.all(color: AppPalette.stroke),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.brand.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppPalette.textMuted,
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w600,
                        )),
                    Text(product.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(categoryLabel(product.category),
                        style: const TextStyle(
                            color: AppPalette.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              ElevatedButton(onPressed: onAdd, child: const Text('Add')),
            ],
          ),
          if (!isSkincare(product.category))
            TextButton(
              onPressed: onToggle,
              child: Text(expanded
                  ? 'Hide shades'
                  : pickedShade != null
                      ? 'Shade: $pickedShade'
                      : 'Pick a shade (optional)'),
            ),
          if (!isSkincare(product.category) && expanded)
            _ShadeChips(
                productId: product.id,
                picked: pickedShade,
                onPick: onShadeChosen),
        ],
      ),
    );
  }
}

class _ShadeChips extends ConsumerWidget {
  final String productId;
  final String? picked;
  final ValueChanged<ProductShade> onPick;
  const _ShadeChips(
      {required this.productId, required this.picked, required this.onPick});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_inlineShadesProvider(productId));
    return async.when(
      loading: () => const _Loader(),
      error: (e, _) => Text('$e',
          style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
      data: (shades) => shades.isEmpty
          ? const Text('No shades on file.',
              style: TextStyle(color: AppPalette.textMuted, fontSize: 12))
          : Wrap(
              spacing: 6,
              runSpacing: 6,
              children: shades.map((s) {
                final on = picked == s.shadeName;
                return ChoiceChip(
                  label: Text(s.shadeName),
                  avatar: s.hexColor == null
                      ? null
                      : CircleAvatar(backgroundColor: s.hexColor, radius: 8),
                  selected: on,
                  onSelected: (_) => onPick(s),
                );
              }).toList(),
            ),
    );
  }
}

final _inlineShadesProvider =
    FutureProvider.family<List<ProductShade>, String>((ref, id) {
  return ref.watch(productRepositoryProvider).fetchShades(id);
});

class _UndertoneInsight extends ConsumerWidget {
  const _UndertoneInsight();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(undertoneInferenceProvider);
    return async.maybeWhen(
      data: (inf) {
        if (inf.lean == null) return const SizedBox.shrink();
        final leanWord = switch (inf.lean!) {
          UndertoneLean.warm => 'Warm',
          UndertoneLean.cool => 'Cool',
          UndertoneLean.neutral => 'Neutral',
          UndertoneLean.olive => 'Olive',
        };
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppPalette.rose.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppPalette.rose.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.palette_outlined,
                    size: 16, color: AppPalette.roseDeep),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                      'You seem to lean $leanWord · ${confidenceLabel(inf.confidence)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13.5)),
                ),
              ]),
              if (inf.season != null) ...[
                const SizedBox(height: 4),
                Text(inf.season!,
                    style: const TextStyle(
                        fontSize: 12.5, color: AppPalette.roseDeep)),
              ],
              const SizedBox(height: 6),
              Text(inf.reasoning,
                  style: const TextStyle(fontSize: 12.5, height: 1.45)),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _FinishInsight extends ConsumerWidget {
  const _FinishInsight();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(finishPreferenceProvider);
    return async.maybeWhen(
      data: (pref) {
        if (!pref.hasSignal || pref.recommendation == null) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.auto_awesome_outlined,
                  size: 15, color: AppPalette.textMuted),
              const SizedBox(width: 7),
              Expanded(
                child: Text(pref.recommendation!,
                    style: const TextStyle(
                        fontSize: 12.5,
                        color: AppPalette.textMuted,
                        height: 1.45)),
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

typedef _SkinSave = Future<void> Function({
  List<String>? skinType,
  String? skinTypeSource,
  List<String>? concerns,
  String? concernsSource,
  List<String>? goals,
});

// Editing a field changes its source from inferred to stated.
class _SkinProfileEditor extends StatelessWidget {
  final UserProfile profile;
  final _SkinSave onSave;
  const _SkinProfileEditor({required this.profile, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final skinTypes =
        profile.skinType.map(skinTypeFromKey).whereType<SkinType>().toSet();
    final concerns =
        profile.concerns.map(concernFromKey).whereType<SkinConcern>().toSet();
    final goals = profile.goals.map(goalFromKey).whereType<SkinGoal>().toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (profile.inferenceNotes.isNotEmpty) ...[
          _InferenceCard(notes: profile.inferenceNotes),
          const SizedBox(height: 16),
        ],
        _MiniLabel('Skin type', source: profile.skinTypeSource),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in SkinType.values)
              _EditChip(
                label: skinTypeLabel(t),
                selected: skinTypes.contains(t),
                onTap: () {
                  final next = {...skinTypes};
                  next.contains(t) ? next.remove(t) : next.add(t);
                  onSave(
                    skinType: next.map((e) => skinTypeKeys[e]!).toList(),
                    skinTypeSource: 'stated',
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: 18),
        _MiniLabel('Concerns', source: profile.concernsSource),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in SkinConcern.values)
              _EditChip(
                label: concernLabel(c),
                selected: concerns.contains(c),
                onTap: () {
                  final next = {...concerns};
                  next.contains(c) ? next.remove(c) : next.add(c);
                  onSave(
                    concerns: next.map((e) => concernKeys[e]!).toList(),
                    concernsSource: 'stated',
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: 18),
        const _MiniLabel('Goals'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final g in SkinGoal.values)
              _EditChip(
                label: goalLabel(g),
                selected: goals.contains(g),
                onTap: () {
                  final next = {...goals};
                  next.contains(g) ? next.remove(g) : next.add(g);
                  onSave(goals: next.map((e) => goalKeys[e]!).toList());
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _InferenceCard extends StatelessWidget {
  final List<Map<String, dynamic>> notes;
  const _InferenceCard({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.rose.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.rose.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_outlined,
                  size: 16, color: AppPalette.roseDeep),
              SizedBox(width: 7),
              Expanded(
                child: Text('What we worked out from your products',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'A starting guess, not a verdict — edit anything below and it becomes yours.',
            style: TextStyle(
                fontSize: 12, color: AppPalette.textMuted, height: 1.4),
          ),
          const SizedBox(height: 10),
          for (final n in notes)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  ',
                      style: TextStyle(color: AppPalette.roseDeep)),
                  Expanded(
                    child: Text(
                      '${n['reason'] ?? ''}'
                      '${_confSuffix(n['confidence'])}',
                      style: const TextStyle(fontSize: 12.5, height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _confSuffix(dynamic c) {
    final v = (c as num?)?.toDouble() ?? 0;
    if (v >= 0.55) return ' (fairly confident)';
    if (v >= 0.35) return ' (a guess worth checking)';
    return ' (low confidence)';
  }
}

class _MiniLabel extends StatelessWidget {
  final String text;
  final String? source;
  const _MiniLabel(this.text, {this.source});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Text(text,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            if (source == 'inferred') ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppPalette.beige,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text('we guessed this',
                    style: TextStyle(
                        fontSize: 10.5,
                        color: AppPalette.textMuted,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
      );
}

class _EditChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _EditChip(
      {required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppPalette.rose : AppPalette.beige,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          child: Text(label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : AppPalette.text,
              )),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: const TextStyle(
              fontSize: 12,
              color: AppPalette.textMuted,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            )),
      );
}

class _Loader extends StatelessWidget {
  const _Loader();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2)),
      );
}
