import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme.dart';
import '../../widgets/undertone_picker.dart';
import 'onboarding_flow.dart';

class UndertoneStep extends ConsumerWidget {
  const UndertoneStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(onboardingProvider).undertone;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("What's your undertone?",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        const Text('A quick check: look at your inner-wrist veins in daylight.',
            style: TextStyle(color: AppPalette.textMuted)),
        const SizedBox(height: 20),
        UndertonePicker(
          selected: selected,
          onChanged: (u) => ref.read(onboardingProvider.notifier).setUndertone(u),
        ),
      ],
    );
  }
}
