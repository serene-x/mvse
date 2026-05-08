import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/models.dart';
import '../../providers/providers.dart';
import '../../theme.dart';
import '../../widgets/pill.dart';
import '../../widgets/shade_swatch.dart';
import '../../widgets/undertone_picker.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  // Anything that depends on profile/owned products gets nuked, so the next
  // For-You / shade-twins read pulls fresh data.
  void _invalidateAll(WidgetRef ref) {
    ref.invalidate(currentUserProfileProvider);
    ref.invalidate(ownedProductsProvider);
    ref.invalidate(forYouFeedProvider);
    ref.invalidate(shadeTwinsProvider);
    ref.invalidate(yourShadeProvider);
    ref.invalidate(twinRecommendationsProvider);
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
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.redAccent))),
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
                error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.redAccent)),
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
                              await ref.read(profileRepositoryProvider).removeOwnedProduct(
                                    userId: profile.id,
                                    productId: op.productId,
                                    shadeName: op.shadeName,
                                  );
                              _invalidateAll(ref);
                            },
                            onSaveShade: (newShade) async {
                              await ref.read(profileRepositoryProvider).updateOwnedProductShade(
                                    userId: profile.id,
                                    productId: op.productId,
                                    oldShadeName: op.shadeName,
                                    newShadeName: newShade,
                                  );
                              _invalidateAll(ref);
                            },
                          ),
                        ),
                    ],
                  );
                },
              ),
              Text('${ownedAsync.valueOrNull?.length ?? 0} / 10 — keep adding for sharper matches',
                  style: const TextStyle(color: AppPalette.textMuted, fontSize: 12)),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openAddSheet(BuildContext context, WidgetRef ref, String userId) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppPalette.warmWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
          _idx >= 0 ? 'Selected: ${kSkinToneScale[_idx].label}' : 'No tone set yet.',
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
  const _OwnedProductRow({
    required this.owned,
    required this.onRemove,
    required this.onSaveShade,
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
              if (widget.owned.hexColor != null)
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
                            fontSize: 11, color: AppPalette.textMuted,
                            letterSpacing: 0.6, fontWeight: FontWeight.w600,
                          )),
                    Text(p?.name ?? '(deleted product)',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (!_editing && widget.owned.shadeName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text('Shade: ${widget.owned.shadeName}',
                            style: const TextStyle(color: AppPalette.textMuted, fontSize: 12)),
                      ),
                  ],
                ),
              ),
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
                      content: Text('Remove ${p?.name ?? 'this product'} from your list?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(context, true),  child: const Text('Remove')),
                      ],
                    ),
                  );
                  if (ok == true) widget.onRemove();
                },
              ),
            ],
          ),
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
                            await widget.onSaveShade(newShade.isEmpty ? null : newShade);
                            if (mounted) setState(() { _editing = false; _saving = false; });
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

class _AddProductSheet extends ConsumerStatefulWidget {
  final String userId;
  final VoidCallback onAdded;
  const _AddProductSheet({required this.userId, required this.onAdded});

  @override
  ConsumerState<_AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends ConsumerState<_AddProductSheet> {
  final _query = TextEditingController();
  String? _picking;        // productId currently expanded for shade pick
  String? _pickedShade;
  String? _pickedHex;

  @override
  Widget build(BuildContext context) {
    final searchAsync = ref.watch(searchProvider(SearchArgs(query: _query.text)));

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add a product', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
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
              error: (e, _) => Text('$e', style: const TextStyle(color: Colors.redAccent)),
              data: (products) {
                if (_query.text.trim().isEmpty) {
                  return const Center(
                    child: Text('Search to find products to add.',
                        style: TextStyle(color: AppPalette.textMuted)),
                  );
                }
                if (products.isEmpty) {
                  return const Center(child: Text('No matches.', style: TextStyle(color: AppPalette.textMuted)));
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
                            ? '#${s.hexColor!.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}'
                            : null;
                      }),
                      onAdd: () async {
                        await ref.read(profileRepositoryProvider).addOwnedProduct(
                              userId: widget.userId,
                              productId: p.id,
                              shadeName: _pickedShade,
                              hexColor: _pickedHex,
                            );
                        widget.onAdded();
                        if (mounted) Navigator.of(context).pop();
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
                          fontSize: 11, color: AppPalette.textMuted,
                          letterSpacing: 0.6, fontWeight: FontWeight.w600,
                        )),
                    Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(categoryLabel(product.category),
                        style: const TextStyle(color: AppPalette.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              ElevatedButton(onPressed: onAdd, child: const Text('Add')),
            ],
          ),
          TextButton(
            onPressed: onToggle,
            child: Text(expanded
                ? 'Hide shades'
                : pickedShade != null ? 'Shade: $pickedShade' : 'Pick a shade (optional)'),
          ),
          if (expanded) _ShadeChips(productId: product.id, picked: pickedShade, onPick: onShadeChosen),
        ],
      ),
    );
  }
}

class _ShadeChips extends ConsumerWidget {
  final String productId;
  final String? picked;
  final ValueChanged<ProductShade> onPick;
  const _ShadeChips({required this.productId, required this.picked, required this.onPick});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_inlineShadesProvider(productId));
    return async.when(
      loading: () => const _Loader(),
      error: (e, _) => Text('$e', style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
      data: (shades) => shades.isEmpty
          ? const Text('No shades on file.', style: TextStyle(color: AppPalette.textMuted, fontSize: 12))
          : Wrap(
              spacing: 6, runSpacing: 6,
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

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: const TextStyle(
              fontSize: 12, color: AppPalette.textMuted,
              letterSpacing: 1.2, fontWeight: FontWeight.w700,
            )),
      );
}

class _Loader extends StatelessWidget {
  const _Loader();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
      );
}
