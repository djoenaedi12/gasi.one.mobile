import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gasione/app/notification_navigation_coordinator.dart';
import 'package:gasione_core_api/gasione_core_api.dart';

ActiveBusinessContext _context(String session, {String company = 'ACME'}) =>
    ActiveBusinessContext(
      company: CompanyIdentity(code: company, baseUrl: 'https://$company.test'),
      employee: const EmployeeIdentity(id: 7, name: 'Employee'),
      username: 'employee',
      serverTimezone: '+07:00',
      isManager: true,
      permissions: {},
      sessionId: session,
    );

final class _Context implements BusinessContextProvider {
  final changes = StreamController<ActiveBusinessContext?>.broadcast(
    sync: true,
  );
  ActiveBusinessContext? value;
  void update(ActiveBusinessContext? context) {
    value = context;
    changes.add(context);
  }

  @override
  ActiveBusinessContext? get activeContext => value;
  @override
  Stream<ActiveBusinessContext?> get contextChanges => changes.stream;
}

final class _Resolver implements NotificationDestinationResolver {
  @override
  NotificationDestination? resolveNotification(
    NotificationInteraction interaction,
    ActiveBusinessContext context,
  ) {
    if (interaction.data['invalid'] == true) {
      throw const FormatException('private');
    }
    final route = interaction.data['route'];
    final company = interaction.data['company'];
    if (route is! String || company is! String) return null;
    return NotificationDestination(
      route: route,
      companyCode: company,
      arguments: interaction.id,
    );
  }
}

NotificationInteraction _event(
  String id, {
  String route = '/detail',
  String company = 'ACME',
}) =>
    NotificationInteraction(id: id, data: {'route': route, 'company': company});

Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  late _Context context;
  late StreamController<NotificationInteraction> interactions;
  late List<NotificationDestination> navigated;
  NotificationNavigationCoordinator build({
    NotificationInteraction? initial,
    void Function(void Function())? schedule,
    void Function(String, Object, StackTrace)? onError,
  }) {
    final coordinator = NotificationNavigationCoordinator(
      context: context,
      interactions: interactions.stream,
      initialInteraction: () => initial,
      resolvers: [_Resolver()],
      isRegisteredRoute: (path) => path == '/detail',
      navigate: navigated.add,
      schedule: schedule ?? scheduleMicrotask,
      onError: onError,
    );
    addTearDown(coordinator.dispose);
    return coordinator;
  }

  setUp(() {
    context = _Context();
    interactions = StreamController.broadcast(sync: true);
    navigated = [];
    addTearDown(context.changes.close);
    addTearDown(interactions.close);
  });

  test('cold start waits for context AND local verification, deduplicates warm delivery', () async {
    final coordinator = build(initial: _event('one'))
      ..start()
      ..start();
    await _flush();
    expect(navigated, isEmpty);
    context.update(_context('session'));
    await _flush();
    expect(navigated, isEmpty);
    interactions.add(_event('one'));
    coordinator.setReady(true);
    await _flush();
    expect(navigated.map((target) => target.arguments), ['one']);
    interactions.add(_event('one'));
    await _flush();
    expect(navigated, hasLength(1));
  });

  test(
    'malformed, external, unknown, and cross-company targets never navigate',
    () async {
      context.update(_context('session'));
      final errors = <Object>[];
      final coordinator = build(onError: (_, error, _) => errors.add(error))
        ..start()
        ..setReady(true);
      interactions.add(
        NotificationInteraction(id: 'bad', data: {'invalid': true}),
      );
      interactions.add(NotificationInteraction(id: 'missing'));
      interactions.add(_event('unknown', route: '/legacy'));
      interactions.add(
        _event('external', route: 'https://elsewhere.test/detail'),
      );
      interactions.add(_event('other-tenant', company: 'OTHER'));
      interactions.add(_event('valid'));
      await _flush();
      expect(navigated.map((target) => target.arguments), ['valid']);
      expect(errors, [FormatException]);
      await coordinator.dispose();
    },
  );

  test('switching company discards old pending work and requires verification again', () async {
    context.update(_context('old'));
    final coordinator = build()..start();
    interactions.add(_event('old'));
    context.update(_context('new', company: 'OTHER'));
    coordinator.setReady(true);
    await _flush();
    expect(navigated, isEmpty);
    coordinator.setReady(false);
    interactions.add(_event('new', company: 'OTHER'));
    await _flush();
    expect(navigated, isEmpty);
    coordinator.setReady(true);
    await _flush();
    expect(navigated.map((target) => target.arguments), ['new']);
  });

  test('logout or company change before scheduled navigation blocks the old target', () async {
    final scheduled = <void Function()>[];
    context.update(_context('old'));
    final coordinator = build(schedule: scheduled.add)
      ..start()
      ..setReady(true);
    interactions.add(_event('old'));
    context.update(null);
    scheduled.removeAt(0)();
    expect(navigated, isEmpty);
    context.update(_context('new'));
    coordinator.setReady(true);
    await _flush();
    expect(navigated, isEmpty);
  });

  test(
    'new session cannot inherit readiness even with the same company',
    () async {
      context.update(_context('old'));
      final coordinator = build()
        ..start()
        ..setReady(true);
      context.update(_context('new'));
      interactions.add(_event('new'));
      await _flush();
      expect(navigated, isEmpty);
      coordinator.setReady(true);
      await _flush();
      expect(navigated, hasLength(1));
    },
  );

  test(
    'disposal cancels subscriptions and invalidates scheduled work',
    () async {
      final scheduled = <void Function()>[];
      context.update(_context('session'));
      final coordinator = build(schedule: scheduled.add)
        ..start()
        ..setReady(true);
      interactions.add(_event('one'));
      await coordinator.dispose();
      await coordinator.dispose();
      scheduled.single();
      expect(navigated, isEmpty);
      expect(interactions.hasListener, false);
      expect(context.changes.hasListener, false);
    },
  );

  test('pending queue is bounded while login is pending', () async {
    final coordinator = build()..start();
    for (var i = 0; i < 30; i++) {
      interactions.add(_event('$i'));
    }
    context.update(_context('session'));
    coordinator.setReady(true);
    await _flush();
    expect(navigated, hasLength(16));
    expect(navigated.first.arguments, '14');
  });
}
