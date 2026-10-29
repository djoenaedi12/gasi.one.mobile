import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasione_core_api/gasione_core_api.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';

void main() {
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
