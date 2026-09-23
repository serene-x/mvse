import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/models/models.dart';
import '../logic/pricing.dart';
import '../theme.dart';
import 'product_image.dart';
import 'save_product_button.dart';

class CatalogProductTile extends StatelessWidget {
  final Product product;
  const CatalogProductTile({super.key, required this.product});
  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AspectRatio(
              aspectRatio: 1.08,
              child: Stack(children: [
                Positioned.fill(
                    child: Material(
                        color: Colors.white,
                        child: InkWell(
                          onTap: () => context.push('/product/${product.id}'),
                          child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Center(
                                child: ProductImage(
                                    product: product,
                                    size: constraints.maxWidth - 36),
                              )),
                        ))),
                Positioned(
                    top: 4,
                    right: 4,
                    child: SaveProductButton(product: product)),
              ])),
          const SizedBox(height: 14),
          Text(product.brand.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                  color: AppPalette.textMuted)),
          const SizedBox(height: 6),
          InkWell(
              onTap: () => context.push('/product/${product.id}'),
              child: Text(product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, height: 1.3))),
          const SizedBox(height: 8),
          Text(
              '${categoryLabel(product.category)}${product.priceUsd == null ? '' : '  ·  ${formatPrice(product.priceUsd!)} USD'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 12, color: AppPalette.textMuted)),
        ]);
      });
}
