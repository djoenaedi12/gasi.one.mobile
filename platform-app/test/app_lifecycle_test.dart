// TRANSITION[LEGACY-EPC]: this fixture exercises the current EPC/Phoenix shell.
// When it retires, retain equivalent restart/service-disposal coverage against
// the new shell; remove http from dev_dependencies only if no other tests use it.
import 'dart:async';
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/view/auth/client_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasione/app/app.dart';
import 'package:gasione/app/app_dependencies.dart';
import 'package:gasione/app/startup_gate.dart';
import 'package:gasione_core_starter/gasione_core_starter.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Notifications extends Fake implements NotificationService {
  final tokens = StreamController<String>.broadcast();
  @override
  Stream<NotificationInteraction> get interactions => const Stream.empty();
  @override
  NotificationInteraction? getInitialInteraction() => null;
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
    if (key == 'assets/img/logo.png' ||
        key == 'packages/gasione_core_ui/assets/branding/logo.png') {
      return logo;
    }
    if (key == 'AssetManifest.bin') {
      return const StandardMessageCodec().encodeMessage(<String, Object?>{});
    }
    if (key.endsWith('.json')) {
      final indonesian = key.endsWith('/id.json');
      return ByteData.sublistView(
        Uint8List.fromList(
          utf8.encode(
            jsonEncode({
              'Welcome to e-PeopleCare': indonesian
                  ? 'Selamat datang di e-PeopleCare'
                  : 'Welcome to e-PeopleCare',
              'Please Sign In With Your Company Code': indonesian
                  ? 'Silakan masuk dengan kode perusahaan Anda'
                  : 'Please Sign In With Your Company Code',
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
    'blocked device never creates legacy shell or starts its services',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
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
          security: DeviceSecurity(unsafeDevice: true, signatureValid: true),
        ),
        notifications: notifications,
        preferences: await SharedPreferences.getInstance(),
        initialLocale: const Locale('en'),
      );
      await http.runWithClient(
        () async {
          await tester.pumpWidget(GasioneApp(dependencies: dependencies));
          await tester.pumpAndSettle();
          expect(
            find.text('Device Does Not Meet Security Standard'),
            findsOneWidget,
          );
          final blockedContext = tester.element(find.byType(Scaffold));
          expect(Theme.of(blockedContext).brightness, Brightness.light);
          expect(
            Theme.of(blockedContext).colorScheme.primary,
            AppColors.light.primary,
          );
          expect(find.byType(ClientPage), findsNothing);
          expect(dependencies.navigatorKey.currentState, isNull);
          expect(notifications.permissions, 0);
          expect(notifications.tokens.hasListener, false);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
          expect(notifications.disposals, 1);
          expect(tester.takeException(), isNull);
        },
        () => MockClient(
          (_) => throw StateError('Blocked app started an API call'),
        ),
      );
    },
  );

  for (final language in ['en', 'id']) {
    testWidgets(
      'soft restart retains light core theme and language $language',
      (tester) async {
        tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        SharedPreferences.setMockInitialValues({
          'language': language,
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
          initialLocale: Locale(language),
        );
        await http.runWithClient(
          () async {
            final services = Completer<AppDependencies>();
            var initializationCalls = 0;
            await tester.pumpWidget(
              StartupGate<AppDependencies>(
                initialize: () {
                  initializationCalls++;
                  return services.future;
                },
                disposeValue: (value) => value.dispose(),
                builder: (value) => GasioneApp(dependencies: value),
              ),
            );
            expect(find.byType(ClientPage), findsNothing);
            services.complete(dependencies);
            await tester.pump(const Duration(seconds: 2));
            await tester.pumpAndSettle();
            expect(find.byType(ClientPage), findsOneWidget);
            final pageTheme = Theme.of(tester.element(find.byType(ClientPage)));
            expect(pageTheme.colorScheme.primary, AppColors.light.primary);
            expect(pageTheme.primaryColor, AppColors.light.primary);
            expect(
              pageTheme.scaffoldBackgroundColor,
              AppColors.light.background,
            );
            expect(pageTheme.extension<AppSemanticColors>(), isNotNull);
            expect(pageTheme.brightness, Brightness.light);
            expect(
              Localizations.localeOf(tester.element(find.byType(ClientPage)))
                  .languageCode,
              language,
            );
            expect(
              find.text(
                language == 'id'
                    ? 'Selamat datang di e-PeopleCare'
                    : 'Welcome to e-PeopleCare',
              ),
              findsOneWidget,
            );
            expect(initializationCalls, 1);
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
            final restartedTheme = Theme.of(
              tester.element(find.byType(ClientPage)),
            );
            expect(restartedTheme.brightness, Brightness.light);
            expect(
              Localizations.localeOf(tester.element(find.byType(ClientPage)))
                  .languageCode,
              language,
            );
            expect(restartedTheme.colorScheme.primary, AppColors.light.primary);
            expect(find.byType(ClientPage), findsOneWidget);
            expect(initializationCalls, 1);
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
}
