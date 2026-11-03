import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';

void main() {
  testWidgets('long labels wrap beside an icon within narrow button bounds', (
    tester,
  ) async {
    var presses = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 180,
              child: AppButton.primary(
                label: 'Continue to confirmation',
                icon: Icons.check,
                expand: true,
                onPressed: () => presses++,
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final button = tester.getRect(find.byType(FilledButton));
    final label = tester.getRect(find.text('Continue to confirmation'));
    expect(label.left, greaterThanOrEqualTo(button.left));
    expect(label.right, lessThanOrEqualTo(button.right));
    await tester.tap(find.text('Continue to confirmation'));
    expect(presses, 1);
  });

  testWidgets('maps semantic variants to their Material button types', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              AppButton.primary(label: 'Primary', onPressed: () {}),
              AppButton.secondary(label: 'Secondary', onPressed: () {}),
              AppButton.destructive(label: 'Delete', onPressed: () {}),
              AppButton.outline(label: 'Outline', onPressed: () {}),
              AppButton.ghost(label: 'Ghost', onPressed: () {}),
              AppButton.link(label: 'Link', onPressed: () {}),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(FilledButton), findsNWidgets(3));
    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(find.byType(TextButton), findsNWidgets(2));

    final deleteButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Delete'),
    );
    final deleteContext = tester.element(find.text('Delete'));
    expect(
      deleteButton.style?.backgroundColor?.resolve({}),
      Theme.of(deleteContext).colorScheme.error,
    );

    final linkButton = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Link'),
    );
    expect(
      linkButton.style?.textStyle?.resolve({})?.decoration,
      TextDecoration.underline,
    );
  });

  testWidgets('shows progress and disables interaction while loading', (
    tester,
  ) async {
    var pressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton.primary(
            label: 'Save',
            isLoading: true,
            onPressed: () => pressed = true,
          ),
        ),
      ),
    );

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    final buttonContext = tester.element(find.byType(FilledButton));
    expect(
      button.style?.backgroundColor?.resolve({WidgetState.disabled}),
      isNot(Theme.of(buttonContext).colorScheme.primary),
    );
    expect(pressed, isFalse);
  });
}
