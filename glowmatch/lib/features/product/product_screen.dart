import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/catalog.dart';
import '../../data/models/models.dart';
import '../../data/beauty_details.dart';
import '../../data/ingredient_guides.dart';
import '../../widgets/ingredient_guide_card.dart';
import '../../widgets/ingredient_signal_panel.dart';
import '../../logic/beauty_book.dart';
import '../../logic/ingredient_identity.dart';
import '../../logic/shade_matching.dart';
import '../../providers/beauty_book.dart';
import '../../providers/shade_reports.dart';
import '../../providers/providers.dart';
import '../../theme.dart';
import '../../widgets/buy_buttons.dart';
import '../../widgets/shade_dropdown.dart';
import '../../widgets/season_selector.dart';
import '../../widgets/product_image.dart';
import '../../widgets/save_product_button.dart';
import '../colour/wear_note_sheet.dart';

class ProductScreen extends ConsumerStatefulWidget {
  final String productId;
  const ProductScreen({super.key, required this.productId});
  @override
  ConsumerState<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends ConsumerState<ProductScreen> {
  String? selected;
  @override
  void didUpdateWidget(covariant ProductScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.productId != widget.productId) selected = null;
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = ref.watch(currentUserIdProvider) != null;
    final browsingSeason = ref.watch(browseSeasonProvider);
    final product = ref.watch(productProvider(widget.productId));
    final metadata = ref.watch(beautyDetailsProvider);
    final book =
        ref.watch(beautyBookProvider).valueOrNull ?? const BeautyBook();
    return Scaffold(
        appBar: AppBar(
            title: const Text('MVSE / PRODUCT FILE',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1)),
            actions: [
              TextButton(
                  onPressed: () => context.push('/colour'),
                  child: const Text('Shade book'))
            ]),
        body: product.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(
                child: Text('Could not load this product. Try again.')),
            data: (p) {
              if (p == null) {
                return const Center(child: Text('Product not found.'));
              }
              final data = metadata.valueOrNull ?? <String, BeautyDetails>{};
              final detail = detailsFor(p, data);
              final shade =
                  detail.shades.where((s) => s.name == selected).firstOrNull;
              final key = BundledCatalog.key(p), formula = detail.ingredients;
              final hasShades =
                  !isSkincare(p.category) && detail.shades.isNotEmpty;
              final complexion = [
                ProductCategory.foundation,
                ProductCategory.concealer
              ].contains(p.category);
              final exploring = !complexion && browsingSeason != null;
              final picks = !hasShades
                  ? <ShadePick>[]
                  : recommendShades(key, detail,
                      exploring ? BeautyBook(season: browsingSeason) : book,
                      complexion: [
                        ProductCategory.foundation,
                        ProductCategory.concealer
                      ].contains(p.category),
                      catalog: data,
                      groups:
                          ref.watch(reviewedShadeReportsProvider).valueOrNull ??
                              communityGroups);
              final formulas = <String, String>{
                for (final e in data.entries) e.key: e.value.ingredients,
              };
              final tokens = formulaIngredients(formula);
              final legacyKeys =
                  ref.watch(keyIngredientsProvider(p.id)).valueOrNull ??
                      <KeyIngredient>[];
              final guides = guidesForIngredients(tokens);
              final guidedTokens = guides.expand((g) => g.inci).toSet();
              final roles = ingredientRoles.entries
                  .where((e) =>
                      tokens.contains(e.key) && !guidedTokens.contains(e.key))
                  .toList();
              final wide = MediaQuery.sizeOf(context).width > 800;
              final intro = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.brand.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 12,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Text(p.name,
                        style:
                            editorialTitle.copyWith(fontSize: wide ? 44 : 32)),
                    const SizedBox(height: 16),
                    Text(
                        '${categoryLabel(p.category)}${p.priceUsd == null ? '' : ' / US \$${p.priceUsd!.toStringAsFixed(0)}'}',
                        style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 12),
                    if (p.summary != null && p.summary!.length < 220)
                      Text(
                          p.summary!.replaceAll('—', '. ').replaceAll('–', ','),
                          style: const TextStyle(height: 1.6)),
                    const SizedBox(height: 20),
                    Wrap(
                        spacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          FilledButton.icon(
                              onPressed: () =>
                                  showWearNote(context, ref, p, shade),
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('Add wear note')),
                          SaveProductButton(product: p)
                        ]),
                    const SizedBox(height: 12),
                    BuyButtons(
                        brandUrl: detail.url,
                        sephoraUrl: p.sephoraUrl,
                        ultaUrl: p.ultaUrl,
                        searchTerm: '${p.brand} ${p.name}'),
                    const Text('Prices shown in USD.',
                        style: TextStyle(
                            fontSize: 11, color: AppPalette.textMuted)),
                  ]);
              return Center(
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: ListView(
                          padding: EdgeInsets.all(wide ? 36 : 20),
                          children: [
                            if (wide)
                              Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                        child: Center(
                                            child: ProductImage(
                                                product: p, size: 340))),
                                    const SizedBox(width: 48),
                                    Expanded(child: intro)
                                  ])
                            else ...[
                              Center(
                                  child: ProductImage(product: p, size: 240)),
                              const SizedBox(height: 24),
                              intro
                            ],
                            if (hasShades) ...[
                              section('01', 'Choose a shade'),
                              if (metadata.isLoading)
                                const LinearProgressIndicator(),
                              if (!metadata.isLoading && detail.shades.isEmpty)
                                const Text(
                                    'Add your shade name in a wear note.'),
                              if (detail.shades.isNotEmpty)
                                ShadeDropdown(
                                    value: selected,
                                    shades: detail.shades
                                        .map((s) => s.name)
                                        .toList(),
                                    onChanged: (v) =>
                                        setState(() => selected = v)),
                              section(
                                  '02',
                                  exploring || !loggedIn
                                      ? 'Explore shades'
                                      : 'Your shade shortlist'),
                              if (!complexion) ...[
                                const SeasonSelector(),
                                const SizedBox(height: 16),
                              ],
                              if (picks.isEmpty)
                                Text(
                                    exploring
                                        ? 'No shades with enough colour information for this season yet.'
                                        : !loggedIn
                                            ? (complexion
                                                ? 'Sign in to find matches from shades you wear.'
                                                : 'Choose a season to see shades to try.')
                                            : 'Add a shade you wear or choose a season for suggestions.',
                                    style: const TextStyle(height: 1.6)),
                              for (final pick in picks)
                                Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(20),
                                    decoration: const BoxDecoration(
                                        color: AppPalette.beige,
                                        border: Border(
                                            left: BorderSide(
                                                color: AppPalette.rose,
                                                width: 3))),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(pick.shade,
                                              style: const TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w600)),
                                          const SizedBox(height: 8),
                                          Text(pick.reason,
                                              style:
                                                  const TextStyle(height: 1.5)),
                                          if (pick.source.isNotEmpty)
                                            SourceLink(
                                                url: pick.source,
                                                label: 'Read the evidence'),
                                          if (detail.shades.any((s) =>
                                              shadeIdentity(s.name) ==
                                              shadeIdentity(pick.shade)))
                                            TextButton(
                                                onPressed: () => setState(() =>
                                                    selected = detail.shades
                                                        .firstWhere((s) =>
                                                            shadeIdentity(
                                                                s.name) ==
                                                            shadeIdentity(
                                                                pick.shade))
                                                        .name),
                                                child: const Text(
                                                    'Select this shade'))
                                        ])),
                              Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton(
                                      onPressed: () => context.push('/colour'),
                                      child: Text(loggedIn
                                          ? 'Edit your colour profile →'
                                          : 'Sign in for personal matches →'))),
                            ],
                            section(hasShades ? '03' : '01', 'Key ingredients'),
                            if (detail.howToUse.isNotEmpty) ...[
                              const Text('How to use this product',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              Text(detail.howToUse,
                                  style: const TextStyle(height: 1.6)),
                              const SizedBox(height: 18),
                            ],
                            if (guides.isNotEmpty) ...[
                              const Text(
                                  'Tap an ingredient for use and pairing tips. Product directions take priority.',
                                  style: TextStyle(fontSize: 12, height: 1.5)),
                              for (final guide in guides)
                                IngredientGuideCard(guide: guide),
                            ],
                            if (roles.isNotEmpty) ...[
                              for (final r in roles)
                                Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                              flex: 2,
                                              child: Text(
                                                  '${r.key[0].toUpperCase()}${r.key.substring(1)}',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600))),
                                          const SizedBox(width: 16),
                                          Expanded(
                                              flex: 3,
                                              child: Text(r.value,
                                                  style: const TextStyle(
                                                      height: 1.5)))
                                        ]))
                            ] else if (guides.isEmpty)
                              Text(formula.isEmpty
                                  ? 'Full ingredient list not added yet.'
                                  : 'See the full ingredient list below.'),
                            if (roles.isEmpty &&
                                guides.isEmpty &&
                                legacyKeys.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              for (final k in legacyKeys)
                                if (k.ingredient != null &&
                                    guideForName(k.ingredient!.inciName) !=
                                        null)
                                  IngredientGuideCard(
                                      guide:
                                          guideForName(k.ingredient!.inciName)!)
                                else if (k.ingredient != null)
                                  Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: Text(
                                          '${k.ingredient!.displayName}: ${ingredientRoles[k.ingredient!.inciName.toLowerCase()] ?? (k.ingredient!.whatItDoes ?? k.roleInProduct ?? "View the brand for details.").replaceAll("—", ". ").replaceAll("–", ", ")}',
                                          style: const TextStyle(height: 1.5))),
                              const Text('Selected ingredients.',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppPalette.textMuted)),
                            ],
                            if (formula.isNotEmpty)
                              ExpansionTile(
                                  tilePadding: EdgeInsets.zero,
                                  title: Text(detail.ingredientsComplete
                                      ? 'Full ingredient list'
                                      : 'Published ingredients / materials'),
                                  subtitle: detail.formulaNote.isEmpty
                                      ? null
                                      : Text(detail.formulaNote),
                                  children: [
                                    if (detail.ingredientSource.isNotEmpty)
                                      SourceLink(
                                          url: detail.ingredientSource,
                                          label:
                                              'Formula source${detail.checked.isEmpty ? '' : ' · checked ${detail.checked}'}'),
                                    const Text(
                                        'Formulas can change and differ by market. Compare with your packaging.',
                                        style: TextStyle(
                                            fontSize: 12, height: 1.5)),
                                    const SizedBox(height: 10),
                                    SelectableText(formula,
                                        style: const TextStyle(
                                            fontSize: 13, height: 1.6)),
                                    const SizedBox(height: 16)
                                  ]),
                            section(hasShades ? '04' : '02',
                                loggedIn ? 'Your skin' : 'Skin notes'),
                            IngredientSignalPanel(
                                formula: formula,
                                productKey: key,
                                notes: book.notes,
                                formulas: formulas,
                                loggedIn: loggedIn,
                                complete: detail.ingredientsComplete &&
                                    formula.isNotEmpty,
                                rinseOff:
                                    p.category == ProductCategory.cleanser ||
                                        p.name.contains('Peeling Solution')),
                            if (!loggedIn)
                              TextButton(
                                  onPressed: () =>
                                      context.push('/auth/sign-up'),
                                  child: const Text(
                                      'Create an account to track skin reactions')),
                            const SizedBox(height: 12),
                            const SizedBox(height: 30),
                          ])));
            }));
  }

  Widget section(String number, String title) => Padding(
      padding: const EdgeInsets.only(top: 32, bottom: 18),
      child: Column(children: [
        const Divider(),
        const SizedBox(height: 18),
        Row(children: [
          Text(number,
              style: const TextStyle(
                  color: AppPalette.rose,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
          const SizedBox(width: 16),
          Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -.5)))
        ])
      ]));
}
