import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasione/app/startup_gate.dart';

void main() {
  testWidgets(
    'abandoned startup disposes resources when initialization finishes',
    (tester) async {
      final result = Completer<String>();
      var disposals = 0;
      await tester.pumpWidget(
        StartupGate<String>(
          initialize: () => result.future,
          disposeValue: (_) async {
            disposals++;
          },
          builder: (_) => const SizedBox.shrink(),
        ),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      result.complete('Ready');
      await tester.pump();
      expect(disposals, 1);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('rebuilding the gate does not initialize services twice', (
    tester,
  ) async {
    var calls = 0;
    final result = Completer<String>();
    Future<String> initialize() {
      calls++;
      return result.future;
    }

    Widget app() => StartupGate<String>(
      initialize: initialize,
      builder: (value) =>
          Directionality(textDirection: TextDirection.ltr, child: Text(value)),
    );
    await tester.pumpWidget(app());
    await tester.pumpWidget(app());
    expect(calls, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    result.complete('Ready');
    await tester.pump();
    expect(find.text('Ready'), findsOneWidget);
  });

  testWidgets(
    'failure is sanitized and retry is a separate initialization attempt',
    (tester) async {
      var calls = 0;
      final retry = Completer<String>();
      await tester.pumpWidget(
        StartupGate<String>(
          initialize: () {
            calls++;
            if (calls == 1) throw StateError('private native failure details');
            return retry.future;
          },
          builder: (value) => Directionality(
            textDirection: TextDirection.ltr,
            child: Text(value),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('private native'), findsNothing);
      await tester.tap(find.text('Coba lagi'));
      await tester.tap(find.text('Coba lagi'));
      await tester.pump();
      expect(calls, 2);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Coba lagi'), findsNothing);
      retry.complete('Ready');
      await tester.pumpAndSettle();
      expect(find.text('Ready'), findsOneWidget);
    },
  );
}
