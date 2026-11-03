import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasione/app/plugin_composition.dart';
import 'package:gasione_core_api/gasione_core_api.dart';

final class _Plugin
    implements
        AppPlugin,
        PageRouteContributor,
        PickerContributor,
        PluginLifecycle,
        NotificationDestinationResolver {
  _Plugin(
    this.code,
    this.events, {
    this.path,
    this.pickerId,
    this.delegates = const [],
    this.failStart = false,
    this.startGate,
  });
  @override
  final String code;
  final List<String> events;
  final String? path;
  final String? pickerId;
  final List<LocalizationsDelegate<dynamic>> delegates;
  final bool failStart;
  final Completer<void>? startGate;
  @override
  List<PluginPageRoute> get pageRoutes => [
    if (path != null)
      PluginPageRoute(path: path!, builder: (_, _) => Text(code)),
  ];
  @override
  List<PickerDefinitionBase> get pickers => [
    if (pickerId != null)
      PickerDefinition<int>(
        key: PickerKey<int>(pickerId!),
        pageBuilder: (_, _) => const SizedBox(),
      ),
  ];
  @override
  List<PluginRoute> get routes => const [];
  @override
  List<PluginMenuItem> get menus => const [];
  @override
  List<LocalizationsDelegate<dynamic>> get localizationsDelegates => delegates;
  @override
  List<Locale> get supportedLocales => const [Locale('id')];
  @override
  Future<void> start() async {
    events.add('start:$code');
    await startGate?.future;
    if (failStart) throw StateError('start failed');
  }

  @override
  void dispose() => events.add('dispose:$code');
  @override
  NotificationDestination? resolveNotification(
    NotificationInteraction interaction,
    ActiveBusinessContext context,
  ) => null;
}

void main() {
  testWidgets(
    'composition exposes routes, locale, resolver and typed picker together',
    (tester) async {
      final plugin = _Plugin('demo', [], path: '/demo', pickerId: 'demo.pick');
      final composition = PluginComposition(plugins: [plugin]);
      expect(composition.supportedLocales, [const Locale('id')]);
      expect(composition.notificationResolvers, [plugin]);
      expect(composition.routes.containsPath('/demo?id=7'), true);
      expect(
        composition.routes.containsPath('https://external.test/demo'),
        false,
      );
      expect(composition.routes.containsPath('//external.test/demo'), false);
      await tester.pumpWidget(
        MaterialApp(
          home: const Text('home'),
          onGenerateRoute: composition.routes.call,
        ),
      );
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      unawaited(navigator.pushNamed('/demo'));
      await tester.pumpAndSettle();
      expect(find.text('demo'), findsOneWidget);
    },
  );

  test(
    'duplicate plugin, page, picker and localization fail at composition time',
    () {
      expect(
        () => PluginComposition(
          plugins: [_Plugin('same', []), _Plugin('same', [])],
        ),
        throwsArgumentError,
      );
      expect(
        () => PluginComposition(
          plugins: [
            _Plugin('a', [], path: '/same'),
            _Plugin('b', [], path: '/same'),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => PluginComposition(
          plugins: [
            _Plugin('a', [], pickerId: 'same'),
            _Plugin('b', [], pickerId: 'same'),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => PluginComposition(
          plugins: [
            _Plugin('a', [], delegates: [DefaultWidgetsLocalizations.delegate]),
            _Plugin('b', [], delegates: [DefaultWidgetsLocalizations.delegate]),
          ],
        ),
        throwsArgumentError,
      );
    },
  );

  test('lifecycle starts once and disposes once in reverse order', () async {
    final events = <String>[];
    final composition = PluginComposition(
      plugins: [_Plugin('a', events), _Plugin('b', events)],
    );
    await Future.wait([composition.start(), composition.start()]);
    await Future.wait([composition.dispose(), composition.dispose()]);
    await composition.start();
    expect(events, ['start:a', 'start:b', 'dispose:b', 'dispose:a']);
  });

  test('failed startup releases partially initialized services', () async {
    final events = <String>[];
    final composition = PluginComposition(
      plugins: [
        _Plugin('a', events),
        _Plugin('b', events, failStart: true),
        _Plugin('c', events),
      ],
    );
    await expectLater(composition.start(), throwsStateError);
    await composition.dispose();
    expect(events, [
      'start:a',
      'start:b',
      'dispose:c',
      'dispose:b',
      'dispose:a',
    ]);
  });

  test(
    'disposal during startup stops remaining plugins and awaits cleanup',
    () async {
      final events = <String>[];
      final gate = Completer<void>();
      final composition = PluginComposition(
        plugins: [
          _Plugin('a', events, startGate: gate),
          _Plugin('b', events),
        ],
      );
      final start = composition.start();
      final disposal = composition.dispose();
      gate.complete();
      await start;
      await disposal;
      expect(events, ['start:a', 'dispose:b', 'dispose:a']);
    },
  );
}
