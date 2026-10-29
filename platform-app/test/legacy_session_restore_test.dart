import 'dart:async';
import 'dart:convert';

import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/legacy_epc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasione_core_api/gasione_core_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class _Push implements PushTokenProvider {
  @override
  Future<String?> getToken() async => null;
  @override
  Stream<String> get tokenRefreshes => const Stream.empty();
}

const _runtime = AppRuntime(
  info: AppInfo(
    appName: 'GASI',
    packageName: 'test.gasi',
    version: '1.0.0',
    buildNumber: '1',
  ),
  deviceId: 'installed-device',
  security: DeviceSecurity(unsafeDevice: false, signatureValid: true),
);
Future<LegacyEpcModule> _module() async {
  SharedPreferences.setMockInitialValues({
    'isClient': '1',
    'code': 'ACME',
    'name': 'Acme',
    'url': 'https://tenant.test',
    'client_id': 'client',
    'client_secret': 'secret',
    'isLogin': '1',
    'username': 'employee',
    'access_token': 'token',
    'refresh_token': 'refresh',
    'verificationType': 'PIN',
  });
  return LegacyEpcModule(
    preferences: await SharedPreferences.getInstance(),
    runtime: _runtime,
    notifications: _Push(),
    navigatorKey: GlobalKey<NavigatorState>(),
    language: 'en',
    cameraPreference: 'system',
    directoryUrl: 'https://directory.test',
    directoryToken: () async => 'directory-token',
  );
}

Future<http.Response> _response(http.Request request) async {
  final Object? data;
  if (request.url.path.endsWith('/user/get')) {
    data = {
      'id': 7,
      'username': 'employee',
      'name': 'Employee',
      'roles': <Object?>[],
      'login_failure': 0,
      'enabled': true,
    };
  } else if (request.url.path.endsWith('/parameter/get')) {
    final name = request.url.queryParameters['name'];
    data = {
      'name': name,
      'value': name == 'TIMEZONE'
          ? '+08:00'
          : name == 'SHOW_DISABLED_MENU'
          ? '0'
          : '1',
    };
  } else if (request.url.path.endsWith('/isManager')) {
    data = true;
  } else {
    data = null;
  }
  return http.Response(
    jsonEncode({'success': true, 'message': '', 'data': data}),
    200,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('restores existing context and requires local verification without new plugins', () async {
    final module = await _module();
    addTearDown(module.dispose);
    await http.runWithClient(() async {
      final status = await module.restore();
      expect(status, AuthStatus.verificationRequired);
      expect(Config.user?.username, 'employee');
      expect(Config.serverTimezone, '+08:00');
      expect(Config.showDisabledMenu, false);
      expect(Config.switchAccount, true);
      expect(Config.isManager, true);
    }, () => MockClient(_response));
  });
  test('abandoned restoration cannot reinstall user context', () async {
    final module = await _module();
    final gate = Completer<void>();
    final started = Completer<void>();
    await http.runWithClient(
      () async {
        final pending = module.restore();
        final assertion = expectLater(pending, throwsStateError);
        await started.future;
        module.dispose();
        gate.complete();
        await assertion;
        expect(Config.user, isNull);
      },
      () => MockClient((request) async {
        if (request.url.path.endsWith('/user/get')) {
          started.complete();
          await gate.future;
        }
        return _response(request);
      }),
    );
  });
}
