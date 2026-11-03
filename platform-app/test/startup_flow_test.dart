import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasione/app/app_entry_page.dart';
import 'package:gasione/app/device_access_gate.dart';
import 'package:gasione/app/startup_gate.dart';
import 'package:gasione_core_api/gasione_core_api.dart';
import 'package:gasione_core_starter/gasione_core_starter.dart'
    show DeviceSecurityPolicy;
import 'package:gasione_core_ui/gasione_core_ui.dart';

final class _Auth implements AuthRestorer {
  final session = Completer<AuthStatus>();
  int calls = 0;

  @override
  Future<AuthStatus> restore() {
    calls++;
    return session.future;
  }
}

Widget _featureShell(_Auth auth) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: AppEntryPage(
    auth: auth,
    buildDestination: (_, status) =>
        Scaffold(body: Text('page:${status.name}')),
  ),
);

void main() {
  final checklistCases = [
    (
      'rooted device',
      const DeviceSecurityReport(
        jailbroken: true,
        realDevice: true,
        developmentMode: false,
        externalStorage: false,
        signatureValid: true,
      ),
      {'Not rooted, jailbroken, or an emulator'},
    ),
    (
      'emulator',
      const DeviceSecurityReport(
        jailbroken: false,
        realDevice: false,
        developmentMode: false,
        externalStorage: false,
        signatureValid: true,
      ),
      {'Not rooted, jailbroken, or an emulator'},
    ),
    (
      'developer mode',
      const DeviceSecurityReport(
        jailbroken: false,
        realDevice: true,
        developmentMode: true,
        externalStorage: false,
        signatureValid: true,
      ),
      {'Developer mode turned off'},
    ),
    (
      'external storage',
      const DeviceSecurityReport(
        jailbroken: false,
        realDevice: true,
        developmentMode: false,
        externalStorage: true,
        signatureValid: true,
      ),
      {'Installed in internal storage'},
    ),
    (
      'all requirements failed',
      const DeviceSecurityReport(
        jailbroken: true,
        realDevice: false,
        developmentMode: true,
        externalStorage: true,
        signatureValid: true,
      ),
      {
        'Not rooted, jailbroken, or an emulator',
        'Developer mode turned off',
        'Installed in internal storage',
      },
    ),
  ];
  for (final (name, report, failedRequirements) in checklistCases) {
    testWidgets('checklist identifies only failed requirements for $name', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          DeviceAccessGate(
            security: const DeviceSecurityPolicy().evaluate(report),
            child: const SizedBox.shrink(),
          ),
        );
        await tester.pumpAndSettle();
        for (final requirement in [
          'Not rooted, jailbroken, or an emulator',
          'Developer mode turned off',
          'Installed in internal storage',
        ]) {
          final status = failedRequirements.contains(requirement)
              ? 'Requirement not met'
              : 'Requirement met';
          expect(
            find.bySemanticsLabel('$requirement: $status'),
            findsOneWidget,
          );
        }
        expect(
          find.byIcon(Icons.close_rounded),
          findsNWidgets(failedRequirements.length),
        );
        expect(
          find.byIcon(Icons.check_rounded),
          findsNWidgets(3 - failedRequirements.length),
        );
      } finally {
        semantics.dispose();
      }
    });
  }

  for (final status in AuthStatus.values) {
    testWidgets('startup waits for services and session before $status', (
      tester,
    ) async {
      final services = Completer<DeviceSecurity>();
      final auth = _Auth();
      var initializationCalls = 0;
      await tester.pumpWidget(
        StartupGate<DeviceSecurity>(
          initialize: () {
            initializationCalls++;
            return services.future;
          },
          builder: (security) =>
              DeviceAccessGate(security: security, child: _featureShell(auth)),
        ),
      );
      expect(auth.calls, 0);
      expect(find.byType(AppSplashPage), findsOneWidget);

      services.complete(
        const DeviceSecurity(unsafeDevice: false, signatureValid: true),
      );
      await tester.pump();
      expect(auth.calls, 0);
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(auth.calls, 1);
      expect(find.text('page:${status.name}'), findsNothing);
      expect(find.byType(AppSplashPage), findsOneWidget);

      auth.session.complete(status);
      await tester.pumpAndSettle();
      expect(find.text('page:${status.name}'), findsOneWidget);
      expect(initializationCalls, 1);
      expect(auth.calls, 1);
      expect(tester.takeException(), isNull);
    });
  }

  final denied = [
    (
      const DeviceSecurity(unsafeDevice: true, signatureValid: true),
      'Device Does Not Meet Security Standard',
    ),
    (
      const DeviceSecurity(unsafeDevice: false, signatureValid: false),
      'Invalid application',
    ),
    (
      const DeviceSecurity(unsafeDevice: true, signatureValid: false),
      'Invalid application',
    ),
  ];
  for (final (security, title) in denied) {
    testWidgets(
      'blocked access shows $title without starting session restore '
      '(unsafe=${security.unsafeDevice}, signature=${security.signatureValid})',
      (tester) async {
        final auth = _Auth();
        await tester.pumpWidget(
          DeviceAccessGate(security: security, child: _featureShell(auth)),
        );
        await tester.pumpAndSettle();
        expect(find.text(title), findsOneWidget);
        expect(auth.calls, 0);
        expect(find.byType(AppEntryPage), findsNothing);
        expect(find.byType(MaterialApp), findsOneWidget);
        if (security.signatureValid) {
          expect(find.byTooltip('Check result unavailable'), findsNWidgets(3));
          expect(find.byIcon(Icons.close_rounded), findsNothing);
        } else {
          expect(find.text('Developer mode turned off'), findsNothing);
        }
        final navigator = tester.state<NavigatorState>(find.byType(Navigator));
        // maybePop reports the back action as handled even when PopScope
        // prevents the page from being removed.
        expect(await navigator.maybePop(), true);
        await tester.pumpAndSettle();
        expect(find.text(title), findsOneWidget);
        expect(auth.calls, 0);
      },
    );
  }

  testWidgets('blocked page honors the saved Indonesian language', (
    tester,
  ) async {
    await tester.pumpWidget(
      const DeviceAccessGate(
        security: DeviceSecurity(unsafeDevice: true, signatureValid: true),
        locale: Locale('id'),
        child: SizedBox.shrink(),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Perangkat tidak memenuhi standar keamanan'),
      findsOneWidget,
    );
    expect(find.text('Keluar'), findsOneWidget);
  });
}
