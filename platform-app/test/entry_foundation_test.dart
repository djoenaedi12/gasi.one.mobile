import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasione/app/app_entry_page.dart';
import 'package:gasione/app/plugin_route_bridge.dart';
import 'package:gasione_core_api/gasione_core_api.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';

final class _Auth implements AuthRestorer {
  int calls = 0;
  Future<AuthStatus> Function() attempt = () async =>
      throw StateError('private');
  @override
  Future<AuthStatus> restore() {
    calls++;
    return attempt();
  }
}

void main() {
  testWidgets(
    'generic entry sanitizes failures and retries once across rebuilds',
    (tester) async {
      final auth = _Auth();
      final pending = Completer<AuthStatus>();
      Widget app() => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AppEntryPage(
          auth: auth,
          buildDestination: (_, status) => Text(status.name),
        ),
      );
      await tester.pumpWidget(app());
      await tester.pump();
      expect(find.textContaining('private'), findsNothing);
      expect(find.text('Retry'), findsOneWidget);
      auth.attempt = () => pending.future;
      await tester.tap(find.text('Retry'));
      await tester.pumpWidget(app());
      expect(auth.calls, 2);
      pending.complete(AuthStatus.loginRequired);
      await tester.pump();
      expect(find.text('loginRequired'), findsOneWidget);
    },
  );
  testWidgets(
    'plugin bridge preserves settings, handles queries, and falls back',
    (tester) async {
      RouteSettings? received;
      var fallbackCalls = 0;
      final bridge = PluginRouteBridge(
        [
          PluginPageRoute(
            path: '/feature',
            builder: (_, settings) {
              received = settings;
              return const Text('plugin');
            },
          ),
        ],
        fallback: (settings) {
          fallbackCalls++;
          return MaterialPageRoute<void>(builder: (_) => const Text('legacy'));
        },
      );
      await tester.pumpWidget(
        MaterialApp(home: const Text('home'), onGenerateRoute: bridge.call),
      );
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      unawaited(navigator.pushNamed('/feature?id=7', arguments: 8));
      await tester.pumpAndSettle();
      expect(find.text('plugin'), findsOneWidget);
      expect(received!.arguments, 8);
      expect(received!.name, '/feature?id=7');
      unawaited(navigator.pushNamed('/legacy'));
      await tester.pumpAndSettle();
      expect(find.text('legacy'), findsOneWidget);
      expect(fallbackCalls, 1);
      expect(
        () => PluginRouteBridge([
          PluginPageRoute(path: '/x', builder: (_, _) => const SizedBox()),
          PluginPageRoute(path: '/x', builder: (_, _) => const SizedBox()),
        ]),
        throwsArgumentError,
      );
    },
  );
}
