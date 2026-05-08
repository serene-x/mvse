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
    final searchAsync = ref.watch(searchProvider(SearchArgs(query: _query.text)));
    final canAddMore = st.ownedProducts.length < 10;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Add up to 10 products you own',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('${st.ownedProducts.length}/10 added · this fuels your shade twin matches.',
            style: const TextStyle(color: AppPalette.textMuted)),
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
              style: TextStyle(fontWeight: FontWeight.w600, color: AppPalette.textMuted, fontSize: 12, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              for (var i = 0; i < st.ownedProducts.length; i++)
                _OwnedChip(
                  product: st.ownedProducts[i],
                  onRemove: () => controller.removeOwned(i),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        if (_query.text.trim().isNotEmpty)
          Expanded(
            child: searchAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.redAccent)),
              data: (products) => products.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('No matches.', style: TextStyle(color: AppPalette.textMuted)),
                    )
                  : ListView.separated(
                      itemCount: products.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _SearchResultRow(
                        product: products[i],
                        canAdd: canAddMore,
                        onAdd: (shade) => controller.addOwned(
                          DraftOwnedProduct(product: products[i], shadeName: shade),
                        ),
                      ),
                    ),
            ),
          ),
      ],
    );
  }
}

class _OwnedChip extends StatelessWidget {
  final DraftOwnedProduct product;
  final VoidCallback onRemove;
  const _OwnedChip({required this.product, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('${product.product.brand} · ${product.product.name}'
          '${product.shadeName != null ? ' (${product.shadeName})' : ''}'),
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
    final shadesAsync = _shadesExpanded
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
                          fontSize: 11, color: AppPalette.textMuted,
                          letterSpacing: 0.6, fontWeight: FontWeight.w600,
                        )),
                    Text(widget.product.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(categoryLabel(widget.product.category),
                        style: const TextStyle(color: AppPalette.textMuted, fontSize: 12)),
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
          TextButton(
            onPressed: () => setState(() => _shadesExpanded = !_shadesExpanded),
            child: Text(_shade == null ? 'Pick a shade (optional)' : 'Shade: $_shade'),
          ),
          if (shadesAsync != null) shadesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(8),
              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
            data: (shades) => shades.isEmpty
                ? const Text('No shades on file.', style: TextStyle(color: AppPalette.textMuted, fontSize: 12))
                : Wrap(
                    spacing: 6, runSpacing: 6,
                    children: shades.map((s) {
                      final on = _shade == s.shadeName;
                      return ChoiceChip(
                        label: Text(s.shadeName),
                        avatar: s.hexColor == null
                            ? null
                            : CircleAvatar(backgroundColor: s.hexColor, radius: 8),
                        selected: on,
                        onSelected: (_) => setState(() => _shade = on ? null : s.shadeName),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

// Inline provider — only used here. Defined locally to avoid bloating
// providers.dart; data still comes from the repository layer.
final _productShadesProvider =
    FutureProvider.family<List<ProductShade>, String>((ref, id) {
  return ref.watch(productRepositoryProvider).fetchShades(id);
});
