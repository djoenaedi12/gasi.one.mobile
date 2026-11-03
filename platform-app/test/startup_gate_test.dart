import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasione/app/startup_gate.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';

void main() {
  for (final (deviceLocale, message, retryLabel) in [
    (
      const Locale('id'),
      'Aplikasi belum dapat disiapkan. Silakan coba lagi.',
      'Coba lagi',
    ),
    (
      const Locale('fr'),
      'Unable to prepare the application. Please try again.',
      'Retry',
    ),
  ]) {
    testWidgets(
      'startup uses shared preparation UI for device locale $deviceLocale',
      (tester) async {
        tester.platformDispatcher.localesTestValue = [deviceLocale];
        addTearDown(tester.platformDispatcher.clearLocalesTestValue);
        final result = Completer<String>();
        var attempts = 0;
        await tester.pumpWidget(
          StartupGate<String>(
            initialize: () {
              attempts++;
              if (attempts == 1) throw StateError('private startup details');
              return result.future;
            },
            builder: (value) => Directionality(
              textDirection: TextDirection.ltr,
              child: Text(value),
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();
        expect(find.byType(AppSplashPage), findsOneWidget);
        expect(find.text(message), findsOneWidget);
        expect(find.textContaining('private'), findsNothing);
        await tester.tap(find.text(retryLabel));
        await tester.pump();
        expect(attempts, 2);
        expect(find.byType(AppSplashPage), findsOneWidget);
        result.complete('Ready');
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();
        expect(find.text('Ready'), findsOneWidget);
      },
    );
  }

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
    expect(find.byType(AppSplashPage), findsOneWidget);
    result.complete('Ready');
    await tester.pump(const Duration(seconds: 2));
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
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.textContaining('private native'), findsNothing);
      await tester.tap(find.text('Retry'));
      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(calls, 2);
      expect(find.byType(AppSplashPage), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
      retry.complete('Ready');
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('Ready'), findsOneWidget);
    },
  );

  testWidgets('fast preparation keeps the splash for exactly the minimum', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      StartupGate<String>(
        initialize: () async {
          calls++;
          return '4.15.0';
        },
        versionOf: (value) => value,
        builder: (_) => const Directionality(
          textDirection: TextDirection.ltr,
          child: Text('Ready'),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(AppSplashPage), findsOneWidget);
    expect(find.text('Version 4.15.0'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1999));
    expect(find.text('Ready'), findsNothing);
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('Ready'), findsOneWidget);
    expect(calls, 1);
  });

  testWidgets('slow preparation remains on splash until it finishes', (
    tester,
  ) async {
    final result = Completer<String>();
    await tester.pumpWidget(
      StartupGate<String>(
        initialize: () => result.future,
        builder: (value) => Directionality(
          textDirection: TextDirection.ltr,
          child: Text(value),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 5));
    expect(find.byType(AppSplashPage), findsOneWidget);
    expect(find.text('Ready'), findsNothing);
    result.complete('Ready');
    await tester.pump();
    expect(find.text('Ready'), findsOneWidget);
  });

  testWidgets('early failure waits for minimum then retry shows splash again', (
    tester,
  ) async {
    var attempts = 0;
    final result = Completer<String>();
    await tester.pumpWidget(
      StartupGate<String>(
        initialize: () {
          attempts++;
          if (attempts == 1) throw StateError('private');
          return result.future;
        },
        builder: (value) => Directionality(
          textDirection: TextDirection.ltr,
          child: Text(value),
        ),
      ),
    );
    await tester.pump();
    final splash = tester.element(find.byType(AppSplashPage));
    await tester.pump(const Duration(milliseconds: 1999));
    expect(find.byType(AppSplashPage), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byType(AppSplashPage), findsOneWidget);
    expect(tester.element(find.byType(AppSplashPage)), same(splash));
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(find.byType(AppSplashPage), findsOneWidget);
    expect(tester.element(find.byType(AppSplashPage)), same(splash));
    expect(find.text('Retry'), findsNothing);
    result.complete('Ready');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1999));
    expect(find.text('Ready'), findsNothing);
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('Ready'), findsOneWidget);
    expect(attempts, 2);
  });

  testWidgets(
    'abandoning a prepared splash disposes the value and cancels timer',
    (tester) async {
      var disposals = 0;
      await tester.pumpWidget(
        StartupGate<String>(
          initialize: () async => 'Ready',
          disposeValue: (_) async => disposals++,
          builder: (_) => const SizedBox(),
        ),
      );
      await tester.pump();
      expect(find.byType(AppSplashPage), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(disposals, 1);
      await tester.pump(const Duration(seconds: 3));
      expect(tester.takeException(), isNull);
    },
  );
}
