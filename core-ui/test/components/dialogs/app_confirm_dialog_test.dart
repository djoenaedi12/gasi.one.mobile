import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';

void main() {
  testWidgets('returns true when the confirmation action is selected', (
    tester,
  ) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await AppConfirmDialog.show(
                context,
                title: 'Delete product?',
                message: 'This action cannot be undone.',
                cancelLabel: 'Cancel',
                confirmLabel: 'Delete',
                destructive: true,
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });

  testWidgets('stays open and shows loading while async action runs', (
    tester,
  ) async {
    final action = Completer<bool>();
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await AppConfirmDialog.showAsync(
                context,
                title: 'Delete product?',
                message: 'This action cannot be undone.',
                cancelLabel: 'Cancel',
                confirmLabel: 'Delete',
                destructive: true,
                onConfirm: () => action.future,
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pump();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    action.complete(true);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(result, isTrue);
  });
}
