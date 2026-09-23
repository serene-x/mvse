import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../../data/ingredient_guides.dart';
import '../../widgets/ingredient_guide_card.dart';
import '../../providers/providers.dart';
import '../../theme.dart';
import '../../widgets/claim_card.dart';
import '../../widgets/evidence_labels.dart';

class IngredientScreen extends ConsumerWidget {
  final String ingredientId;
  const IngredientScreen({super.key, required this.ingredientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(ingredientProvider(ingredientId));
    final claimsAsync = ref.watch(ingredientClaimsProvider(ingredientId));

    return Scaffold(
      appBar: AppBar(),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Couldn\'t load ingredient: $e',
              style: const TextStyle(color: Colors.redAccent)),
        ),
        data: (ing) {
          if (ing == null) {
            return const Center(child: Text('Ingredient not found.'));
          }
          final guide = guideForName(ing.inciName);
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(ing.displayName,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w700, height: 1.2)),
              if (ing.commonName != null && ing.commonName != ing.inciName) ...[
                const SizedBox(height: 3),
                Text('INCI: ${ing.inciName}',
                    style: const TextStyle(
                        fontSize: 12.5, color: AppPalette.textMuted)),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (ing.evidenceLevel != null)
                    EvidenceChip(level: ing.evidenceLevel!),
                  for (final f in ing.functions)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppPalette.beige,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(f,
                          style: const TextStyle(
                              fontSize: 11.5, fontWeight: FontWeight.w500)),
                    ),
                ],
              ),
              if (guide != null) IngredientGuideCard(guide: guide),
              if (guide == null && ing.simpleExplanation != null) ...[
                const SizedBox(height: 26),
                const _SectionHeader('In plain language'),
                Text(ing.simpleExplanation!, style: _body),
              ],
              if (ing.scienceExplanation != null ||
                  ing.evidenceSummary != null) ...[
                const SizedBox(height: 20),
                Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppPalette.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppPalette.stroke),
                    ),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      title: const Text('Go deeper: the science',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      children: [
                        if (ing.scienceExplanation != null)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(ing.scienceExplanation!, style: _body),
                          ),
                        if (ing.evidenceSummary != null) ...[
                          const SizedBox(height: 10),
                          DataNote(
                              text:
                                  'State of the evidence: ${ing.evidenceSummary!}',
                              icon: Icons.balance_outlined),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              if (guide == null && ing.pairsWell.isNotEmpty) ...[
                const SizedBox(height: 26),
                const _SectionHeader('Tends to work well with'),
                for (final p in ing.pairsWell)
                  _PairingTile(pairing: p, positive: true),
              ],
              if (guide == null && ing.pairsPoorly.isNotEmpty) ...[
                const SizedBox(height: 20),
                const _SectionHeader('Worth separating from'),
                for (final p in ing.pairsPoorly)
                  _PairingTile(pairing: p, positive: false),
              ],
              claimsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (claims) => claims.isEmpty
                    ? const SizedBox.shrink()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 26),
                          const _SectionHeader('Claims and evidence'),
                          for (var i = 0; i < claims.length; i++) ...[
                            if (i > 0) const SizedBox(height: 10),
                            ClaimCard(claim: claims[i]),
                          ],
                        ],
                      ),
              ),
              ..._flags(ing),
              const SizedBox(height: 26),
              const _SectionHeader('Sources'),
              if (ing.sources.isEmpty)
                const DataNote(
                  icon: Icons.menu_book_outlined,
                  text: 'Sources have not been added for this ingredient yet.',
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final s in ing.sources) SourceLink(source: s),
                    const SizedBox(height: 6),
                    const DataNote(
                      icon: Icons.menu_book_outlined,
                      text:
                          'These links go to peer-reviewed research or dermatology organizations, not marketing pages.',
                    ),
                  ],
                ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _flags(Ingredient ing) {
    final flags = <Widget>[];
    if (ing.pregnancyCaution || ing.pregnancyNote != null) {
      flags.add(DataNote(
        icon: Icons.family_restroom_outlined,
        text: ing.pregnancyNote ??
            'Commonly avoided during pregnancy or breastfeeding. check with your doctor.',
      ));
    }
    if (ing.isFragrance || ing.commonAllergen) {
      flags.add(const DataNote(
        icon: Icons.air_outlined,
        text:
            'A known sensitizer for some people. Most users are fine with it. your own experience is the best guide.',
      ));
    }
    if (ing.comedogenicRating != null) {
      flags.add(DataNote(
        icon: Icons.bubble_chart_outlined,
        text: ing.comedogenicNote ??
            'Flagged in older ingredient-level pore-clogging tests. This does not predict how a finished formula will behave on your skin.',
      ));
    }
    if (flags.isEmpty) return const [];
    return [
      const SizedBox(height: 26),
      const _SectionHeader('Worth knowing'),
      for (var i = 0; i < flags.length; i++) ...[
        if (i > 0) const SizedBox(height: 8),
        flags[i],
      ],
    ];
  }
}

const _body = TextStyle(fontSize: 14.5, height: 1.55, color: AppPalette.text);

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              color: AppPalette.textMuted,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            )),
      );
}

class _PairingTile extends StatelessWidget {
  final IngredientPairing pairing;
  final bool positive;
  const _PairingTile({required this.pairing, required this.positive});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            positive ? Icons.handshake_outlined : Icons.alt_route,
            size: 16,
            color: positive ? AppPalette.positive : AppPalette.roseDeep,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                    fontSize: 13, height: 1.45, color: AppPalette.text),
                children: [
                  TextSpan(
                      text: pairing.withIngredient,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (pairing.note != null) TextSpan(text: '. ${pairing.note}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
