import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/models.dart';
import '../../providers/providers.dart';
import '../../theme.dart';
import '../../widgets/buy_buttons.dart';
import '../../widgets/pill.dart';
import '../../widgets/shade_swatch.dart';

class ProductScreen extends ConsumerWidget {
  final String productId;
  const ProductScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productProvider(productId));
    final mentionsAsync = ref.watch(productMentionsProvider(productId));
    final sentimentsAsync = ref.watch(productSentimentsProvider(productId));
    final yourShadeAsync = ref.watch(yourShadeProvider(productId));

    return Scaffold(
      appBar: AppBar(),
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Couldn\'t load product: $e', style: const TextStyle(color: Colors.redAccent)),
        ),
        data: (product) {
          if (product == null) return const Center(child: Text('Product not found.'));
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(product.brand.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12, color: AppPalette.textMuted,
                    letterSpacing: 0.8, fontWeight: FontWeight.w600,
                  )),
              const SizedBox(height: 4),
              Text(product.name,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.2)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: [
                  Pill(label: categoryLabel(product.category)),
                  yourShadeAsync.when(
                    loading: () => const Pill(label: 'Finding your shade…'),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (s) => s == null
                        ? const Pill(label: 'Pick a shade in your shade twins')
                        : _YourShadePill(shade: s),
                  ),
                ],
              ),

              const SizedBox(height: 28),
              const _SectionHeader('TikTok consensus'),
              sentimentsAsync.when(
                loading: () => const _LoaderRow(),
                error: (_, __) => const SizedBox.shrink(),
                data: (tags) => tags.isEmpty
                    ? const Text('No sentiment yet.', style: TextStyle(color: AppPalette.textMuted))
                    : Wrap(
                        spacing: 8, runSpacing: 8,
                        children: tags
                            .map((t) => Pill(label: '${t.tag} · ${t.count}'))
                            .toList(),
                      ),
              ),

              const SizedBox(height: 24),
              const _SectionHeader('From TikTok'),
              mentionsAsync.when(
                loading: () => const _LoaderRow(),
                error: (_, __) => const SizedBox.shrink(),
                data: (mentions) => mentions.isEmpty
                    ? const Text('No mentions yet.', style: TextStyle(color: AppPalette.textMuted))
                    : SizedBox(
                        height: 200,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: mentions.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (_, i) => _TikTokThumbnail(mention: mentions[i]),
                        ),
                      ),
              ),

              const SizedBox(height: 28),
              BuyButtons(sephoraUrl: product.sephoraUrl, ultaUrl: product.ultaUrl),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: const TextStyle(
              fontSize: 12, color: AppPalette.textMuted,
              letterSpacing: 1.2, fontWeight: FontWeight.w700,
            )),
      );
}

class _LoaderRow extends StatelessWidget {
  const _LoaderRow();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
      );
}

class _YourShadePill extends StatelessWidget {
  final YourShade shade;
  const _YourShadePill({required this.shade});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        border: Border.all(color: AppPalette.rose, width: 1.5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShadeSwatch(color: shade.hexColor, size: 14),
          const SizedBox(width: 8),
          Text('Your shade: ${shade.shadeName}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
        ],
      ),
    );
  }
}

class _TikTokThumbnail extends StatelessWidget {
  final TikTokMention mention;
  const _TikTokThumbnail({required this.mention});

  Future<void> _open() async {
    final uri = Uri.tryParse(mention.videoUrl);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final hasThumb = mention.thumbnailUrl != null && mention.thumbnailUrl!.isNotEmpty;
    return GestureDetector(
      onTap: _open,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 130,
          decoration: BoxDecoration(
            color: AppPalette.beige,
            border: Border.all(color: AppPalette.stroke),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasThumb)
                CachedNetworkImage(
                  imageUrl: mention.thumbnailUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const _ThumbPlaceholder(),
                  errorWidget: (_, __, ___) => const _ThumbPlaceholder(),
                )
              else
                const _ThumbPlaceholder(),

              // Gradient + play icon overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(hasThumb ? 0.45 : 0),
                    ],
                  ),
                ),
              ),
              const Center(
                child: Icon(Icons.play_circle_fill, size: 44, color: Colors.white),
              ),
              Positioned(
                left: 8, right: 8, bottom: 8,
                child: Text(
                  '${(mention.viewCount / 1000).toStringAsFixed(1)}K views',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: hasThumb ? Colors.white : AppPalette.text,
                  ),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThumbPlaceholder extends StatelessWidget {
  const _ThumbPlaceholder();
  @override
  Widget build(BuildContext context) =>
      Container(color: AppPalette.beige);
}
