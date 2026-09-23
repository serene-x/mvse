import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/catalog.dart';
import '../data/models/models.dart';
import '../theme.dart';

Future<Map<String, String>>? _images;
Future<Map<String, String>> _loadImages() async {
  final manifest =
      jsonDecode(await rootBundle.loadString('assets/catalog/images.json'))
          as Map;
  final products = await BundledCatalog.load();
  return {
    for (final p in products)
      if (manifest[p.id] != null)
        BundledCatalog.key(p): manifest[p.id]['asset'] as String
  };
}

class ProductImage extends StatelessWidget {
  final Product product;
  final double size;
  final double radius;
  const ProductImage(
      {super.key, required this.product, this.size = 72, this.radius = 2});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(radius)),
        child: FutureBuilder<Map<String, String>>(
          future: _images ??= _loadImages(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return _placeholder();
            }
            final asset = snapshot.data?[BundledCatalog.key(product)];
            if (asset != null) {
              return Image.asset(asset,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => _placeholder());
            }
            if (product.imageUrl != null) {
              return Image.network(product.imageUrl!,
                  fit: BoxFit.contain,
                  webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                  errorBuilder: (_, __, ___) => _placeholder());
            }
            return _placeholder();
          },
        ),
      );

  Widget _placeholder() => ColoredBox(
        color: AppPalette.beige,
        child: Center(
            child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(product.brand,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: 'MvseSerif',
                            fontSize: size > 120 ? 22 : 12,
                            color: AppPalette.textMuted)),
                    if (size > 120) ...[
                      const SizedBox(height: 12),
                      const Text('PHOTO COMING SOON',
                          style: TextStyle(
                              fontSize: 9,
                              letterSpacing: 1,
                              color: AppPalette.textMuted)),
                    ],
                  ],
                ))),
      );
}
