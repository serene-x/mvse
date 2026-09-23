import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/catalog.dart';
import '../../data/models/models.dart';
import '../../providers/providers.dart';
import '../../providers/saved_products.dart';
import '../../theme.dart';
import '../../widgets/catalog_product_tile.dart';
import '../../providers/beauty_book.dart';

class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});
  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  ProductCategory? _category;
  bool _shelf = false;
  bool _underTwenty = false;
  String _sort = 'edit';
  static const categories = <ProductCategory?>[
    null,
    ProductCategory.foundation,
    ProductCategory.concealer,
    ProductCategory.blush,
    ProductCategory.lip,
    ProductCategory.skincare
  ];

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(discoveryFeedProvider(null));
    final saved = ref.watch(savedProductsProvider).valueOrNull ?? {};
    final wide = MediaQuery.sizeOf(context).width > 980;
    final inset = wide ? 40.0 : 20.0;
    return Scaffold(
      body: SafeArea(
          child: RefreshIndicator(
        onRefresh: () async {
          ref.read(productRepositoryProvider).refresh();
          ref.invalidate(discoveryFeedProvider);
          await ref.read(discoveryFeedProvider(null).future);
        },
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
              child: Container(
            decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppPalette.stroke))),
            child: Center(
                child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: inset, vertical: 14),
                  child: Row(children: [
                    Flexible(
                        flex: wide ? 0 : 1,
                        child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('mvse',
                                style: TextStyle(
                                    fontFamily: 'MvseSerif',
                                    fontSize: 38,
                                    letterSpacing: -3)))),
                    if (wide) ...[
                      const SizedBox(width: 28),
                      const Text('THE SHADE BOOK',
                          style: TextStyle(fontSize: 9, letterSpacing: 2))
                    ],
                    const Spacer(),
                    Flexible(
                        flex: wide ? 0 : 1,
                        child: TextButton(
                            style: TextButton.styleFrom(
                                minimumSize: const Size(0, 44),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8)),
                            onPressed: () => setState(() => _shelf = false),
                            child: Text('Discover',
                                style: TextStyle(
                                    fontWeight: !_shelf
                                        ? FontWeight.w700
                                        : FontWeight.w400)))),
                    Flexible(
                        flex: wide ? 0 : 1,
                        child: TextButton(
                            style: TextButton.styleFrom(
                                minimumSize: const Size(0, 44),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8)),
                            onPressed: () {
                              if (ref.read(currentUserIdProvider) == null) {
                                context.push('/auth/sign-in');
                              } else {
                                setState(() => _shelf = true);
                              }
                            },
                            child: Text(
                                'My shelf${saved.isEmpty || !wide ? '' : ' (${saved.length})'}',
                                style: TextStyle(
                                    fontWeight: _shelf
                                        ? FontWeight.w700
                                        : FontWeight.w400)))),
                    IconButton(
                        tooltip: 'Search products',
                        onPressed: () => context.push('/search'),
                        icon: const Icon(Icons.search, size: 22)),
                    const _AccountMenu(),
                  ])),
            )),
          )),
          SliverToBoxAdapter(
              child: Center(
                  child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Padding(
                padding: EdgeInsets.fromLTRB(inset, wide ? 48 : 28, inset, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_shelf)
                      _EditorialHero(
                          products: feed.valueOrNull ?? [], wide: wide)
                    else ...[
                      Text('Your beauty shelf.',
                          style: editorialTitle.copyWith(
                              fontSize: wide ? 56 : 38)),
                      const SizedBox(height: 12),
                      Text(
                          ref.watch(currentUserIdProvider) == null
                              ? 'Browse products. Sign in to save your favourites.'
                              : 'Saved to your account.',
                          style: const TextStyle(color: AppPalette.textMuted)),
                    ],
                    SizedBox(height: wide ? 44 : 30),
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                              child: Text(
                                  _shelf
                                      ? 'Saved products'
                                      : 'The product index',
                                  style: editorialTitle.copyWith(
                                      fontSize: wide ? 32 : 28,
                                      letterSpacing: -0.5))),
                          if (wide)
                            TextButton.icon(
                                onPressed: () => context.push('/twins'),
                                icon:
                                    const Icon(Icons.people_outline, size: 18),
                                label: const Text('Open shade book')),
                        ]),
                    const SizedBox(height: 20),
                    SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(children: [
                          for (final cat in categories)
                            Padding(
                                padding: const EdgeInsets.only(right: 22),
                                child: InkWell(
                                  onTap: () => setState(() => _category = cat),
                                  child: Container(
                                    padding: const EdgeInsets.only(
                                        bottom: 12, top: 10),
                                    decoration: BoxDecoration(
                                        border: Border(
                                            bottom: BorderSide(
                                                color: _category == cat
                                                    ? AppPalette.text
                                                    : Colors.transparent,
                                                width: 2))),
                                    child: Text(
                                        cat == null
                                            ? 'Everything'
                                            : categoryLabel(cat),
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: _category == cat
                                                ? AppPalette.text
                                                : AppPalette.textMuted,
                                            fontWeight: _category == cat
                                                ? FontWeight.w600
                                                : FontWeight.w400)),
                                  ),
                                )),
                          PopupMenuButton<ProductCategory>(
                            tooltip: 'All categories',
                            onSelected: (cat) =>
                                setState(() => _category = cat),
                            itemBuilder: (_) => [
                              for (final cat in ProductCategory.values
                                  .where((c) => c != ProductCategory.other))
                                PopupMenuItem(
                                    value: cat, child: Text(categoryLabel(cat)))
                            ],
                            child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(0, 10, 8, 12),
                                child: Text(
                                    _category != null &&
                                            !categories.contains(_category)
                                        ? '${categoryLabel(_category!)} ▾'
                                        : 'More ▾',
                                    style: const TextStyle(fontSize: 13))),
                          ),
                        ])),
                    const Divider(height: 1),
                  ],
                )),
          ))),
          ...feed.when(
            loading: () => [
              const SliverToBoxAdapter(
                  child: Padding(
                      padding: EdgeInsets.all(60),
                      child: Center(child: CircularProgressIndicator())))
            ],
            error: (_, __) => [
              SliverToBoxAdapter(
                  child: Center(
                      child: TextButton(
                          onPressed: () =>
                              ref.invalidate(discoveryFeedProvider),
                          child: const Text(
                              'Couldn’t load the catalog. Try again'))))
            ],
            data: (all) {
              final products = all
                  .where((p) =>
                      (!_shelf || saved.contains(BundledCatalog.key(p))) &&
                      (_category == null ||
                          (_category == ProductCategory.skincare
                              ? isSkincare(p.category)
                              : p.category == _category)) &&
                      (!_underTwenty ||
                          (p.priceUsd != null && p.priceUsd! < 20)))
                  .toList();
              if (_sort == 'name') {
                products.sort((a, b) => a.name.compareTo(b.name));
              }
              if (_sort == 'brand') {
                products.sort((a, b) => a.brand.compareTo(b.brand));
              }
              if (_sort == 'price') {
                products.sort((a, b) => (a.priceUsd ?? double.infinity)
                    .compareTo(b.priceUsd ?? double.infinity));
              }
              final maxWidth = (MediaQuery.sizeOf(context).width - inset * 2)
                  .clamp(0.0, 1200.0);
              final columns = wide ? (maxWidth > 980 ? 4 : 3) : 2;
              final tileWidth = (maxWidth - (columns - 1) * 20) / columns;
              final margin =
                  ((MediaQuery.sizeOf(context).width - maxWidth) / 2);
              return [
                SliverToBoxAdapter(
                    child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: margin, vertical: 18),
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            Text(
                                '${products.length} ${products.length == 1 ? 'product' : 'products'}',
                                style: const TextStyle(
                                    fontSize: 12, color: AppPalette.textMuted)),
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              FilterChip(
                                  label: const Text('Under \$20',
                                      style: TextStyle(fontSize: 12)),
                                  selected: _underTwenty,
                                  onSelected: (v) =>
                                      setState(() => _underTwenty = v)),
                              const SizedBox(width: 12),
                              DropdownButton<String>(
                                  value: _sort,
                                  underline: const SizedBox.shrink(),
                                  style: const TextStyle(
                                      fontSize: 12, color: AppPalette.text),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'edit',
                                        child: Text('Catalog order')),
                                    DropdownMenuItem(
                                        value: 'name',
                                        child: Text('Name: A–Z')),
                                    DropdownMenuItem(
                                        value: 'brand',
                                        child: Text('Brand: A–Z')),
                                    DropdownMenuItem(
                                        value: 'price',
                                        child: Text('Price: low to high'))
                                  ],
                                  onChanged: (v) => setState(() => _sort = v!)),
                            ]),
                          ],
                        ))),
                if (products.isEmpty)
                  SliverToBoxAdapter(
                      child: Padding(
                          padding: const EdgeInsets.all(48),
                          child: Column(children: [
                            Text(
                                _shelf && saved.isEmpty
                                    ? 'A shelf of your own.'
                                    : 'Nothing in this corner yet.',
                                style: editorialTitle.copyWith(fontSize: 30)),
                            const SizedBox(height: 12),
                            Text(
                                _shelf && saved.isEmpty
                                    ? 'Tap the bookmark on a product to keep it here.'
                                    : 'Try another category or remove the price filter.',
                                textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            OutlinedButton(
                                onPressed: () => setState(() {
                                      _category = null;
                                      _underTwenty = false;
                                      if (saved.isEmpty) _shelf = false;
                                    }),
                                child: const Text('Browse products')),
                          ]))),
                SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: margin),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisExtent: tileWidth / 1.08 + 135,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 14),
                      delegate: SliverChildBuilderDelegate(
                          (context, i) =>
                              CatalogProductTile(product: products[i]),
                          childCount: products.length),
                    )),
                SliverToBoxAdapter(
                    child: Padding(
                        padding: EdgeInsets.fromLTRB(margin, 24, margin, 36),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Divider(),
                              const SizedBox(height: 16),
                              Text(
                                  ref.watch(currentUserIdProvider) == null
                                      ? 'Browse products. Sign in to save your favourites.'
                                      : 'Saved to your account.',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppPalette.textMuted)),
                              const SizedBox(height: 6),
                              const Text(
                                  'Prices are recorded US retail prices, not live offers. Check the retailer for current pricing.',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppPalette.textMuted)),
                            ]))),
              ];
            },
          ),
        ]),
      )),
    );
  }
}

class _EditorialHero extends ConsumerWidget {
  final List<Product> products;
  final bool wide;
  const _EditorialHero({required this.products, required this.wide});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final book = ref.watch(beautyBookProvider).valueOrNull;
    final intro =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('MVSE / BEAUTY, ON RECORD',
          style: TextStyle(
              fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
      const SizedBox(height: 18),
      Text('Your shades,\nin one place.',
          style: editorialTitle.copyWith(
              fontSize: wide ? 62 : 42, letterSpacing: -2.5)),
      const SizedBox(height: 20),
      const Text(
          'Find your next match from the makeup you already wear.\nKeep track of what looks good and what your skin likes.',
          style: TextStyle(fontSize: 14, height: 1.7)),
      const SizedBox(height: 24),
      FilledButton.icon(
          onPressed: () => context.push('/colour'),
          label: const Text('Build your shade book'),
          icon: const Icon(Icons.arrow_forward, size: 18),
          iconAlignment: IconAlignment.end),
      const SizedBox(height: 8),
      TextButton(
          onPressed: () => context.push('/seasons'),
          child: const Text('Browse shades by season')),
    ]);
    final record = Container(
        color: AppPalette.rose,
        padding: const EdgeInsets.all(28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Expanded(
                child: Text('YOUR BEAUTY RECORD',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        letterSpacing: 1.5))),
            SizedBox(width: 12),
            Icon(Icons.bookmark_outline, color: Color(0xFFE0EB9F), size: 20)
          ]),
          const SizedBox(height: 28),
          Text(
              book?.season.isNotEmpty == true
                  ? book!.season
                  : 'Start with a shade\nyou know.',
              style: const TextStyle(
                  fontFamily: 'MvseSerif',
                  fontSize: 36,
                  height: 1.1,
                  color: Colors.white)),
          const SizedBox(height: 28),
          for (final item in [
            ('01', 'Known shade matches', '/colour'),
            ('02', 'Browse by season', '/seasons'),
            ('03', 'Skin & wear notes', '/colour')
          ]) ...[
            const Divider(color: Color(0xFF985669)),
            InkWell(
                onTap: () => context.push(item.$3),
                child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(children: [
                      Text(item.$1,
                          style: const TextStyle(
                              color: Color(0xFFE0EB9F), fontSize: 11)),
                      const SizedBox(width: 16),
                      Expanded(
                          child: Text(item.$2,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14))),
                      const Icon(Icons.arrow_outward,
                          color: Colors.white, size: 16)
                    ]))),
          ],
          const SizedBox(height: 12),
          Text(
              ref.watch(currentUserIdProvider) == null
                  ? 'Create an account for your own shade book.'
                  : '${book?.notes.length ?? 0} wear notes saved',
              style: const TextStyle(color: Color(0xFFE9CCD3), fontSize: 11)),
        ]));
    return wide
        ? Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(flex: 3, child: intro),
            const SizedBox(width: 64),
            Expanded(flex: 2, child: record)
          ])
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [intro, const SizedBox(height: 28), record]);
  }
}

class _AccountMenu extends ConsumerWidget {
  const _AccountMenu();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loggedIn = ref.watch(currentUserIdProvider) != null;
    return PopupMenuButton<String>(
        tooltip: loggedIn ? 'Your account' : 'Sign in or create account',
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Text(loggedIn ? 'Account' : 'Sign in')),
        onSelected: (path) async {
          if (path == 'sign-out') {
            await ref.read(authRepositoryProvider).signOut();
          } else if (context.mounted) {
            context.push(path);
          }
        },
        itemBuilder: (_) => [
              if (!loggedIn) ...[
                const PopupMenuItem(
                    value: '/auth/sign-in', child: Text('Sign in')),
                const PopupMenuItem(
                    value: '/auth/sign-up', child: Text('Create account')),
              ] else
                const PopupMenuItem(
                    value: '/profile', child: Text('Your profile')),
              const PopupMenuItem(
                  value: '/seasons', child: Text('Browse by season')),
              const PopupMenuItem(value: '/for-you', child: Text('For you')),
              const PopupMenuItem(value: '/colour', child: Text('Shade book')),
              const PopupMenuItem(
                  value: '/routine', child: Text('Your routine')),
              const PopupMenuItem(
                  value: '/ingredients', child: Text('Ingredient library')),
              if (loggedIn)
                const PopupMenuItem(value: 'sign-out', child: Text('Sign out')),
            ]);
  }
}
