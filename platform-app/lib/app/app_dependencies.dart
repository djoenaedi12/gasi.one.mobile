import 'dart:io';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gasione_core_starter/gasione_core_starter.dart';
import 'package:gasione_plugin_business_context/gasione_plugin_business_context.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';

/// Explicit composition root. Core services are shared across app restarts.
class AppDependencies {
  AppDependencies({
    required this.runtime,
    required this.notifications,
    required this.preferences,
    this.savedThemeMode,
    this.initialLocale,
  });

  final AppRuntime runtime;
  final NotificationService notifications;
  final SharedPreferences preferences;
  Map<String, Object?> requestHeaders() => {
    'Device': '${Platform.operatingSystem}/${Platform.operatingSystemVersion}',
    'DeviceId': runtime.deviceId,
    'Version': runtime.info.version,
    'Accept-Language': preferences.getString('language') ?? 'en',
  };
  BusinessContextPlugin createBusinessContextPlugin({
    required ApiClient api,
    void Function(String token)? onPushRegistered,
    void Function(String operation, Object error, StackTrace stack)? onError,
  }) => BusinessContextPlugin(
    api: api,
    runtime: runtime,
    notifications: notifications,
    preferences: preferences,
    baseUrl: () => preferences.getString('url') ?? '',
    language: () => preferences.getString('language') ?? 'en',
    onPushRegistered: onPushRegistered,
    onError: onError,
  );
  // TRANSITION[LEGACY-EPC]: compatibility getter for Config.cameraPreference.
  // Move ownership to the camera/settings capability when its callers migrate.
  String get cameraPreference {
    final saved = preferences.getString('cameraPreference');
    return saved?.isNotEmpty == true
        ? saved!
        : Platform.isIOS
        ? 'inapp'
        : 'system';
  }

  // TRANSITION[LEGACY-UI]: remove type/read with the AdaptiveTheme replacement.
  final AdaptiveThemeMode? savedThemeMode;
  final Locale? initialLocale;
  final navigatorKey = GlobalKey<NavigatorState>();
  Future<void>? _permissionRequest;
  bool _disposed = false;

  static Future<AppDependencies> initialize() async {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await EasyLocalization.ensureInitialized();
    // COMPAT[ANDROID-CA]: preserve supported devices' CA trust. This is not
    // automatically removable when legacy code is retired.
    final certificate = await rootBundle.load('assets/ca/isrgrootx1.pem');
    SecurityContext.defaultContext.setTrustedCertificatesBytes(
      certificate.buffer.asUint8List(
        certificate.offsetInBytes,
        certificate.lengthInBytes,
      ),
    );
    final preferences = await SharedPreferences.getInstance();
    // COMPAT[INSTALLED-DATA]: keep the installed preference backend and keys.
    final storage = CachedPreferencesStorage(preferences);
    final runtime = await AppRuntimeService(storage).load();
    final language = await storage.readString('language');
    // TRANSITION[LEGACY-UI]: read saved mode until the theme replacement migrates it.
    final savedTheme = await AdaptiveTheme.getThemeMode();
    final notifications = FirebaseNotificationService(
      // COMPAT[NOTIFICATION-CHANNEL]: retain the installed channel and its user
      // settings beyond EPC removal; a channel change needs its own migration.
      androidChannel: const AndroidNotificationChannel(
        'your channel id',
        'your channel name',
        description: 'your channel description',
        importance: Importance.max,
      ),
    );
    try {
      await notifications.initializePush(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      return AppDependencies(
        runtime: runtime,
        notifications: notifications,
        preferences: preferences,
        savedThemeMode: savedTheme,
        initialLocale: const ['en', 'id'].contains(language)
            ? Locale(language!)
            : null,
      );
    } catch (_) {
      await notifications.dispose();
      rethrow;
    }
  }

  Future<void> requestNotificationPermission() => _permissionRequest ??=
      notifications.requestPermission().then<void>((_) {});

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await notifications.dispose();
  }
}
