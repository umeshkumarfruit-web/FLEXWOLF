import 'package:flexwolf/core/widgets/app_product_card_shell.dart';
import 'package:flexwolf/core/widgets/app_quick_add_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('sale badge keeps card image and quick add at full width', (
    tester,
  ) async {
    Widget card(String name, {bool sale = false}) => SizedBox(
      width: 160,
      height: 340,
      child: AppProductCardShell(
        title: name,
        price: const Text('₹999'),
        badge: sale ? const Text('SALE') : null,
        image: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(key: ValueKey('$name-image'), color: Colors.grey),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: AppQuickAddButton(
                key: ValueKey('$name-button'),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(children: [card('regular'), card('sale', sale: true)]),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(const ValueKey('sale-image'))).width, 160);
    expect(
      tester.getSize(find.byKey(const ValueKey('regular-image'))).width,
      160,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('sale-button'))).width,
      144,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('regular-button'))).width,
      144,
    );
    expect(tester.takeException(), isNull);
  });
}
