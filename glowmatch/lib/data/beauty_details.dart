import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'catalog.dart';
import 'models/models.dart';

class BrandShade {
  final String name;
  const BrandShade({required this.name});
}

class BeautyDetails {
  final String url,
      ingredientSource,
      checked,
      ingredients,
      howToUse,
      formulaNote;
  final bool ingredientsComplete;
  final List<BrandShade> shades;
  final Map<String, String> shadeDescriptions;
  const BeautyDetails(
      {this.url = '',
      this.ingredientSource = '',
      this.checked = '',
      this.ingredients = '',
      this.howToUse = '',
      this.formulaNote = '',
      this.ingredientsComplete = true,
      this.shades = const [],
      this.shadeDescriptions = const {}});
  factory BeautyDetails.fromJson(Map<String, dynamic> j) => BeautyDetails(
      url: j['url'] ?? '',
      ingredientSource: j['ingredients_source'] ?? j['url'] ?? '',
      checked: j['checked'] ?? '',
      ingredients: j['ingredients'] ?? '',
      howToUse: j['how_to_use'] ?? '',
      formulaNote: j['formula_note'] ?? '',
      ingredientsComplete: j['ingredients_complete'] ?? true,
      shades: (j['shades'] as List? ?? [])
          .map((name) => BrandShade(name: name as String))
          .toList(),
      shadeDescriptions:
          Map<String, String>.from(j['shade_descriptions'] ?? {}));
  String description(String name) => shadeDescriptions[name] ?? '';
}

Future<Map<String, BeautyDetails>>? _details;
Future<Map<String, BeautyDetails>> loadBeautyDetails() =>
    _details ??= _loadDetails();
Future<Map<String, BeautyDetails>> _loadDetails() async {
  final j =
      jsonDecode(await rootBundle.loadString('assets/catalog/details.json'))
          as Map;
  final skincare = jsonDecode(
          await rootBundle.loadString('assets/catalog/skincare_formulas.json'))
      as Map;
  j.addAll(skincare);
  return j.map((k, v) => MapEntry(
      k as String, BeautyDetails.fromJson(Map<String, dynamic>.from(v))));
}

final beautyDetailsProvider =
    FutureProvider<Map<String, BeautyDetails>>((ref) => loadBeautyDetails());
BeautyDetails detailsFor(Product p, Map<String, BeautyDetails> data) =>
    data[BundledCatalog.key(p)] ??
    BeautyDetails(
        url: RegExp(r'Manufacturer:\s*(https://\S+)')
                .firstMatch(p.dataNotes ?? '')
                ?.group(1) ??
            '',
        ingredients: p.ingredientList ?? '');
