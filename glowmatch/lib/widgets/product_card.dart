import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models/models.dart';
import '../theme.dart';
import 'pill.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final String? yourShade;
  final Color? yourShadeColor;

  const ProductCard({
    super.key,
    required this.product,
    this.yourShade,
    this.yourShadeColor,
  });

  @override
  Widget build(BuildContext context) {
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
                      label: '${product.mentionCount} mentions',
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
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Pill(label: categoryLabel(product.category)),
                  const SizedBox(width: 6),
                  if (yourShade != null) _yourShadeChip(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      );
}
