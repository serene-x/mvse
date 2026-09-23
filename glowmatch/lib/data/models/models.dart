import 'package:flutter/material.dart';
import '../../logic/beauty_book.dart';

String? _plainCopy(dynamic value) => value is String
    ? value.replaceAll(' — ', '. ').replaceAll('—', ', ').replaceAll('–', '-')
    : null;

enum ProductCategory {
  // makeup
  foundation,
  concealer,
  blush,
  bronzer,
  highlighter,
  eyeshadow,
  eyeliner,
  mascara,
  brow,
  lip,
  settingProduct,
  // skincare
  cleanser,
  moisturizer,
  serum,
  sunscreen,
  toner,
  exfoliant,
  mask,
  eyeCream,
  faceOil,
  treatment,
  mist,
  // generic buckets
  skincare,
  other,
}

const _categoryStrings = <ProductCategory, String>{
  ProductCategory.foundation: 'foundation',
  ProductCategory.concealer: 'concealer',
  ProductCategory.blush: 'blush',
  ProductCategory.bronzer: 'bronzer',
  ProductCategory.highlighter: 'highlighter',
  ProductCategory.eyeshadow: 'eyeshadow',
  ProductCategory.eyeliner: 'eyeliner',
  ProductCategory.mascara: 'mascara',
  ProductCategory.brow: 'brow',
  ProductCategory.lip: 'lip',
  ProductCategory.settingProduct: 'setting_product',
  ProductCategory.cleanser: 'cleanser',
  ProductCategory.moisturizer: 'moisturizer',
  ProductCategory.serum: 'serum',
  ProductCategory.sunscreen: 'sunscreen',
  ProductCategory.toner: 'toner',
  ProductCategory.exfoliant: 'exfoliant',
  ProductCategory.mask: 'mask',
  ProductCategory.eyeCream: 'eye_cream',
  ProductCategory.faceOil: 'face_oil',
  ProductCategory.treatment: 'treatment',
  ProductCategory.mist: 'mist',
  ProductCategory.skincare: 'skincare',
  ProductCategory.other: 'other',
};

ProductCategory categoryFromString(String? s) {
  for (final e in _categoryStrings.entries) {
    if (e.value == s) return e.key;
  }
  return ProductCategory.other;
}

String categoryToString(ProductCategory c) => _categoryStrings[c]!;

String categoryLabel(ProductCategory c) {
  switch (c) {
    case ProductCategory.foundation:
      return 'Foundation';
    case ProductCategory.concealer:
      return 'Concealer';
    case ProductCategory.blush:
      return 'Blush';
    case ProductCategory.bronzer:
      return 'Bronzer';
    case ProductCategory.highlighter:
      return 'Highlighter';
    case ProductCategory.eyeshadow:
      return 'Eyeshadow';
    case ProductCategory.eyeliner:
      return 'Eyeliner';
    case ProductCategory.mascara:
      return 'Mascara';
    case ProductCategory.brow:
      return 'Brow';
    case ProductCategory.lip:
      return 'Lip';
    case ProductCategory.settingProduct:
      return 'Setting';
    case ProductCategory.cleanser:
      return 'Cleanser';
    case ProductCategory.moisturizer:
      return 'Moisturizer';
    case ProductCategory.serum:
      return 'Serum';
    case ProductCategory.sunscreen:
      return 'Sunscreen';
    case ProductCategory.toner:
      return 'Toner';
    case ProductCategory.exfoliant:
      return 'Exfoliant';
    case ProductCategory.mask:
      return 'Mask';
    case ProductCategory.eyeCream:
      return 'Eye cream';
    case ProductCategory.faceOil:
      return 'Face oil';
    case ProductCategory.treatment:
      return 'Treatment';
    case ProductCategory.mist:
      return 'Mist';
    case ProductCategory.skincare:
      return 'Skincare';
    case ProductCategory.other:
      return 'Other';
  }
}

/// Categories included by the Skincare filter.
const skincareCategories = <ProductCategory>{
  ProductCategory.cleanser,
  ProductCategory.moisturizer,
  ProductCategory.serum,
  ProductCategory.sunscreen,
  ProductCategory.toner,
  ProductCategory.exfoliant,
  ProductCategory.mask,
  ProductCategory.eyeCream,
  ProductCategory.faceOil,
  ProductCategory.treatment,
  ProductCategory.mist,
  ProductCategory.skincare,
};

bool isSkincare(ProductCategory c) => skincareCategories.contains(c);

enum Undertone { warm, cool, neutral, olive }

Undertone? undertoneFromString(String? s) {
  switch (s) {
    case 'warm':
      return Undertone.warm;
    case 'cool':
      return Undertone.cool;
    case 'neutral':
      return Undertone.neutral;
    case 'olive':
      return Undertone.olive;
    default:
      return null;
  }
}

class UserProfile {
  final String id;
  final String? skinToneDesc;
  final Undertone? undertone;
  final bool onboardingComplete;
  final List<String> skinType;
  final String? skinTypeSource; // 'stated' | 'inferred'
  final List<String> concerns;
  final String? concernsSource;
  final List<String> goals;
  final List<Map<String, dynamic>>
      sensitivities; // {label, ingredient_id?, source}
  final List<Map<String, dynamic>>
      inferenceNotes; // {field, value, reason, confidence}

  const UserProfile({
    required this.id,
    this.skinToneDesc,
    this.undertone,
    required this.onboardingComplete,
    this.skinType = const [],
    this.skinTypeSource,
    this.concerns = const [],
    this.concernsSource,
    this.goals = const [],
    this.sensitivities = const [],
    this.inferenceNotes = const [],
  });

  static List<String> _strList(dynamic v) =>
      v is List ? v.whereType<String>().toList() : const [];
  static List<Map<String, dynamic>> _mapList(dynamic v) => v is List
      ? v.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList()
      : const [];

  factory UserProfile.fromMap(Map<String, dynamic> m) => UserProfile(
        id: m['id'] as String,
        skinToneDesc: m['skin_tone_desc'] as String?,
        undertone: undertoneFromString(m['undertone'] as String?),
        onboardingComplete: (m['onboarding_complete'] as bool?) ?? false,
        skinType: _strList(m['skin_type']),
        skinTypeSource: m['skin_type_source'] as String?,
        concerns: _strList(m['concerns']),
        concernsSource: m['concerns_source'] as String?,
        goals: _strList(m['goals']),
        sensitivities: _mapList(m['sensitivities']),
        inferenceNotes: _mapList(m['inference_notes']),
      );
}

class Product {
  final String id;
  final String name;
  final String brand;
  final ProductCategory category;
  final String? sephoraUrl;
  final String? ultaUrl;
  final int mentionCount;
  // plain-language + makeup attributes
  final String? summary;
  final String? finish;
  final String? coverage;
  final String? howItWears;
  final String? skincareBenefits;
  // Catalogue provenance.
  final String? ingredientList;
  final String? ingredientListSource;
  final String? region;
  final String? dataNotes;
  final String dataSource;
  final int? defaultPaoMonths;
  // Missing photos use the product placeholder.
  final String? imageUrl;
  final String? imageSource;
  // Dated US retail price and package size.
  final double? priceUsd;
  final String? priceSource;
  final DateTime? priceAsOf;
  final double? sizeValue;
  final String? sizeUnit; // 'ml' | 'g'
  final String? sizeSource;

  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    this.sephoraUrl,
    this.ultaUrl,
    this.mentionCount = 0,
    this.summary,
    this.finish,
    this.coverage,
    this.howItWears,
    this.skincareBenefits,
    this.ingredientList,
    this.ingredientListSource,
    this.region,
    this.dataNotes,
    this.dataSource = 'seed',
    this.defaultPaoMonths,
    this.imageUrl,
    this.imageSource,
    this.priceUsd,
    this.priceSource,
    this.priceAsOf,
    this.sizeValue,
    this.sizeUnit,
    this.sizeSource,
  });

  factory Product.fromMap(Map<String, dynamic> m) => Product(
        id: m['id'] as String,
        name: m['name'] as String,
        brand: m['brand'] as String,
        category: categoryFromString(m['category'] as String?),
        sephoraUrl: m['sephora_url'] as String?,
        ultaUrl: m['ulta_url'] as String?,
        mentionCount: (m['mention_count'] as int?) ?? 0,
        summary: m['summary'] as String?,
        finish: m['finish'] as String?,
        coverage: m['coverage'] as String?,
        howItWears: m['how_it_wears'] as String?,
        skincareBenefits: m['skincare_benefits'] as String?,
        ingredientList: m['ingredient_list'] as String?,
        ingredientListSource: m['ingredient_list_source'] as String?,
        region: m['region'] as String?,
        dataNotes: m['data_notes'] as String?,
        dataSource: (m['data_source'] as String?) ?? 'seed',
        defaultPaoMonths: m['default_pao_months'] as int?,
        imageUrl: m['image_url'] as String?,
        imageSource: m['image_source'] as String?,
        priceUsd: asDoubleOrNull(m['price_usd']),
        priceSource: m['price_source'] as String?,
        priceAsOf: m['price_as_of'] == null
            ? null
            : DateTime.tryParse(m['price_as_of'] as String),
        sizeValue: asDoubleOrNull(m['size_value']),
        sizeUnit: m['size_unit'] as String?,
        sizeSource: m['size_source'] as String?,
      );
}

class ProductShade {
  final String id;
  final String productId;
  final String shadeName;
  final Color? hexColor;

  const ProductShade({
    required this.id,
    required this.productId,
    required this.shadeName,
    this.hexColor,
  });

  factory ProductShade.fromMap(Map<String, dynamic> m) => ProductShade(
        id: m['id'] as String,
        productId: m['product_id'] as String,
        shadeName: m['shade_name'] as String,
        hexColor: _parseHex(m['hex_color'] as String?),
      );
}

Color? _parseHex(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  final h = hex.replaceFirst('#', '');
  if (h.length != 6) return null;
  return Color(int.parse('FF$h', radix: 16));
}

/// Postgres `numeric` arrives from PostgREST as an int, double, or string
/// depending on value/driver: normalize to a nullable double.
double? asDoubleOrNull(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

class OwnedProduct {
  final String userId;
  final String productId;
  final String? shadeName;
  final Color? hexColor;
  final DateTime? openedAt;
  final int? paoMonths;
  // joined product fields (optional, for list rendering)
  final Product? product;

  const OwnedProduct({
    required this.userId,
    required this.productId,
    this.shadeName,
    this.hexColor,
    this.openedAt,
    this.paoMonths,
    this.product,
  });

  factory OwnedProduct.fromMap(Map<String, dynamic> m) => OwnedProduct(
        userId: m['user_id'] as String,
        productId: m['product_id'] as String,
        // '' in the DB means "no shade" (shade_name is part of the PK)
        shadeName: (m['shade_name'] as String?)?.isEmpty ?? true
            ? null
            : m['shade_name'] as String,
        hexColor: _parseHex(m['hex_color'] as String?),
        openedAt: m['opened_at'] != null
            ? DateTime.tryParse(m['opened_at'] as String)
            : null,
        paoMonths: m['pao_months'] as int?,
        product: m['products'] is Map<String, dynamic>
            ? Product.fromMap(Map<String, dynamic>.from(m['products'] as Map))
            : null,
      );
}

/// Evidence level for an ingredient, independent of the finished product.
enum EvidenceLevel { wellEstablished, promising, limited, contested }

EvidenceLevel? evidenceLevelFromString(String? s) {
  switch (s) {
    case 'well_established':
      return EvidenceLevel.wellEstablished;
    case 'promising':
      return EvidenceLevel.promising;
    case 'limited':
      return EvidenceLevel.limited;
    case 'contested':
      return EvidenceLevel.contested;
    default:
      return null;
  }
}

String evidenceLevelLabel(EvidenceLevel l) {
  switch (l) {
    case EvidenceLevel.wellEstablished:
      return 'Well-established';
    case EvidenceLevel.promising:
      return 'Promising';
    // NB: the chip appends the word 'evidence': labels must not include it.
    case EvidenceLevel.limited:
      return 'Limited';
    case EvidenceLevel.contested:
      return 'Contested';
  }
}

class IngredientPairing {
  final String withIngredient;
  final String? note;
  const IngredientPairing({required this.withIngredient, this.note});

  static List<IngredientPairing> listFromJson(dynamic json) {
    if (json is! List) return const [];
    return json
        .whereType<Map>()
        .map((m) => IngredientPairing(
              withIngredient: (m['with'] as String?) ?? '',
              note: m['note'] as String?,
            ))
        .where((p) => p.withIngredient.isNotEmpty)
        .toList();
  }
}

class IngredientSource {
  final String title;
  final String url;
  final String? publisher;
  const IngredientSource(
      {required this.title, required this.url, this.publisher});

  static List<IngredientSource> listFromJson(dynamic json) {
    if (json is! List) return const [];
    return json
        .whereType<Map>()
        .map((m) => IngredientSource(
              title: (m['title'] as String?) ?? '',
              url: (m['url'] as String?) ?? '',
              publisher: m['publisher'] as String?,
            ))
        .where((s) => s.url.isNotEmpty)
        .toList();
  }
}

class Ingredient {
  final String id;
  final String inciName;
  final String? commonName;
  final String? whatItDoes;
  final List<String> functions;
  final String? simpleExplanation;
  final String? scienceExplanation;
  final EvidenceLevel? evidenceLevel;
  final String? evidenceSummary;
  final bool isCellTurnoverActive;
  final String? activeFamily;
  final List<IngredientPairing> pairsWell;
  final List<IngredientPairing> pairsPoorly;
  final bool pregnancyCaution;
  final String? pregnancyNote;
  final bool isFragrance;
  final bool isEssentialOil;
  final bool commonAllergen;
  final int? comedogenicRating;
  final String? comedogenicNote;
  final List<IngredientSource> sources;
  final String dataSource;

  const Ingredient({
    required this.id,
    required this.inciName,
    this.commonName,
    this.whatItDoes,
    this.functions = const [],
    this.simpleExplanation,
    this.scienceExplanation,
    this.evidenceLevel,
    this.evidenceSummary,
    this.isCellTurnoverActive = false,
    this.activeFamily,
    this.pairsWell = const [],
    this.pairsPoorly = const [],
    this.pregnancyCaution = false,
    this.pregnancyNote,
    this.isFragrance = false,
    this.isEssentialOil = false,
    this.commonAllergen = false,
    this.comedogenicRating,
    this.comedogenicNote,
    this.sources = const [],
    this.dataSource = 'seed',
  });

  String get displayName => commonName ?? inciName;

  factory Ingredient.fromMap(Map<String, dynamic> m) => Ingredient(
        id: m['id'] as String,
        inciName: m['inci_name'] as String,
        commonName: m['common_name'] as String?,
        whatItDoes: ingredientRoles[(m['inci_name'] as String).toLowerCase()] ??
            _plainCopy(m['what_it_does']),
        functions: m['functions'] is List
            ? (m['functions'] as List).whereType<String>().toList()
            : const [],
        simpleExplanation:
            ingredientRoles[(m['inci_name'] as String).toLowerCase()] ??
                _plainCopy(m['simple_explanation']),
        scienceExplanation: _plainCopy(m['science_explanation']),
        evidenceLevel: evidenceLevelFromString(m['evidence_level'] as String?),
        evidenceSummary: _plainCopy(m['evidence_summary']),
        isCellTurnoverActive: (m['is_cell_turnover_active'] as bool?) ?? false,
        activeFamily: m['active_family'] as String?,
        pairsWell: IngredientPairing.listFromJson(m['pairs_well']),
        pairsPoorly: IngredientPairing.listFromJson(m['pairs_poorly']),
        pregnancyCaution: (m['pregnancy_caution'] as bool?) ?? false,
        pregnancyNote: m['pregnancy_note'] as String?,
        isFragrance: (m['is_fragrance'] as bool?) ?? false,
        isEssentialOil: (m['is_essential_oil'] as bool?) ?? false,
        commonAllergen: (m['common_allergen'] as bool?) ?? false,
        comedogenicRating: m['comedogenic_rating'] as int?,
        comedogenicNote: _plainCopy(m['comedogenic_note']),
        sources: IngredientSource.listFromJson(m['sources']),
        dataSource: (m['data_source'] as String?) ?? 'seed',
      );
}

class KeyIngredient {
  final String id;
  final String productId;
  final String ingredientId;
  final String? roleInProduct;
  final String? formNote;
  final double? concentrationPct; // null = brand does not disclose
  final String? concentrationSource;
  final int displayOrder;
  final Ingredient? ingredient; // joined row

  const KeyIngredient({
    required this.id,
    required this.productId,
    required this.ingredientId,
    this.roleInProduct,
    this.formNote,
    this.concentrationPct,
    this.concentrationSource,
    this.displayOrder = 0,
    this.ingredient,
  });

  factory KeyIngredient.fromMap(Map<String, dynamic> m) => KeyIngredient(
        id: m['id'] as String,
        productId: m['product_id'] as String,
        ingredientId: m['ingredient_id'] as String,
        roleInProduct: _plainCopy(m['role_in_product']),
        formNote: _plainCopy(m['form_note']),
        concentrationPct: (m['concentration_pct'] as num?)?.toDouble(),
        concentrationSource: m['concentration_source'] as String?,
        displayOrder: (m['display_order'] as int?) ?? 0,
        ingredient: m['ingredients'] is Map
            ? Ingredient.fromMap(
                Map<String, dynamic>.from(m['ingredients'] as Map))
            : null,
      );
}

enum ClaimConfidence {
  wellSupported,
  mixed,
  dependsOnFormula,
  contested,
  unsupported
}

ClaimConfidence claimConfidenceFromString(String? s) {
  switch (s) {
    case 'well_supported':
      return ClaimConfidence.wellSupported;
    case 'mixed':
      return ClaimConfidence.mixed;
    case 'depends_on_formula':
      return ClaimConfidence.dependsOnFormula;
    case 'contested':
      return ClaimConfidence.contested;
    default:
      return ClaimConfidence.unsupported;
  }
}

String claimConfidenceLabel(ClaimConfidence c) {
  switch (c) {
    case ClaimConfidence.wellSupported:
      return 'Well-supported';
    case ClaimConfidence.mixed:
      return 'Mixed evidence';
    case ClaimConfidence.dependsOnFormula:
      return 'Depends on the formula';
    case ClaimConfidence.contested:
      return 'Contested';
    case ClaimConfidence.unsupported:
      return 'Not supported by evidence';
  }
}

class ProductFeedback {
  final String id;
  final String userId;
  final String productId;
  final String? liked; // 'yes' | 'no' | 'meh'
  final bool? stillUsing;
  final Map<String, int> attributeRatings;
  final String?
      reaction; // 'none' | 'breakout' | 'irritation' | 'dryness' | 'other'
  final int? breakoutOnsetDays;
  final String? breakoutLocation;
  final String? breakoutType;
  final String? breakoutDuration;
  final List<String> irritationKind;
  final bool otherNewProducts;
  final List<String> contextFlags;
  final List<String> shadeNotes; // makeup shade observations (undertone signal)
  final String? note;
  final Product? product;

  const ProductFeedback({
    required this.id,
    required this.userId,
    required this.productId,
    this.liked,
    this.stillUsing,
    this.attributeRatings = const {},
    this.reaction,
    this.breakoutOnsetDays,
    this.breakoutLocation,
    this.breakoutType,
    this.breakoutDuration,
    this.irritationKind = const [],
    this.otherNewProducts = false,
    this.contextFlags = const [],
    this.shadeNotes = const [],
    this.note,
    this.product,
  });

  factory ProductFeedback.fromMap(Map<String, dynamic> m) => ProductFeedback(
        id: m['id'] as String,
        userId: m['user_id'] as String,
        productId: m['product_id'] as String,
        liked: m['liked'] as String?,
        stillUsing: m['still_using'] as bool?,
        attributeRatings: m['attribute_ratings'] is Map
            ? (m['attribute_ratings'] as Map).map(
                (k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0))
            : const {},
        reaction: m['reaction'] as String?,
        breakoutOnsetDays: m['breakout_onset_days'] as int?,
        breakoutLocation: m['breakout_location'] as String?,
        breakoutType: m['breakout_type'] as String?,
        breakoutDuration: m['breakout_duration'] as String?,
        irritationKind: m['irritation_kind'] is List
            ? (m['irritation_kind'] as List).whereType<String>().toList()
            : const [],
        otherNewProducts: (m['other_new_products'] as bool?) ?? false,
        contextFlags: m['context_flags'] is List
            ? (m['context_flags'] as List).whereType<String>().toList()
            : const [],
        shadeNotes: m['shade_notes'] is List
            ? (m['shade_notes'] as List).whereType<String>().toList()
            : const [],
        note: m['note'] as String?,
        product: m['products'] is Map
            ? Product.fromMap(Map<String, dynamic>.from(m['products'] as Map))
            : null,
      );
}

class ProductClaim {
  final String id;
  final String? productId;
  final String? ingredientId;
  final String claim;
  final String reality;
  final ClaimConfidence confidence;
  final List<IngredientSource> sources;

  const ProductClaim({
    required this.id,
    this.productId,
    this.ingredientId,
    required this.claim,
    required this.reality,
    required this.confidence,
    this.sources = const [],
  });

  factory ProductClaim.fromMap(Map<String, dynamic> m) => ProductClaim(
        id: m['id'] as String,
        productId: m['product_id'] as String?,
        ingredientId: m['ingredient_id'] as String?,
        claim: m['claim'] as String,
        reality: m['reality'] as String,
        confidence: claimConfidenceFromString(m['confidence'] as String?),
        sources: IngredientSource.listFromJson(m['sources']),
      );
}
