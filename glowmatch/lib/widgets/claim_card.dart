import 'package:flutter/material.dart';
import 'buy_buttons.dart' as links;

import '../data/models/models.dart';
import '../theme.dart';
import 'evidence_labels.dart';

class ClaimCard extends StatelessWidget {
  final ProductClaim claim;
  const ClaimCard({super.key, required this.claim});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('“${claim.claim}”',
              style: const TextStyle(
                  fontSize: 13.5, fontStyle: FontStyle.italic, height: 1.4)),
          const SizedBox(height: 8),
          ClaimConfidenceChip(confidence: claim.confidence),
          const SizedBox(height: 8),
          Text(claim.reality,
              style: const TextStyle(
                  fontSize: 13, height: 1.5, color: AppPalette.text)),
          if (claim.sources.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final s in claim.sources) SourceLink(source: s),
          ],
        ],
      ),
    );
  }
}

class SourceLink extends StatelessWidget {
  final IngredientSource source;
  const SourceLink({super.key, required this.source});

  @override
  Widget build(BuildContext context) => links.SourceLink(
      url: source.url,
      label: source.publisher != null
          ? '${source.title} / ${source.publisher}'
          : source.title);
}
