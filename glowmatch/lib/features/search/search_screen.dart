import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/models.dart';
import '../../providers/providers.dart';
import '../../theme.dart';
import '../../widgets/catalog_product_tile.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _query = TextEditingController();
  ProductCategory? _category;
  bool _hasMyShade = false;
  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = SearchArgs(
        query: _query.text, category: _category, hasMyShade: _hasMyShade);
    final results = ref.watch(searchProvider(args));
    return Scaffold(
      appBar: AppBar(
          title: const Text('Search the index',
              style: TextStyle(fontFamily: 'MvseSerif', fontSize: 24))),
      body: Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: Column(children: [
                Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: TextField(
                      controller: _query,
                      autofocus: true,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                          hintText: 'Search by product or brand',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _query.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear search',
                                  icon: const Icon(Icons.close),
                                  onPressed: () =>
                                      setState(() => _query.clear()))),
                    )),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(children: [
                      Expanded(
                          child: DropdownButtonFormField<ProductCategory?>(
                              key: ValueKey(_category),
                              initialValue: _category,
                              decoration:
                                  const InputDecoration(labelText: 'Category'),
                              items: [
                                const DropdownMenuItem<ProductCategory?>(
                                    value: null, child: Text('All categories')),
                                for (final cat in ProductCategory.values)
                                  DropdownMenuItem(
                                      value: cat,
                                      child: Text(categoryLabel(cat)))
                              ],
                              onChanged: (value) =>
                                  setState(() => _category = value))),
                      if (ref.watch(currentUserIdProvider) != null) ...[
                        const SizedBox(width: 16),
                        FilterChip(
                            label: const Text('My products'),
                            selected: _hasMyShade,
                            onSelected: (v) => setState(() => _hasMyShade = v)),
                      ],
                    ])),
                const SizedBox(height: 20),
                Expanded(
                    child: results.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => Center(
                      child: TextButton(
                          onPressed: () => ref.invalidate(searchProvider(args)),
                          child:
                              const Text('Search is unavailable. Try again'))),
                  data: (products) {
                    if (products.isEmpty) {
                      return Center(
                          child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('No matches yet.',
                                        style: editorialTitle.copyWith(
                                            fontSize: 32)),
                                    const SizedBox(height: 12),
                                    const Text(
                                        'Try a brand name, a shorter search, or another category.',
                                        textAlign: TextAlign.center),
                                    const SizedBox(height: 16),
                                    TextButton(
                                        onPressed: () => setState(() {
                                              _query.clear();
                                              _category = null;
                                              _hasMyShade = false;
                                            }),
                                        child: const Text('Clear all filters')),
                                  ])));
                    }
                    return LayoutBuilder(builder: (_, constraints) {
                      final cols = constraints.maxWidth > 1000
                          ? 4
                          : constraints.maxWidth > 700
                              ? 3
                              : 2;
                      final width =
                          (constraints.maxWidth - 40 - (cols - 1) * 20) / cols;
                      return CustomScrollView(slivers: [
                        SliverToBoxAdapter(
                            child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 0, 20, 18),
                                child: Text(
                                    '${products.length} ${products.length == 1 ? 'product' : 'products'}',
                                    style: const TextStyle(
                                        color: AppPalette.textMuted,
                                        fontSize: 12)))),
                        SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            sliver: SliverGrid(
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: cols,
                                        crossAxisSpacing: 20,
                                        mainAxisSpacing: 14,
                                        mainAxisExtent: width / 1.08 + 135),
                                delegate: SliverChildBuilderDelegate(
                                    (_, i) => CatalogProductTile(
                                        product: products[i]),
                                    childCount: products.length))),
                      ]);
                    });
                  },
                )),
              ]))),
    );
  }
}
