import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/routine.dart';
import '../../providers/providers.dart';
import '../../theme.dart';
import '../../widgets/evidence_labels.dart';

class RoutineScreen extends ConsumerWidget {
  const RoutineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(routinePlanProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Your routine')),
      body: planAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: Colors.redAccent))),
        data: (plan) {
          if (plan.am.isEmpty && plan.pm.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Add the products you use (in your profile) and we\'ll arrange them into an AM/PM routine and flag anything worth spacing out.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppPalette.textMuted, height: 1.5),
                ),
              ),
            );
          }

          final conflicts = plan.guidance
              .where((g) => g.kind == GuidanceKind.conflict)
              .toList();
          final synergies = plan.guidance
              .where((g) => g.kind == GuidanceKind.synergy)
              .toList();
          final coaching = plan.guidance
              .where((g) => g.kind == GuidanceKind.coaching)
              .toList();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const DataNote(
                icon: Icons.info_outline,
                text:
                    'A suggested order, not a rulebook. Skincare goes thinnest to thickest; the notes below are guidance with the reasoning shown.',
              ),
              const SizedBox(height: 20),
              _RoutineColumn(
                  title: 'Morning',
                  icon: Icons.wb_sunny_outlined,
                  slots: plan.am),
              const SizedBox(height: 24),
              _RoutineColumn(
                  title: 'Evening',
                  icon: Icons.nightlight_outlined,
                  slots: plan.pm),
              if (conflicts.isNotEmpty) ...[
                const SizedBox(height: 28),
                const _GuidanceHeader(
                    'Worth spacing out', Icons.alt_route, AppPalette.roseDeep),
                for (final g in conflicts) _GuidanceCard(g: g),
              ],
              if (synergies.isNotEmpty) ...[
                const SizedBox(height: 24),
                const _GuidanceHeader('Nice pairings', Icons.handshake_outlined,
                    AppPalette.positive),
                for (final g in synergies) _GuidanceCard(g: g),
              ],
              if (coaching.isNotEmpty) ...[
                const SizedBox(height: 24),
                const _GuidanceHeader(
                    'Ease in', Icons.spa_outlined, AppPalette.roseDeep),
                for (final g in coaching) _GuidanceCard(g: g),
              ],
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

class _RoutineColumn extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<RoutineSlot> slots;
  const _RoutineColumn(
      {required this.title, required this.icon, required this.slots});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 18, color: AppPalette.roseDeep),
            const SizedBox(width: 8),
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          if (slots.isEmpty)
            const Text('Nothing here yet.',
                style: TextStyle(color: AppPalette.textMuted, fontSize: 13))
          else
            for (var i = 0; i < slots.length; i++)
              _StepRow(index: i + 1, slot: slots[i]),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final int index;
  final RoutineSlot slot;
  const _StepRow({required this.index, required this.slot});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
                color: AppPalette.beige, shape: BoxShape.circle),
            child: Text('$index',
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(slot.stepLabel.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 10.5,
                        letterSpacing: 0.8,
                        color: AppPalette.textMuted,
                        fontWeight: FontWeight.w700)),
                Text(slot.product.name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuidanceHeader extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  const _GuidanceHeader(this.text, this.icon, this.color);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 8),
          Text(text,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: color)),
        ]),
      );
}

class _GuidanceCard extends StatelessWidget {
  final RoutineGuidance g;
  const _GuidanceCard({required this.g});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(g.title,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 6),
          Text(g.detail, style: const TextStyle(fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }
}
