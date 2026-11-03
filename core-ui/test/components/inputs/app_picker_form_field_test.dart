import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  home: Scaffold(body: child),
);

AppPickerFormField<int> _field({
  int? value,
  bool enabled = true,
  required Future<int?> Function(BuildContext) onPick,
  ValueChanged<int?>? onChanged,
}) => AppPickerFormField<int>(
  label: 'Employee',
  value: value,
  enabled: enabled,
  labelOf: (value) => 'Employee $value',
  onPick: onPick,
  onChanged: onChanged,
);

void main() {
  testWidgets('rapid taps launch once and cancellation unlocks the field', (
    tester,
  ) async {
    var result = Completer<int?>();
    var calls = 0;
    int? selected;
    await tester.pumpWidget(
      _app(
        _field(
          onPick: (_) {
            calls++;
            return result.future;
          },
          onChanged: (value) => selected = value,
        ),
      ),
    );
    final tap = tester.widget<InkWell>(find.byType(InkWell)).onTap!;
    tap();
    // The old handler may be invoked again before the disabled state rebuilds.
    tap();
    await tester.pump();
    expect(calls, 1);
    expect(tester.widget<InkWell>(find.byType(InkWell)).onTap, isNull);
    result.complete(null);
    await tester.pump();
    expect(selected, isNull);
    result = Completer<int?>();
    await tester.tap(find.byType(InkWell));
    expect(calls, 2);
    result.complete(7);
    await tester.pump();
    expect(selected, 7);
    expect(find.text('Employee 7'), findsOneWidget);
    expect(tester.widget<InkWell>(find.byType(InkWell)).onTap, isNotNull);
  });

  testWidgets(
    'external value update invalidates a result for the replaced field',
    (tester) async {
      final result = Completer<int?>();
      var changes = 0;
      Widget app(int value) => _app(
        _field(
          value: value,
          onPick: (_) => result.future,
          onChanged: (_) => changes++,
        ),
      );
      await tester.pumpWidget(app(1));
      final state = tester.state(find.byType(AppPickerFormField<int>));
      await tester.tap(find.byType(InkWell));
      await tester.pumpWidget(app(2));
      expect(tester.state(find.byType(AppPickerFormField<int>)), same(state));
      result.complete(3);
      await tester.pump();
      expect(changes, 0);
      expect(find.text('Employee 2'), findsOneWidget);
      expect(find.text('Employee 3'), findsNothing);
      expect(tester.takeException(), isNull);
      expect(tester.widget<InkWell>(find.byType(InkWell)).onTap, isNotNull);
    },
  );

  testWidgets('result arriving after unmount does not update or notify', (
    tester,
  ) async {
    final result = Completer<int?>();
    var changes = 0;
    await tester.pumpWidget(
      _app(_field(onPick: (_) => result.future, onChanged: (_) => changes++)),
    );
    await tester.tap(find.byType(InkWell));
    await tester.pumpWidget(const SizedBox());
    result.complete(7);
    await tester.pump();
    expect(changes, 0);
    expect(tester.takeException(), isNull);
  });

  for (final disabled in [true, false]) {
    testWidgets(
      'pending result is ignored when field becomes ${disabled ? 'disabled' : 'read-only'}',
      (tester) async {
        final result = Completer<int?>();
        var changes = 0;
        Widget app({required bool writable}) => _app(
          _field(
            value: 1,
            enabled: writable || !disabled,
            onPick: (_) => result.future,
            onChanged: writable || disabled ? (_) => changes++ : null,
          ),
        );
        await tester.pumpWidget(app(writable: true));
        await tester.tap(find.byType(InkWell));
        await tester.pumpWidget(app(writable: false));
        result.complete(7);
        await tester.pump();
        expect(changes, 0);
        expect(find.text('Employee 1'), findsOneWidget);
        await tester.pumpWidget(app(writable: true));
        expect(tester.widget<InkWell>(find.byType(InkWell)).onTap, isNotNull);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
