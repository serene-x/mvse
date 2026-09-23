import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/models.dart';
import '../logic/personalization.dart';
import '../logic/pricing.dart';
import '../providers/providers.dart';
import '../theme.dart';
import 'compatibility_banner.dart';
import 'pill.dart';
import 'product_image.dart';

class ProductCard extends ConsumerWidget {
  final Product product;
  final String? yourShade;
  final Color? yourShadeColor;
  final bool showCompatibility;

  const ProductCard({
    super.key,
    required this.product,
    this.yourShade,
    this.yourShadeColor,
    this.showCompatibility = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push('/product/${product.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProductImage(product: product, size: 76),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                product.brand.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppPalette.textMuted,
                                  letterSpacing: 0.6,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (product.mentionCount > 0)
                              Pill(
                                label: product.mentionCount == 1
                                    ? '1 mention'
                                    : '${product.mentionCount} mentions',
                                icon: Icons.local_fire_department,
                                background: AppPalette.beige,
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        if (product.summary != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            product.summary!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12.5,
                                height: 1.4,
                                color: AppPalette.textMuted),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Pill(label: categoryLabel(product.category)),
                  const SizedBox(width: 6),
                  if (product.priceUsd != null) ...[
                    Pill(label: _priceSizeLabel()),
                    const SizedBox(width: 6),
                  ],
                  if (yourShade != null) _yourShadeChip(),
                ],
              ),
              if (showCompatibility) _compatibilityLine(ref),
            ],
          ),
        ),
      ),
    );
  }

  // Hide the compatibility line when there is no useful evidence.
  Widget _compatibilityLine(WidgetRef ref) {
    final async = ref.watch(productCompatibilityProvider(product.id));
    return async.maybeWhen(
      data: (result) {
        if (result.level == Compatibility.unknown) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: CompatibilityBanner(result: result, compact: true),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  // Compact "$16 · 30ml": size appended only when known.
  String _priceSizeLabel() {
    final price = formatPrice(product.priceUsd!);
    if (product.sizeValue != null && product.sizeUnit != null) {
      final v = product.sizeValue! == product.sizeValue!.roundToDouble()
          ? product.sizeValue!.toStringAsFixed(0)
          : product.sizeValue!.toStringAsFixed(1);
      return '$price · $v${product.sizeUnit}';
    }
    return price;
  }

  Widget _yourShadeChip() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppPalette.warmWhite,
          border: Border.all(color: AppPalette.stroke),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: yourShadeColor ?? AppPalette.beige,
                shape: BoxShape.circle,
                border: Border.all(color: AppPalette.stroke),
              ),
            ),
            const SizedBox(width: 6),
            Text(yourShade!,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      );
}
