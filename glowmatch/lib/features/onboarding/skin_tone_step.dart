import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme.dart';
import '../../widgets/shade_swatch.dart';
import 'onboarding_flow.dart';

class SkinToneStep extends ConsumerStatefulWidget {
  const SkinToneStep({super.key});
  @override
  ConsumerState<SkinToneStep> createState() => _SkinToneStepState();
}

class _SkinToneStepState extends ConsumerState<SkinToneStep> {
  int? _idx;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pick your skin tone',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        const Text("Tap the swatch closest to your natural skin.",
            style: TextStyle(color: AppPalette.textMuted)),
        const SizedBox(height: 20),
        SkinToneScale(
          tones: kSkinToneScale.map((t) => t.color).toList(),
          selectedIndex: _idx ?? -1,
          onSelected: (i) {
            setState(() => _idx = i);
            final t = kSkinToneScale[i];
            ref.read(onboardingProvider.notifier).setSkinTone(t.label, t.hex);
          },
        ),
        const SizedBox(height: 18),
        if (_idx != null)
          Text('Selected: ${kSkinToneScale[_idx!].label}',
              style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }
}
