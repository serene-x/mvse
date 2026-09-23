import 'package:flutter/material.dart';

import '../data/models/models.dart';
import '../theme.dart';

class EvidenceChip extends StatelessWidget {
  final EvidenceLevel level;
  const EvidenceChip({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (level) {
      EvidenceLevel.wellEstablished => (
          const Color(0xFFE8F0E6),
          const Color(0xFF4E6B4A)
        ),
      EvidenceLevel.promising => (AppPalette.beige, AppPalette.roseDeep),
      EvidenceLevel.limited => (AppPalette.beige, AppPalette.textMuted),
      EvidenceLevel.contested => (
          const Color(0xFFF6E7E0),
          const Color(0xFF9A6A50)
        ),
    };
    return _chip('${evidenceLevelLabel(level)} evidence', bg, fg);
  }
}

class ClaimConfidenceChip extends StatelessWidget {
  final ClaimConfidence confidence;
  const ClaimConfidenceChip({super.key, required this.confidence});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (confidence) {
      ClaimConfidence.wellSupported => (
          const Color(0xFFE8F0E6),
          const Color(0xFF4E6B4A)
        ),
      ClaimConfidence.mixed => (AppPalette.beige, AppPalette.roseDeep),
      ClaimConfidence.dependsOnFormula => (
          AppPalette.beige,
          AppPalette.roseDeep
        ),
      ClaimConfidence.contested => (
          const Color(0xFFF6E7E0),
          const Color(0xFF9A6A50)
        ),
      ClaimConfidence.unsupported => (
          const Color(0xFFF6E7E0),
          const Color(0xFF9A6A50)
        ),
    };
    return _chip(claimConfidenceLabel(confidence), bg, fg);
  }
}

Widget _chip(String label, Color bg, Color fg) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11.5, fontWeight: FontWeight.w600, color: fg)),
    );

class DataNote extends StatelessWidget {
  final String text;
  final IconData icon;
  const DataNote(
      {super.key, required this.text, this.icon = Icons.info_outline});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppPalette.textMuted),
        const SizedBox(width: 7),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  fontSize: 12.5, color: AppPalette.textMuted, height: 1.45)),
        ),
      ],
    );
  }
}
