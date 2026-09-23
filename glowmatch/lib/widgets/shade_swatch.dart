import 'package:flutter/material.dart';
import '../theme.dart';

class SkinToneOption {
  final String label;
  final Color color;
  const SkinToneOption(this.label, this.color);

  String get hex =>
      '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
}

// Twelve display swatches for selecting approximate skin depth.
const kSkinToneScale = <SkinToneOption>[
  SkinToneOption('porcelain', Color(0xFFF6E1CE)),
  SkinToneOption('fair', Color(0xFFEFD0B6)),
  SkinToneOption('light', Color(0xFFE5BC9C)),
  SkinToneOption('light-medium', Color(0xFFD9A684)),
  SkinToneOption('medium', Color(0xFFC8916D)),
  SkinToneOption('medium-tan', Color(0xFFB57E58)),
  SkinToneOption('tan', Color(0xFF9B6745)),
  SkinToneOption('tan-deep', Color(0xFF845635)),
  SkinToneOption('deep', Color(0xFF6E4527)),
  SkinToneOption('deep-rich', Color(0xFF55351D)),
  SkinToneOption('rich', Color(0xFF3F2716)),
  SkinToneOption('deepest', Color(0xFF2C1A0F)),
];

class ShadeSwatch extends StatelessWidget {
  final Color? color;
  final double size;
  final bool selected;
  final VoidCallback? onTap;
  final String? semanticLabel;

  const ShadeSwatch({
    super.key,
    required this.color,
    this.size = 28,
    this.selected = false,
    this.onTap,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color ?? AppPalette.beige,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? AppPalette.roseDeep : AppPalette.stroke,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                        color: AppPalette.roseDeep.withValues(alpha: .15),
                        blurRadius: 8)
                  ]
                : null,
          ),
          child: color == null
              ? Icon(Icons.help_outline,
                  size: size * .5, color: AppPalette.textMuted)
              : null,
        ),
      ),
    );
  }
}

// Horizontal scale of swatches used for skin-tone selection during onboarding.
class SkinToneScale extends StatelessWidget {
  final List<Color> tones;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const SkinToneScale({
    super.key,
    required this.tones,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        scrollDirection: Axis.horizontal,
        itemCount: tones.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => Center(
          child: ShadeSwatch(
            color: tones[i],
            size: i == selectedIndex ? 64 : 48,
            selected: i == selectedIndex,
            onTap: () => onSelected(i),
            semanticLabel: 'Skin tone ${i + 1}',
          ),
        ),
      ),
    );
  }
}
