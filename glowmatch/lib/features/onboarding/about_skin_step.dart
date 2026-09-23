import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/skin_profile.dart';
import '../../theme.dart';
import 'onboarding_flow.dart';

class AboutSkinStep extends ConsumerWidget {
  const AboutSkinStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(onboardingProvider);
    final c = ref.read(onboardingProvider.notifier);

    return ListView(
      children: [
        const Text('A little about your skin',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        const Text(
          'All optional — pick what you know. Not sure? Take the shortcut below and we\'ll work it out from the products you add next.',
          style: TextStyle(color: AppPalette.textMuted, height: 1.4),
        ),
        const SizedBox(height: 16),

        // The "I don't know" escape hatch.
        _NotSureCard(
          selected: st.notSureAboutSkin,
          onTap: () => c.setNotSure(!st.notSureAboutSkin),
        ),

        if (!st.notSureAboutSkin) ...[
          const SizedBox(height: 22),
          const _GroupLabel('How does your skin usually behave?'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in SkinType.values)
                _SelectChip(
                  label: skinTypeLabel(t),
                  selected: st.skinType.contains(t),
                  onTap: () => c.toggleSkinType(t),
                ),
            ],
          ),
          const SizedBox(height: 22),
          const _GroupLabel('What would you like help with?'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final concern in SkinConcern.values)
                _SelectChip(
                  label: concernLabel(concern),
                  selected: st.concerns.contains(concern),
                  onTap: () => c.toggleConcern(concern),
                ),
            ],
          ),
        ],

        const SizedBox(height: 22),
        const _GroupLabel('What are you hoping for? (optional)'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final g in SkinGoal.values)
              _SelectChip(
                label: goalLabel(g),
                selected: st.goals.contains(g),
                onTap: () => c.toggleGoal(g),
              ),
          ],
        ),
        const SizedBox(height: 16),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lock_outline, size: 14, color: AppPalette.textMuted),
            SizedBox(width: 7),
            Expanded(
              child: Text(
                'You can change any of this later in your profile — nothing here is set in stone.',
                style: TextStyle(
                    fontSize: 12.5, color: AppPalette.textMuted, height: 1.4),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NotSureCard extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  const _NotSureCard({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppPalette.rose.withValues(alpha: 0.10)
              : AppPalette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppPalette.rose : AppPalette.stroke,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(selected ? Icons.check_circle : Icons.auto_awesome_outlined,
                color: selected ? AppPalette.rose : AppPalette.roseDeep),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('I\'m not sure — figure it out for me',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14.5)),
                  SizedBox(height: 3),
                  Text(
                    'We\'ll infer your skin type and concerns from the products you add next, and show you exactly why. Totally normal not to know.',
                    style: TextStyle(
                        fontSize: 12.5,
                        color: AppPalette.textMuted,
                        height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  final String text;
  const _GroupLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(text,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      );
}

class _SelectChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SelectChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppPalette.rose : AppPalette.beige,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Text(label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : AppPalette.text,
              )),
        ),
      ),
    );
  }
}
