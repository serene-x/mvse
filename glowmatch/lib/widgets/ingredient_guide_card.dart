import 'package:flutter/material.dart';
import '../data/ingredient_guides.dart';
import 'buy_buttons.dart';

class IngredientGuideCard extends StatelessWidget {
  final IngredientGuide guide;
  const IngredientGuideCard({super.key, required this.guide});
  @override
  Widget build(BuildContext context) => ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 20),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          title: Text(guide.name,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(guide.benefit, style: const TextStyle(height: 1.5))),
          children: [
            for (final item in [
              ('How to use', guide.use),
              ('Pairs well with', guide.pairs),
              ('Use with care', guide.caution)
            ])
              Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.$1,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 5),
                        Text(item.$2, style: const TextStyle(height: 1.5)),
                      ])),
            const SizedBox(height: 8),
            SourceLink(url: guide.source, label: 'Guidance source'),
          ]);
}
