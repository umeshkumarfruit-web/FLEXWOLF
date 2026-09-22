import 'package:flexwolf/core/widgets/app_quick_add_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('quick add stays on one line in narrow product cards', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 118,
              child: AppQuickAddButton(onPressed: () {}),
            ),
          ),
        ),
      ),
    );

    final label = tester.widget<Text>(find.text('QUICK ADD'));
    expect(label.maxLines, 1);
    expect(label.softWrap, isFalse);
    expect(tester.getSize(find.byType(AppQuickAddButton)).height, 40);
    expect(tester.takeException(), isNull);
  });
}
