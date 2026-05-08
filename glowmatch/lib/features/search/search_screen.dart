import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../../providers/providers.dart';
import '../../theme.dart';
import '../../widgets/pill.dart';
import '../../widgets/product_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _query = TextEditingController();
  ProductCategory? _category;
  bool _hasMyShade = false;

  static const _categories = <(String, ProductCategory?)>[
    ('All', null),
    ('Foundation', ProductCategory.foundation),
    ('Blush', ProductCategory.blush),
    ('Lip', ProductCategory.lip),
    ('Skincare', ProductCategory.skincare),
  ];

  @override
  Widget build(BuildContext context) {
    final args = SearchArgs(query: _query.text, category: _category, hasMyShade: _hasMyShade);
    final async = ref.watch(searchProvider(args));

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _query,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Search products & brands',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                if (i == _categories.length) {
                  return Pill(
                    label: 'Has my shade',
                    icon: Icons.check_circle_outline,
                    selected: _hasMyShade,
                    onTap: () => setState(() => _hasMyShade = !_hasMyShade),
                  );
                }
                final (label, cat) = _categories[i];
                return Pill(
                  label: label,
                  selected: _category == cat,
                  onTap: () => setState(() => _category = cat),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(24),
                child: Text('$e', style: const TextStyle(color: Colors.redAccent)),
              ),
              data: (products) {
                if (products.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No matches.',
                          style: TextStyle(color: AppPalette.textMuted)),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => ProductCard(product: products[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
