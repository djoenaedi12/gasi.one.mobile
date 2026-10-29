// TRANSITION[LEGACY-EPC]: this fixture exercises the current EPC/Phoenix shell.
// When it retires, retain equivalent restart/service-disposal coverage against
// the new shell; remove http from dev_dependencies only if no other tests use it.
import 'dart:async';
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasione/app/app.dart';
import 'package:gasione/app/app_dependencies.dart';
import 'package:gasione_core_starter/gasione_core_starter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Notifications extends Fake implements NotificationService {
  final tokens = StreamController<String>.broadcast();
  int permissions = 0;
  int disposals = 0;

  @override
  Stream<String> get tokenRefreshes => tokens.stream;
  @override
  Future<String?> getToken() async => 'fixture-token';
  @override
  Future<AppNotificationPermissionStatus> requestPermission() async {
    permissions++;
    return AppNotificationPermissionStatus.authorized;
  }

  @override
  Future<void> dispose() async {
    disposals++;
    await tokens.close();
  }
}

Future<void> _mockLegacyTranslations(WidgetTester tester) async {
  final logo = await tester.runAsync(
    () => rootBundle.load('assets/img/logo.png'),
  );
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  // The production locale files exceed Flutter's isolate-decoding threshold.
  // Keep this routing fixture small and synchronous inside the fake test clock.
  messenger.setMockMessageHandler('flutter/assets', (message) async {
    final key = utf8.decode(
      message!.buffer.asUint8List(message.offsetInBytes, message.lengthInBytes),
    );
    if (key == 'assets/img/logo.png') return logo;
    if (key == 'AssetManifest.bin') {
      return const StandardMessageCodec().encodeMessage(<String, Object?>{});
    }
    if (key.endsWith('.json')) {
      return ByteData.sublistView(
        Uint8List.fromList(
          utf8.encode(
            jsonEncode({
              'Welcome to': 'Welcome to {companyName}',
              'Forgot Password': 'Forgot Password',
              'Username': 'Username',
              'Password': 'Password',
              'Sign In': 'Sign In',
            }),
          ),
        ),
      );
    }
    return null;
  });
  for (final key in [
    'assets/i18n/en.json',
    'assets/i18n/id.json',
    'AssetManifest.bin',
  ]) {
    rootBundle.evict(key);
  }
  addTearDown(() {
    messenger.setMockMessageHandler('flutter/assets', null);
    for (final key in [
      'assets/i18n/en.json',
      'assets/i18n/id.json',
      'AssetManifest.bin',
    ]) {
      rootBundle.evict(key);
    }
  });
}

void main() {
  testWidgets(
    'soft restart reuses host services, navigator, and updated preferences',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'language': 'en',
        'cameraPreference': 'system',
      });
      await EasyLocalization.ensureInitialized();
      await _mockLegacyTranslations(tester);
      final preferences = await SharedPreferences.getInstance();
      final notifications = _Notifications();
      final dependencies = AppDependencies(
        runtime: const AppRuntime(
          info: AppInfo(
            appName: 'GASI',
            packageName: 'test.gasi',
            version: '1.2.3',
            buildNumber: '4',
          ),
          deviceId: 'existing-device',
          security: DeviceSecurity(unsafeDevice: false, signatureValid: true),
        ),
        notifications: notifications,
        preferences: preferences,
        initialLocale: const Locale('en'),
      );
      await http.runWithClient(
        () async {
          await tester.pumpWidget(GasioneApp(dependencies: dependencies));
          await tester.pumpAndSettle();
          expect(find.byType(MaterialApp), findsOneWidget);
          expect(dependencies.navigatorKey.currentState, isNotNull);
          expect(notifications.permissions, 1);
          expect(notifications.disposals, 0);
          await preferences.setString('cameraPreference', 'inapp');
          Phoenix.rebirth(tester.element(find.byType(Scaffold).first));
          await tester.pumpAndSettle();
          expect(find.byType(MaterialApp), findsOneWidget);
          expect(dependencies.navigatorKey.currentState, isNotNull);
          expect(dependencies.cameraPreference, 'inapp');
          expect(notifications.permissions, 1);
          expect(notifications.disposals, 0);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
          expect(notifications.disposals, 1);
          expect(tester.takeException(), isNull);
        },
        () => MockClient((request) async {
          final data = request.url.path.endsWith('/oauth/token')
              ? <String, Object>{
                  'access_token': 'fixture-access',
                  'refresh_token': 'fixture-refresh',
                  'token_type': 'bearer',
                  'scope': '',
                  'username': 'fixture',
                }
              : <String, Object>{'success': true, 'data': '1.2.3'};
          return http.Response(jsonEncode(data), 200);
        }),
      );
    },
  );
}
