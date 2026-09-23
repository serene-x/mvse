import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mvse/data/beauty_details.dart';
import 'package:mvse/data/ingredient_guides.dart';
import 'package:mvse/logic/beauty_book.dart';
import 'package:mvse/logic/ingredient_identity.dart';
import 'package:mvse/logic/ingredient_signals.dart';
import 'package:mvse/widgets/ingredient_guide_card.dart';
import 'package:mvse/widgets/ingredient_signal_panel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('optional pigments and partial ingredient names are not matched', () {
    final ingredients = formulaIngredients(
        'Water, Cetyl Alcohol, Sodium Hyaluronate. May Contain: Mica');
    expect(ingredients, contains('cetyl alcohol'));
    expect(ingredients, isNot(contains('alcohol')));
    expect(ingredients, isNot(contains('mica')));
  });
  test(
      'INCI aliases, numeric names and active percentages are preserved correctly',
      () {
    expect(
        formulaIngredients(
            'Active ingredients: Titanium Dioxide (6%), Zinc Oxide 5%; Inactive ingredients: Water Aqua Eau, 1,2-Hexanediol, Octyl Palmitate, PEG-7 Trimethylolpropane Coconut Ether'),
        {
          'titanium dioxide',
          'zinc oxide',
          'water',
          '1,2-hexanediol',
          'ethylhexyl palmitate',
          'peg-7 trimethylolpropane coconut ether'
        });
    final signals = ingredientSignals(
        'Octyl Palmitate, Coconut Oil, PEG-7 Trimethylolpropane Coconut Ether, PEG-100 Stearate, Dimethicone',
        [],
        {});
    expect(signals.map((s) => s.ingredient),
        ['ethylhexyl palmitate', 'cocos nucifera (coconut) oil']);
    expect(
        signals.every((s) => s.level == IngredientSignalLevel.watch), isTrue);
  });
  test(
      'one overlap, repeated overlap, tolerated and mixed evidence stay distinct',
      () {
    const formulas = {
      'a': 'Cetyl Alcohol, Squalane',
      'b': 'Cetyl Alcohol',
      'c': 'Squalane, Tocopherol'
    };
    const notes = [
      WearNote(productKey: 'a', reaction: 'Breakout'),
      WearNote(productKey: 'b', reaction: 'Breakout'),
      WearNote(productKey: 'c', reaction: 'Tolerated')
    ];
    final signals = {
      for (final s in ingredientSignals(
          'Cetyl Alcohol, Squalane, Tocopherol, Isopropyl Myristate',
          notes,
          formulas))
        s.ingredient: s
    };
    expect(signals['cetyl alcohol']!.level, IngredientSignalLevel.repeated);
    expect(signals['squalane']!.level, IngredientSignalLevel.mixed);
    expect(signals['tocopherol']!.level, IngredientSignalLevel.tolerated);
    expect(signals['isopropyl myristate']!.level, IngredientSignalLevel.watch);
    expect(
        ingredientSignals('Cetyl Alcohol', notes, formulas, excludeProduct: 'b')
            .single
            .level,
        IngredientSignalLevel.overlap);
  });
  test(
      'duplicate shades, unsure and irritation never create false repeated or green evidence',
      () {
    const notes = [
      WearNote(productKey: 'a', reaction: 'Breakout'),
      WearNote(productKey: 'a', shade: '2', reaction: 'Breakout'),
      WearNote(productKey: 'b', reaction: 'Irritation'),
      WearNote(productKey: 'c', reaction: 'Unsure')
    ];
    final s = ingredientSignals('Water, Cetyl Alcohol', notes, {
      'a': 'Water, Cetyl Alcohol',
      'b': 'Cetyl Alcohol',
      'c': 'Cetyl Alcohol'
    }).single;
    expect(s.level, IngredientSignalLevel.overlap);
    expect(s.breakoutProducts, ['a']);
    expect(s.toleratedProducts, isEmpty);
  });
  test('every skincare item has sourced formula data and no shades', () async {
    final products =
        jsonDecode(await rootBundle.loadString('assets/catalog/products.json'))
            as List;
    final details = await loadBeautyDetails();
    var total = 0, full = 0;
    for (final p in products.where((p) => [
          'cleanser',
          'moisturizer',
          'serum',
          'sunscreen',
          'toner',
          'treatment',
          'eye_cream',
          'exfoliant',
          'face_oil',
          'mist',
          'skincare',
          'mask'
        ].contains(p['category']))) {
      total++;
      final d = details['${p['brand']}|${p['name']}'.toLowerCase()]!;
      expect(d.ingredients, isNotEmpty, reason: p['name']);
      expect(d.ingredientSource, startsWith('https://'));
      expect(d.checked, isNotEmpty);
      expect(d.howToUse, isNotEmpty);
      expect(d.formulaNote, isNotEmpty);
      expect(d.shades, isEmpty);
      if (d.ingredientsComplete) full++;
      if (p['brand'] == 'Hero Cosmetics') {
        expect(d.ingredientsComplete, isFalse);
      }
    }
    expect(total, 46);
    expect(full, 45);
    final kiehls = details["kiehl's|ultra facial cream"]!;
    expect(
        ingredientSignals(kiehls.ingredients, [], {}).map((s) => s.ingredient),
        containsAll([
          'myristyl myristate',
          'peg-8 stearate',
          'cetyl alcohol',
          'stearic acid'
        ]));
  });
  test(
      'ingredient guides distinguish hydration from acids and match active percentages',
      () {
    final names = guidesForIngredients(formulaIngredients(
            'Sodium Hyaluronate, Retinol 0.5%, Zinc Oxide (9%)'))
        .map((g) => g.name);
    expect(names,
        containsAll(['Hyaluronic acid', 'Retinol', 'Sunscreen filters']));
    for (final g in ingredientGuides) {
      expect(g.benefit.length, greaterThan(60));
      expect(g.use, isNotEmpty);
      expect(g.pairs, isNotEmpty);
      expect(g.caution, isNotEmpty);
      expect(g.source, startsWith('https://'));
    }
  });
  testWidgets(
      'guidance expands and guest watch list never uses private evidence at 320px',
      (tester) async {
    tester.view.physicalSize = const Size(320, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: Column(children: [
      IngredientGuideCard(guide: guideForName('sodium hyaluronate')!),
      const IngredientSignalPanel(
          formula: 'Cetyl Alcohol',
          productKey: 'target',
          notes: [WearNote(productKey: 'other', reaction: 'Tolerated')],
          formulas: {'other': 'Cetyl Alcohol'},
          loggedIn: false,
          rinseOff: false)
    ])))));
    await tester.tap(find.text('Hyaluronic acid'));
    await tester.pumpAndSettle();
    expect(find.text('How to use'), findsOneWidget);
    expect(find.text('Pairs well with'), findsOneWidget);
    expect(find.text('Use with care'), findsOneWidget);
    expect(find.text('Watch list'), findsOneWidget);
    expect(find.text('Previously tolerated'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
