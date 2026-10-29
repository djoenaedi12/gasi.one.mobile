import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasione_core_starter/gasione_core_starter.dart';
import 'package:gasione_plugin_business_context/gasione_plugin_business_context.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _runtime = AppRuntime(
  info: AppInfo(
    appName: 'GASI',
    packageName: 'test.gasi',
    version: '1.2.3',
    buildNumber: '4',
  ),
  deviceId: 'device-1',
  security: DeviceSecurity(unsafeDevice: false, signatureValid: true),
);

Map<String, Object?> get _user => {
  'id': 7,
  'username': 'employee',
  'name': 'Employee',
  'device_id': 'device-1',
  'employee': {'id': 77, 'name': 'Employee', 'code': 'E77'},
  'roles': [
    {
      'menus': [
        {
          'id': 10,
          'name': 'attendance',
          'title': 'Attendance',
          'url': '/module/attendance',
          'sequence': 1,
          'visible': true,
          'module': 'attendance',
          'childs': <Object?>[],
        },
      ],
      'access_rights': [
        {
          'entity': {'name': 'LeaveTransaction'},
          'action': {'name': 'Create'},
        },
      ],
    },
  ],
};

Map<String, Object?> get _license => {
  'license': 'licensed',
  'expiry_date': '2030-01-01',
  'modules': ['attendance', 'leave'],
  'company_code': 'ACME',
  'host_name': 'tenant.test',
};

final class _Api extends ApiClient {
  _Api({this.usersOnDevice = false, this.fcmGate, this.userGate})
    : super(enableRetry: false, enableLogging: false);

  final bool usersOnDevice;
  final Completer<void>? fcmGate;
  final Completer<void>? userGate;
  final requests = <String>[];

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? queryParameters,
    Map<String, Object?>? headers,
    CancelToken? cancelToken,
    bool authenticated = true,
  }) async {
    requests.add('GET $path ${queryParameters ?? const {}}');
    if (path.endsWith('/api/v1/user/get')) {
      await userGate?.future;
      return {'success': true, 'data': _user};
    }
    if (path.endsWith('/api/v1/user')) {
      return {
        'success': true,
        'data': {
          'content': usersOnDevice ? [_user] : <Object?>[],
        },
      };
    }
    if (path.endsWith('/api/v1/license')) {
      return {'success': true, 'data': _license};
    }
    if (path.endsWith('/api/v1/employee/isManager')) {
      return {'success': true, 'data': true};
    }
    if (path.endsWith('/api/v1/parameter/get')) {
      final value = switch (queryParameters?['name']) {
        'SESSION_MOBILE_DEVICE' => 'SINGLE',
        'TIMEZONE' => '+08:00',
        'SHOW_DISABLED_MENU' => '0',
        'SWITCH_ACCOUNT' => '1',
        _ => null,
      };
      return {
        'success': true,
        'data': value == null ? null : {'value': value},
      };
    }
    throw StateError('Unexpected GET $path');
  }

  @override
  Future<Map<String, dynamic>> putJson(
    String path, {
    Map<String, Object?>? data,
    Map<String, Object?>? queryParameters,
    Map<String, Object?>? headers,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    bool authenticated = true,
  }) async {
    requests.add('PUT $path ${queryParameters ?? const {}}');
    if (path.endsWith('/set-fcm')) await fcmGate?.future;
    return {'success': true, 'data': null};
  }

  @override
  void close() {}
}

final class _Push implements PushTokenProvider {
  _Push({this.current});

  final String? current;
  final controller = StreamController<String>.broadcast();

  @override
  Future<String?> getToken() async => current;

  @override
  Stream<String> get tokenRefreshes => controller.stream;
}

Future<BusinessContextPlugin> _plugin({
  required _Api api,
  required _Push push,
  Map<String, Object> installed = const {},
  void Function(String)? onPushRegistered,
}) async {
  SharedPreferences.setMockInitialValues(installed);
  final preferences = await SharedPreferences.getInstance();
  final plugin = BusinessContextPlugin(
    api: api,
    runtime: _runtime,
    notifications: push,
    preferences: preferences,
    baseUrl: () => 'https://tenant.test/epc',
    language: () => 'en',
    onPushRegistered: onPushRegistered,
  );
  addTearDown(() async {
    await plugin.dispose();
    await push.controller.close();
  });
  return plugin;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'loads typed business context and registers the current push token',
    () async {
      final api = _Api();
      final push = _Push(current: 'push-1');
      final registered = <String>[];
      final plugin = await _plugin(
        api: api,
        push: push,
        onPushRegistered: registered.add,
      );

      final context = await plugin.load(
        username: 'employee',
        validateDevice: false,
      );
      await Future<void>.delayed(Duration.zero);

      expect(context.user.name, 'Employee');
      expect(plugin.activeContext!.employee.id, 77);
      expect(plugin.activeContext!.serverTimezone, '+08:00');
      expect(plugin.activeContext!.permits('leavetransaction', 'CREATE'), true);
      final installedContext = plugin.activeContext!;
      plugin.clear();
      expect(plugin.activeContext, isNull);
      expect(installedContext.employee.number, 'E77');
      expect(context.user.menus.single.path, '/module/attendance');
      expect(context.user.hasPermission('LeaveTransaction', 'Create'), isTrue);
      expect(context.license?.modules, contains('attendance'));
      expect(context.serverTimezone, '+08:00');
      expect(context.showDisabledMenu, isFalse);
      expect(context.switchAccountEnabled, isTrue);
      expect(context.isManager, isTrue);
      expect(
        api.requests.where((request) => request.contains('/set-device-id')),
        hasLength(1),
      );
      expect(
        api.requests.where((request) => request.contains('/set-fcm')),
        hasLength(1),
      );
      expect(registered, ['push-1']);
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString('fcmToken'), 'push-1');
    },
  );

  test('clear invalidates an unfinished context load', () async {
    final gate = Completer<void>();
    final plugin = await _plugin(
      api: _Api(userGate: gate),
      push: _Push(),
    );
    final pending = plugin.load(username: 'employee', validateDevice: false);
    final assertion = expectLater(
      pending,
      throwsA(
        isA<ApiException>().having(
          (error) => error.type,
          'type',
          ApiExceptionType.cancelled,
        ),
      ),
    );
    plugin.clear();
    gate.complete();
    await assertion;
    expect(plugin.current, isNull);
    expect(plugin.activeContext, isNull);
  });

  test('single-device mismatch is a typed validation failure', () async {
    final api = _Api(usersOnDevice: true);
    final plugin = await _plugin(api: api, push: _Push());

    await expectLater(
      plugin.load(username: 'employee', validateDevice: true),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'status', 422)
            .having((error) => error.code, 'code', 'DEVICE_NOT_SAME'),
      ),
    );
    expect(
      api.requests.where((request) => request.contains('/set-device-id')),
      isEmpty,
    );
  });

  test(
    'installed license cache is retained without a remote license call',
    () async {
      final api = _Api();
      final plugin = await _plugin(
        api: api,
        push: _Push(),
        installed: const {
          'license': 'cached',
          'expiry_date': '2029-01-01',
          'modules': 'attendance;payroll;',
          'company_code': 'ACME',
          'host_name': 'cached.test',
        },
      );

      final context = await plugin.load(
        username: 'employee',
        validateDevice: false,
      );

      expect(context.license?.value, 'cached');
      expect(context.license?.modules, ['attendance', 'payroll']);
      expect(
        api.requests.where((request) => request.contains('/api/v1/license')),
        isEmpty,
      );
    },
  );

  test(
    'refresh tokens are registered only while a context is active',
    () async {
      final api = _Api();
      final push = _Push();
      final plugin = await _plugin(api: api, push: push);
      plugin.start();
      push.controller.add('before-context');
      await Future<void>.delayed(Duration.zero);
      await plugin.load(username: 'employee', validateDevice: false);
      push.controller.add('after-context');
      await Future<void>.delayed(Duration.zero);

      expect(
        api.requests.any((request) => request.contains('before-context')),
        isFalse,
      );
      expect(
        api.requests.any((request) => request.contains('after-context')),
        isTrue,
      );
    },
  );

  test('an in-flight registration cannot update a cleared context', () async {
    final gate = Completer<void>();
    final api = _Api(fcmGate: gate);
    final registered = <String>[];
    final plugin = await _plugin(
      api: api,
      push: _Push(current: 'stale-token'),
      onPushRegistered: registered.add,
    );
    await plugin.load(username: 'employee', validateDevice: false);
    await Future<void>.delayed(Duration.zero);
    plugin.clear();
    gate.complete();
    await Future<void>.delayed(Duration.zero);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('fcmToken'), isNull);
    expect(registered, isEmpty);
  });
}
