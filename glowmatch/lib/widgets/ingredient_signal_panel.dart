import 'package:flutter/material.dart';
import '../logic/beauty_book.dart';
import '../logic/ingredient_signals.dart';

class IngredientSignalPanel extends StatelessWidget {
  final String formula, productKey;
  final List<WearNote> notes;
  final Map<String, String> formulas;
  final bool loggedIn, rinseOff, complete;
  const IngredientSignalPanel(
      {super.key,
      required this.formula,
      required this.productKey,
      required this.notes,
      required this.formulas,
      required this.loggedIn,
      required this.rinseOff,
      this.complete = true});

  @override
  Widget build(BuildContext context) {
    final signals = ingredientSignals(formula, loggedIn ? notes : [], formulas,
        excludeProduct: productKey);
    final known = signals.where((s) => s.historical).toList();
    final other = signals.where((s) => !s.historical).toList();
    final own = notes
        .where((n) => n.productKey == productKey)
        .map((n) => n.reaction)
        .toSet();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (loggedIn && own.contains('Breakout'))
        const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
                'You logged a breakout with this product. Ingredient overlaps below use other products.')),
      if (loggedIn && own.contains('Tolerated'))
        const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text('You logged this product as tolerated.')),
      const Text('Potential pore-clogging ingredients',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      const Text(
          'Not everything clogs pores for everyone. Formula, amount and your skin matter. More wear notes help narrow down possible triggers.',
          style: TextStyle(height: 1.5)),
      if (rinseOff)
        const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
                'This product rinses off. Brief contact differs from a leave-on formula.')),
      if (!complete)
        const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
                'The complete formula is not verified, so this check may miss ingredients.')),
      const SizedBox(height: 12),
      if (known.isEmpty)
        Text(formula.isEmpty
            ? 'A full ingredient list is needed to check this product.'
            : 'No matches in the current watch list. This does not guarantee a breakout-free product.'),
      for (final signal in known) _SignalRow(signal: signal),
      if (other.isNotEmpty) ...[
        const SizedBox(height: 20),
        const Text('Other overlaps in your notes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const Text(
            'These are shared ingredients, not established pore-cloggers.',
            style: TextStyle(height: 1.5)),
        for (final signal in other) _SignalRow(signal: signal),
      ],
    ]);
  }
}

class _SignalRow extends StatelessWidget {
  final IngredientSignal signal;
  const _SignalRow({required this.signal});
  @override
  Widget build(BuildContext context) {
    final color = switch (signal.level) {
      IngredientSignalLevel.watch => const Color(0xFF856600),
      IngredientSignalLevel.overlap ||
      IngredientSignalLevel.mixed =>
        const Color(0xFFAA4A00),
      IngredientSignalLevel.repeated => const Color(0xFFAA3030),
      IngredientSignalLevel.tolerated => const Color(0xFF286849),
    };
    return Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: color.withValues(alpha: .06),
            border: Border(left: BorderSide(color: color, width: 3))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(signal.ingredient,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(signal.label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 5),
          if (signal.level != IngredientSignalLevel.watch)
            Text(signal.detail, style: const TextStyle(height: 1.5)),
          if (signal.breakoutProducts.isNotEmpty ||
              signal.toleratedProducts.isNotEmpty)
            ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Products behind this label',
                    style: TextStyle(fontSize: 13)),
                children: [
                  for (final key in signal.breakoutProducts)
                    ListTile(
                        dense: true,
                        title: Text(key.replaceAll('|', ' / ')),
                        subtitle: const Text('Breakout')),
                  for (final key in signal.toleratedProducts)
                    ListTile(
                        dense: true,
                        title: Text(key.replaceAll('|', ' / ')),
                        subtitle: const Text('Tolerated')),
                ]),
        ]));
  }
}
