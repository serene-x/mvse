import 'package:flutter/material.dart';

import '../logic/personalization.dart';
import '../theme.dart';

class CompatibilityBanner extends StatelessWidget {
  final CompatibilityResult result;
  final bool compact;
  const CompatibilityBanner(
      {super.key, required this.result, this.compact = false});

  @override
  Widget build(BuildContext context) {
    // Unknown with no message = nothing useful to show (e.g. signed out).
    if (result.level == Compatibility.unknown && result.message.isEmpty) {
      return const SizedBox.shrink();
    }

    final (bg, fg, icon) = switch (result.level) {
      Compatibility.compatible => (
          const Color(0xFFE8F0E6),
          const Color(0xFF4E6B4A),
          Icons.check_circle_outline
        ),
      Compatibility.caution => (
          AppPalette.beige,
          AppPalette.roseDeep,
          Icons.info_outline
        ),
      Compatibility.trigger => (
          const Color(0xFFF6E7E0),
          const Color(0xFF9A6A50),
          Icons.warning_amber_rounded
        ),
      Compatibility.unknown => (
          AppPalette.beige,
          AppPalette.textMuted,
          Icons.help_outline
        ),
    };

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 10 : 13),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(compact ? 10 : 13),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: compact ? 15 : 17, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              result.message,
              style: TextStyle(
                fontSize: compact ? 12 : 13,
                height: 1.45,
                color: fg,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
