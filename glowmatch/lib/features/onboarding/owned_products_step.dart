import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../../providers/providers.dart';
import '../../theme.dart';
import 'onboarding_flow.dart';

class OwnedProductsStep extends ConsumerStatefulWidget {
  const OwnedProductsStep({super.key});
  @override
  ConsumerState<OwnedProductsStep> createState() => _OwnedProductsStepState();
}

class _OwnedProductsStepState extends ConsumerState<OwnedProductsStep> {
  final _query = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(onboardingProvider);
    final controller = ref.read(onboardingProvider.notifier);
    final searchAsync =
        ref.watch(searchProvider(SearchArgs(query: _query.text)));
    final canAddMore = st.ownedProducts.length < 10;

    final hint = st.notSureAboutSkin
        ? 'Tap each pick to say if you like it or if it reacted — that\'s how we\'ll work out your skin type and concerns.'
        : '${st.ownedProducts.length}/10 added · this fuels your shade twin matches. Tap a pick to log how it\'s working (optional).';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Add up to 10 products you use',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(hint,
            style: const TextStyle(color: AppPalette.textMuted, height: 1.4)),
        const SizedBox(height: 16),
        TextField(
          controller: _query,
          decoration: const InputDecoration(
            labelText: 'Search products',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        if (st.ownedProducts.isNotEmpty) ...[
          const Text('Your picks',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppPalette.textMuted,
                  fontSize: 12,
                  letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < st.ownedProducts.length; i++)
                _OwnedChip(
                  product: st.ownedProducts[i],
                  onRemove: () => controller.removeOwned(i),
                  onTap: () => _editFeedback(
                      context, controller, i, st.ownedProducts[i]),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (_query.text.trim().isNotEmpty)
          Expanded(
            child: searchAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e',
                  style: const TextStyle(color: Colors.redAccent)),
              data: (products) => products.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('No matches.',
                          style: TextStyle(color: AppPalette.textMuted)),
                    )
                  : ListView.separated(
                      itemCount: products.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _SearchResultRow(
                        product: products[i],
                        canAdd: canAddMore,
                        onAdd: (shade) => controller.addOwned(
                          DraftOwnedProduct(
                              product: products[i], shadeName: shade),
                        ),
                      ),
                    ),
            ),
          ),
      ],
    );
  }
}

// Quick-feedback sheet: like + reaction in a couple of taps.
Future<void> _editFeedback(
  BuildContext context,
  OnboardingController controller,
  int index,
  DraftOwnedProduct draft,
) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppPalette.warmWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _FeedbackSheet(
      draft: draft,
      onChanged: (updated) => controller.updateOwned(index, updated),
    ),
  );
}

class _FeedbackSheet extends StatefulWidget {
  final DraftOwnedProduct draft;
  final ValueChanged<DraftOwnedProduct> onChanged;
  const _FeedbackSheet({required this.draft, required this.onChanged});
  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet> {
  late String? _liked = widget.draft.liked;
  late String? _reaction = widget.draft.reaction;

  static const _likes = [
    ('yes', '👍 Like it'),
    ('meh', '😐 It\'s okay'),
    ('no', '👎 Not for me')
  ];
  static const _reactions = [
    ('none', 'No reaction'),
    ('breakout', 'Broke me out'),
    ('irritation', 'Irritated / stung'),
    ('dryness', 'Dried me out'),
    ('other', 'Something else'),
  ];

  void _emit() => widget
      .onChanged(widget.draft.copyWith(liked: _liked, reaction: _reaction));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.draft.product.name,
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          const Text('How do you feel about it?',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (v, label) in _likes)
                ChoiceChip(
                  label: Text(label),
                  selected: _liked == v,
                  onSelected: (_) {
                    setState(() => _liked = _liked == v ? null : v);
                    _emit();
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Did your skin react to it?',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (v, label) in _reactions)
                ChoiceChip(
                  label: Text(label),
                  selected: _reaction == v,
                  onSelected: (_) {
                    setState(() => _reaction = _reaction == v ? null : v);
                    _emit();
                  },
                ),
            ],
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnedChip extends StatelessWidget {
  final DraftOwnedProduct product;
  final VoidCallback onRemove;
  final VoidCallback onTap;
  const _OwnedChip(
      {required this.product, required this.onRemove, required this.onTap});

  String? get _badge {
    if (product.reaction != null && product.reaction != 'none') return '⚠️';
    if (product.liked == 'yes') return '👍';
    if (product.liked == 'no') return '👎';
    if (product.liked == 'meh') return '😐';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final badge = _badge;
    return InputChip(
      label: Text('${badge != null ? '$badge ' : ''}'
          '${product.product.brand} · ${product.product.name}'
          '${product.shadeName != null ? ' (${product.shadeName})' : ''}'),
      onPressed: onTap,
      onDeleted: onRemove,
      deleteIcon: const Icon(Icons.close, size: 16),
    );
  }
}

class _SearchResultRow extends ConsumerStatefulWidget {
  final Product product;
  final bool canAdd;
  final ValueChanged<String?> onAdd;
  const _SearchResultRow({
    required this.product,
    required this.canAdd,
    required this.onAdd,
  });
  @override
  ConsumerState<_SearchResultRow> createState() => _SearchResultRowState();
}

class _SearchResultRowState extends ConsumerState<_SearchResultRow> {
  String? _shade;
  bool _shadesExpanded = false;

  @override
  Widget build(BuildContext context) {
    final shadesAsync = !isSkincare(widget.product.category) && _shadesExpanded
        ? ref.watch(_productShadesProvider(widget.product.id))
        : null;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppPalette.stroke),
        borderRadius: BorderRadius.circular(14),
        color: AppPalette.surface,
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
                    Text(widget.product.brand.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppPalette.textMuted,
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w600,
                        )),
                    Text(widget.product.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(categoryLabel(widget.product.category),
                        style: const TextStyle(
                            color: AppPalette.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: widget.canAdd ? () => widget.onAdd(_shade) : null,
                child: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (!isSkincare(widget.product.category))
            TextButton(
              onPressed: () =>
                  setState(() => _shadesExpanded = !_shadesExpanded),
              child: Text(_shade == null
                  ? 'Pick a shade (optional)'
                  : 'Shade: $_shade'),
            ),
          if (shadesAsync != null)
            shadesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(8),
                child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (e, _) => Text('Error: $e',
                  style:
                      const TextStyle(color: Colors.redAccent, fontSize: 12)),
              data: (shades) => shades.isEmpty
                  ? const Text('No shades on file.',
                      style:
                          TextStyle(color: AppPalette.textMuted, fontSize: 12))
                  : Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: shades.map((s) {
                        final on = _shade == s.shadeName;
                        return ChoiceChip(
                          label: Text(s.shadeName),
                          avatar: s.hexColor == null
                              ? null
                              : CircleAvatar(
                                  backgroundColor: s.hexColor, radius: 8),
                          selected: on,
                          onSelected: (_) =>
                              setState(() => _shade = on ? null : s.shadeName),
                        );
                      }).toList(),
                    ),
            ),
        ],
      ),
    );
  }
}

final _productShadesProvider =
    FutureProvider.family<List<ProductShade>, String>((ref, id) {
  return ref.watch(productRepositoryProvider).fetchShades(id);
});
