import 'dart:convert';
import 'package:flutter/services.dart';
import 'models/models.dart';

/// Checked-in catalog: browsing remains available without a network or account.
class BundledCatalog {
  static Future<List<Product>>? _products;
  static Future<List<Product>> load() => _products ??= _load();
  static Future<List<Product>> _load() async {
    final raw = await rootBundle.loadString('assets/catalog/products.json');
    return (jsonDecode(raw) as List)
        .map((row) => Product.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  static bool isLocal(String id) => id.startsWith('catalog-');
  static String key(Product p) =>
      '${p.brand.toLowerCase()}|${p.name.toLowerCase()}';
}
