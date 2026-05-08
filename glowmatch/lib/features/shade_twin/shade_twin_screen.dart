import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../../providers/providers.dart';
import '../../theme.dart';
import '../../widgets/pill.dart';
import '../../widgets/product_card.dart';

class ShadeTwinScreen extends ConsumerWidget {
  const ShadeTwinScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final twinsAsync = ref.watch(shadeTwinsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Your shade twins')),
      body: twinsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Couldn\'t load twins: $e', style: const TextStyle(color: Colors.redAccent)),
        ),
        data: (twins) {
          if (twins.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Add some products you own and we\'ll match you to creators with overlapping shades.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppPalette.textMuted),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: twins.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (_, i) => _TwinCard(twin: twins[i]),
          );
        },
      ),
    );
  }
}

class _TwinCard extends ConsumerWidget {
  final ShadeTwinMatch twin;
  const _TwinCard({required this.twin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recsAsync = ref.watch(twinRecommendationsProvider(twin.creatorId));

    return Container(
      decoration: BoxDecoration(
        color: AppPalette.surface,
        border: Border.all(color: AppPalette.stroke),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppPalette.beige,
                child: Text('@', style: const TextStyle(color: AppPalette.text)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('@${twin.tiktokHandle}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    if (twin.skinToneDesc != null)
                      Text(twin.skinToneDesc!,
                          style: const TextStyle(color: AppPalette.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              Pill(label: '${(twin.similarity * 100).toStringAsFixed(0)}% match'),
            ],
          ),
          const SizedBox(height: 12),
          Text('Tries on ${twin.shared} of your shades · ${twin.total} total tracked',
              style: const TextStyle(color: AppPalette.textMuted, fontSize: 12)),
          const SizedBox(height: 14),
          const Text('You might like',
              style: TextStyle(
                fontSize: 11, color: AppPalette.textMuted,
                letterSpacing: 1.0, fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 8),

          recsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(8),
              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
            data: (recs) => recs.isEmpty
                ? const Text('Nothing new from this twin.',
                    style: TextStyle(color: AppPalette.textMuted, fontSize: 12))
                : Column(
                    children: recs.take(4).map((p) => Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ProductCard(product: p),
                    )).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
