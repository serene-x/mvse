import 'package:flutter/material.dart';

import '../data/models/models.dart';
import '../theme.dart';

class UndertonePicker extends StatelessWidget {
  final Undertone? selected;
  final ValueChanged<Undertone> onChanged;
  const UndertonePicker(
      {super.key, required this.selected, required this.onChanged});

  static const _options = <_O>[
    _O('Warm', 'Yellow / golden / peach undertones', Undertone.warm,
        Color(0xFFE8B074)),
    _O('Cool', 'Pink / red / blue undertones', Undertone.cool,
        Color(0xFFD0A0BD)),
    _O('Neutral', 'A balanced mix', Undertone.neutral, Color(0xFFCFB7A4)),
    _O('Olive', 'Green-leaning, often with warmth', Undertone.olive,
        Color(0xFFA9A172)),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final opt in _options) ...[
          _UndertoneTile(
            opt: opt,
            selected: selected == opt.value,
            onTap: () => onChanged(opt.value),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _O {
  final String label;
  final String hint;
  final Undertone value;
  final Color color;
  const _O(this.label, this.hint, this.value, this.color);
}

class _UndertoneTile extends StatelessWidget {
  final _O opt;
  final bool selected;
  final VoidCallback onTap;
  const _UndertoneTile(
      {required this.opt, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppPalette.beige : AppPalette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: selected ? AppPalette.rose : AppPalette.stroke,
            width: selected ? 1.5 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: opt.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppPalette.stroke),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(opt.label,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(opt.hint,
                        style: const TextStyle(
                            color: AppPalette.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              if (selected) const Icon(Icons.check, color: AppPalette.rose),
            ],
          ),
        ),
      ),
    );
  }
}
