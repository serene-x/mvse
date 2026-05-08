import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/models.dart';
import '../../providers/providers.dart';
import '../../theme.dart';
import '../../widgets/pill.dart';
import '../../widgets/product_card.dart';

class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});
  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  ProductCategory? _category;

  static const _filters = <(String, ProductCategory?)>[
    ('All', null),
    ('Foundation', ProductCategory.foundation),
    ('Blush', ProductCategory.blush),
    ('Lip', ProductCategory.lip),
    ('Skincare', ProductCategory.skincare),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('mvse',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22)),
        actions: [
          IconButton(
            onPressed: () => context.push('/search'),
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () => context.push('/twins'),
            icon: const Icon(Icons.favorite_outline),
          ),
          IconButton(
            onPressed: () => context.push('/profile'),
            icon: const Icon(Icons.person_outline),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabs,
            indicatorColor: AppPalette.rose,
            labelColor: AppPalette.text,
            unselectedLabelColor: AppPalette.textMuted,
            tabs: const [Tab(text: 'Trending'), Tab(text: 'For You')],
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final (label, cat) = _filters[i];
                return Pill(
                  label: label,
                  selected: _category == cat,
                  onTap: () => setState(() => _category = cat),
                );
              },
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _Feed(provider: discoveryFeedProvider(_category)),
                _Feed(provider: forYouFeedProvider, emptyHint: _forYouEmptyHint()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _forYouEmptyHint() => 'Add products in onboarding (or your profile) so we can find your shade twins.';
}

class _Feed extends ConsumerWidget {
  final ProviderListenable<AsyncValue<List<Product>>> provider;
  final String? emptyHint;
  const _Feed({required this.provider, this.emptyHint});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(provider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(24),
        child: Text('Couldn\'t load: $e', style: const TextStyle(color: Colors.redAccent)),
      ),
      data: (products) {
        if (products.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(emptyHint ?? 'Nothing here yet.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppPalette.textMuted)),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(provider),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => ProductCard(product: products[i]),
          ),
        );
      },
    );
  }
}
