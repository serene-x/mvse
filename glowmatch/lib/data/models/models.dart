// Plain DTOs. Repositories deserialize Supabase rows into these; the UI
// only ever talks to these types.

import 'package:flutter/material.dart';

enum ProductCategory { foundation, blush, lip, skincare, other }

ProductCategory categoryFromString(String? s) {
  switch (s) {
    case 'foundation': return ProductCategory.foundation;
    case 'blush':      return ProductCategory.blush;
    case 'lip':        return ProductCategory.lip;
    case 'skincare':   return ProductCategory.skincare;
    default:           return ProductCategory.other;
  }
}

String categoryLabel(ProductCategory c) {
  switch (c) {
    case ProductCategory.foundation: return 'Foundation';
    case ProductCategory.blush:      return 'Blush';
    case ProductCategory.lip:        return 'Lip';
    case ProductCategory.skincare:   return 'Skincare';
    case ProductCategory.other:      return 'Other';
  }
}

enum Undertone { warm, cool, neutral, olive }

Undertone? undertoneFromString(String? s) {
  switch (s) {
    case 'warm':    return Undertone.warm;
    case 'cool':    return Undertone.cool;
    case 'neutral': return Undertone.neutral;
    case 'olive':   return Undertone.olive;
    default:        return null;
  }
}

class UserProfile {
  final String id;
  final String? skinToneDesc;
  final Undertone? undertone;
  final bool onboardingComplete;

  const UserProfile({
    required this.id,
    this.skinToneDesc,
    this.undertone,
    required this.onboardingComplete,
  });

  factory UserProfile.fromMap(Map<String, dynamic> m) => UserProfile(
        id: m['id'] as String,
        skinToneDesc: m['skin_tone_desc'] as String?,
        undertone: undertoneFromString(m['undertone'] as String?),
        onboardingComplete: (m['onboarding_complete'] as bool?) ?? false,
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

  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    this.sephoraUrl,
    this.ultaUrl,
    this.mentionCount = 0,
  });

  factory Product.fromMap(Map<String, dynamic> m) => Product(
        id: m['id'] as String,
        name: m['name'] as String,
        brand: m['brand'] as String,
        category: categoryFromString(m['category'] as String?),
        sephoraUrl: m['sephora_url'] as String?,
        ultaUrl: m['ulta_url'] as String?,
        mentionCount: (m['mention_count'] as int?) ?? 0,
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

class OwnedProduct {
  final String userId;
  final String productId;
  final String? shadeName;
  final Color? hexColor;
  // joined product fields (optional, for list rendering)
  final Product? product;

  const OwnedProduct({
    required this.userId,
    required this.productId,
    this.shadeName,
    this.hexColor,
    this.product,
  });

  factory OwnedProduct.fromMap(Map<String, dynamic> m) => OwnedProduct(
        userId: m['user_id'] as String,
        productId: m['product_id'] as String,
        shadeName: m['shade_name'] as String?,
        hexColor: _parseHex(m['hex_color'] as String?),
        product: m['products'] is Map<String, dynamic>
            ? Product.fromMap(Map<String, dynamic>.from(m['products'] as Map))
            : null,
      );
}

class TikTokMention {
  final String id;
  final String productId;
  final String videoUrl;
  final List<String> sentimentTags;
  final int viewCount;
  final String? thumbnailUrl;
  final DateTime? createdAt;

  const TikTokMention({
    required this.id,
    required this.productId,
    required this.videoUrl,
    required this.sentimentTags,
    required this.viewCount,
    this.thumbnailUrl,
    this.createdAt,
  });

  factory TikTokMention.fromMap(Map<String, dynamic> m) {
    final st = m['sentiment_tags'];
    final tags = st is List ? st.whereType<String>().toList() : <String>[];
    return TikTokMention(
      id: m['id'] as String,
      productId: m['product_id'] as String,
      videoUrl: m['video_url'] as String,
      sentimentTags: tags,
      viewCount: (m['view_count'] as int?) ?? 0,
      thumbnailUrl: m['thumbnail_url'] as String?,
      createdAt: m['created_at'] != null ? DateTime.parse(m['created_at'] as String) : null,
    );
  }
}

class SentimentTag {
  final String tag;
  final int count;
  const SentimentTag({required this.tag, required this.count});
}

class ShadeTwinMatch {
  final String creatorId;
  final String tiktokHandle;
  final String? skinToneDesc;
  final int shared;
  final int total;
  final double similarity;

  const ShadeTwinMatch({
    required this.creatorId,
    required this.tiktokHandle,
    this.skinToneDesc,
    required this.shared,
    required this.total,
    required this.similarity,
  });

  factory ShadeTwinMatch.fromMap(Map<String, dynamic> m) => ShadeTwinMatch(
        creatorId: m['creator_id'] as String,
        tiktokHandle: m['tiktok_handle'] as String,
        skinToneDesc: m['skin_tone_desc'] as String?,
        shared: (m['shared'] as int?) ?? 0,
        total:  (m['total']  as int?) ?? 0,
        similarity: (m['similarity'] as num?)?.toDouble() ?? 0,
      );
}

class YourShade {
  final String shadeName;
  final Color? hexColor;
  final double score;
  const YourShade({required this.shadeName, this.hexColor, required this.score});

  factory YourShade.fromMap(Map<String, dynamic> m) => YourShade(
        shadeName: m['shade_name'] as String,
        hexColor: _parseHex(m['hex_color'] as String?),
        score: (m['score'] as num?)?.toDouble() ?? 0,
      );
}
