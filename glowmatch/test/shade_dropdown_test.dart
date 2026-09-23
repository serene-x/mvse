import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mvse/widgets/shade_dropdown.dart';
import 'package:mvse/widgets/buy_buttons.dart';
import 'package:url_launcher/link.dart';

void main() {
  testWidgets('shade menu opens below its field and selects a named shade',
      (tester) async {
    String? selected;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Padding(
                padding: const EdgeInsets.all(24),
                child: ShadeDropdown(
                    shades: const ['Rose', 'Peach'],
                    onChanged: (v) => selected = v)))));
    final field = find.byType(TextField);
    final bottom = tester.getBottomLeft(field).dy;
    await tester.tap(field);
    await tester.pumpAndSettle();
    final option = find.widgetWithText(MenuItemButton, 'Peach');
    expect(tester.getTopLeft(option).dy, greaterThanOrEqualTo(bottom));
    await tester.tap(option);
    await tester.pumpAndSettle();
    expect(selected, 'Peach');
    expect(tester.takeException(), isNull);
  });
  testWidgets('near the viewport bottom the shade list stays below and scrolls',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Padding(
                padding: const EdgeInsets.only(top: 390, left: 20, right: 20),
                child: ShadeDropdown(
                    shades: List.generate(30, (i) => 'Shade $i'),
                    onChanged: (_) {})))));
    final field = find.byType(TextField);
    final bottom = tester.getBottomLeft(field).dy;
    await tester.tap(field);
    await tester.pumpAndSettle();
    final first = find.widgetWithText(MenuItemButton, 'Shade 0');
    expect(tester.getTopLeft(first).dy, greaterThanOrEqualTo(bottom));
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'a direct Sephora product link takes priority over search and opens in the same tab',
      (tester) async {
    MethodCall? launch;
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      launch = call;
      return true;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: BuyButtons(
                sephoraUrl: 'https://www.sephora.com/product/lip-cheek-P416478',
                searchTerm: 'Milk Makeup Lip + Cheek'))));
    expect(find.text('View at Sephora'), findsOneWidget);
    expect(find.text('Search Sephora'), findsNothing);
    final link = tester.widget<Link>(find.byType(Link));
    expect(link.uri.toString(),
        'https://www.sephora.com/product/lip-cheek-P416478');
    expect(link.target, LinkTarget.self);
    await tester.tap(find.text('View at Sephora'));
    await tester.pumpAndSettle();
    expect(launch?.method, 'launch');
    expect((launch?.arguments as Map)['url'], link.uri.toString());
  });
}
