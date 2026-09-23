import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../widgets/product_card.dart';

class RecommendationsScreen extends ConsumerWidget {
  const RecommendationsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(title: const Text('For you')),
        body: Center(
            child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ref.watch(forYouFeedProvider).when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(
                    child: TextButton(
                        onPressed: () => ref.invalidate(forYouFeedProvider),
                        child: const Text(
                            'Couldn’t load recommendations. Try again'))),
                data: (products) => products.isEmpty
                    ? Center(
                        child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('Start with what you already use.',
                                      style: TextStyle(
                                          fontFamily: 'MvseSerif',
                                          fontSize: 30)),
                                  const SizedBox(height: 12),
                                  const Text(
                                      'Add successful shades or a colour season to your shade book. Products appear here when there is enough information to suggest a shade.',
                                      textAlign: TextAlign.center),
                                  const SizedBox(height: 20),
                                  OutlinedButton(
                                      onPressed: () => context.push('/colour'),
                                      child: const Text('Open shade book')),
                                ])))
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: products.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => ProductCard(
                            product: products[i], showCompatibility: false)),
              ),
        )),
      );
}
