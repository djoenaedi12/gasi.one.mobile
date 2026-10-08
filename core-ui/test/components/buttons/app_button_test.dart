import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';

void main() {
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
