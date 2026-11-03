import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';

void main() {
  testWidgets('result content can be embedded without owning navigation', (
    tester,
  ) async {
    var actions = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Material(
          child: AppResultContent(
            status: AppResultStatus.success,
            title: 'Complete',
            message: 'Saved.',
            primaryActionLabel: 'Continue',
            onPrimaryAction: () => actions++,
          ),
        ),
      ),
    );
    expect(find.byType(Scaffold), findsNothing);
    await tester.tap(find.text('Continue'));
    expect(actions, 1);
    expect(find.text('Complete'), findsOneWidget);
  });

  testWidgets('result sheet returns typed actions without replacing the host', (
    tester,
  ) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await AppResultSheet.show<bool>(
                  context,
                  builder: (sheetContext) => AppResultContent(
                    status: AppResultStatus.success,
                    title: 'Saved',
                    message: 'Request submitted.',
                    primaryActionLabel: 'Continue',
                    onPrimaryAction: () => Navigator.pop(sheetContext, true),
                    secondaryActionLabel: 'Review',
                    onSecondaryAction: () => Navigator.pop(sheetContext, false),
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(AppResultContent), findsOneWidget);
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    expect(result, false);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(result, true);
    expect(find.text('Open'), findsOneWidget);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(result, isNull);
    expect(find.byType(AppResultContent), findsNothing);
  });

  testWidgets('long result sheet scrolls to its action on a small viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => AppResultSheet.show<void>(
                context,
                builder: (sheetContext) => AppResultContent(
                  status: AppResultStatus.failure,
                  title: 'Please review',
                  message: List.filled(
                    30,
                    'The selected period is closed.',
                  ).join('\n'),
                  primaryActionLabel: 'Back to form',
                  onPrimaryAction: () => Navigator.pop(sheetContext),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Back to form'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back to form'));
    await tester.pumpAndSettle();
    expect(find.byType(AppResultContent), findsNothing);
    expect(find.text('Open'), findsOneWidget);
  });

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
