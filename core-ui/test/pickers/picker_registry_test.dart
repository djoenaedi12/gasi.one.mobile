import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasione_core_api/gasione_core_api.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';

void main() {
  for (final (presentation, define) in [
    ('sheet', PickerDefinition<int>.sheet),
    ('dialog', PickerDefinition<int>.dialog),
  ]) {
    testWidgets(
      'registered $presentation returns typed values to a picker form field',
      (tester) async {
        const key = PickerKey<int>('employee');
        int? selected;
        PickerRequest<int>? received;
        final registry = PickerRegistry([
          define(
            key: key,
            contentBuilder: (context, request) {
              received = request;
              return ListView(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, 42),
                    child: const Text('Choose 42'),
                  ),
                ],
              );
            },
          ),
        ]);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: AppPickerFormField<int>(
                label: 'Employee',
                value: null,
                labelOf: (value) => 'Employee $value',
                onChanged: (value) => selected = value,
                onPick: (context) => registry.open(
                  context,
                  key,
                  request: const PickerRequest(
                    title: 'Choose employee',
                    initialValue: 7,
                    arguments: {'active': true},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(
          find.descendant(
            of: find.byType(AppPickerFormField<int>),
            matching: find.byType(InkWell),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.text('Choose employee'), findsOneWidget);
        expect(received?.initialValue, 7);
        expect(received?.arguments, {'active': true});
        await tester.tap(find.text('Choose 42'));
        await tester.pumpAndSettle();
        expect(selected, 42);
        expect(find.text('Employee 42'), findsOneWidget);
        expect(find.byType(BottomSheet), findsNothing);
        await tester.tap(
          find.descendant(
            of: find.byType(AppPickerFormField<int>),
            matching: find.byType(InkWell),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Close'));
        await tester.pumpAndSettle();
        expect(selected, 42);
        expect(find.text('Employee 42'), findsOneWidget);
      },
    );

    testWidgets(
      'cancelled registered $presentation returns null and preserves the host',
      (tester) async {
        const key = PickerKey<int>('employee');
        int? selected = 7;
        final registry = PickerRegistry([
          define(
            key: key,
            contentBuilder: (_, _) =>
                const Center(child: Text('Picker content')),
          ),
        ]);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () async =>
                      selected = await registry.open(context, key),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(selected, isNull);
        expect(find.text('Open'), findsOneWidget);
      },
    );
  }

  testWidgets(
    'picker returns typed values and rejects missing/incorrect registrations',
    (tester) async {
      const key = PickerKey<int>('employee');
      final definition = PickerDefinition<int>(
        key: key,
        pageBuilder: (context, request) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.pop(context, request.initialValue),
            child: const Text('Choose'),
          ),
        ),
      );
      final registry = PickerRegistry([definition]);
      int? selected;
      late BuildContext host;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              host = context;
              return TextButton(
                onPressed: () async {
                  selected = await registry.open(
                    context,
                    key,
                    request: const PickerRequest(initialValue: 7),
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose'));
      await tester.pumpAndSettle();
      expect(selected, 7);
      expect(
        () => registry.open(host, const PickerKey<String>('employee')),
        throwsA(isA<PickerTypeMismatchException>()),
      );
      expect(
        () => registry.open(host, const PickerKey<int>('missing')),
        throwsA(isA<PickerUnavailableException>()),
      );
      expect(
        () => PickerRegistry([definition, definition]),
        throwsArgumentError,
      );
    },
  );
}
