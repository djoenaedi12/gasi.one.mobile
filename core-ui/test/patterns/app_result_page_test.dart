import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';

void main() {
  testWidgets('renders full-page success feedback and runs its action', (
    tester,
  ) async {
    var actionPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: AppResultPage(
          status: AppResultStatus.success,
          title: 'Success',
          message: 'Product added.',
          primaryActionLabel: 'Back to products',
          onPrimaryAction: () => actionPressed = true,
        ),
      ),
    );

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('Success'), findsOneWidget);
    expect(find.text('Product added.'), findsOneWidget);

    await tester.tap(find.text('Back to products'));
    expect(actionPressed, isTrue);
  });

  testWidgets('uses the failure presentation for failed processes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AppResultPage(
          status: AppResultStatus.failure,
          title: 'Operation failed',
          message: 'Unable to save the product.',
          primaryActionLabel: 'Back',
          onPrimaryAction: () {},
        ),
      ),
    );

    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(find.text('Unable to save the product.'), findsOneWidget);
  });
}
