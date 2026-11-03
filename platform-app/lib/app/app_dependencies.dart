import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gasione_core_starter/gasione_core_starter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';

/// Shared services created before the application shell can open.
/// Read [initialize] for the startup order; session restore happens afterwards
/// in AppEntryPage. These instances survive a legacy soft restart.
class AppDependencies {
  AppDependencies({
    required this.runtime,
    required this.notifications,
    required this.preferences,
    this.initialLocale,
    this.createPlugins,
  });

  /// Fresh plugin instances for each shell, including a legacy soft restart.
  final List<AppPlugin> Function()? createPlugins;
  final AppRuntime runtime;
  final NotificationService notifications;
  final SharedPreferences preferences;
  Map<String, Object?> requestHeaders() => {
    'Device': '${Platform.operatingSystem}/${Platform.operatingSystemVersion}',
    'DeviceId': runtime.deviceId,
    'Version': runtime.info.version,
    'Accept-Language': preferences.getString('language') ?? 'en',
  };
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

  final Locale? initialLocale;
  final navigatorKey = GlobalKey<NavigatorState>();
  Future<void>? _permissionRequest;
  bool _disposed = false;

  static Future<AppDependencies> initialize() async {
    // 1. Prepare native/UI prerequisites before reading application state.
    await _preparePlatform();

    // 2. Open the existing storage backend; retain installed keys and device ID.
    final preferences = await SharedPreferences.getInstance();
    final storage = CachedPreferencesStorage(preferences);

    // 3. Read app/device information and evaluate device security.
    // The host checks this result before creating the feature shell.
    final runtime = await AppRuntimeService(storage).load();

    // 4. Read presentation settings without restoring a user session yet.
    final initialLocale = _readSavedLocale(preferences);

    // 5. Prepare shared push services. Permission is requested by the shell.
    final notifications = await _initializeNotifications();

    return AppDependencies(
      runtime: runtime,
      notifications: notifications,
      preferences: preferences,
      initialLocale: initialLocale,
    );
  }

  static Future<void> _preparePlatform() async {
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
  }

  static Locale? _readSavedLocale(SharedPreferences preferences) {
    final language = preferences.getString('language');
    return const ['en', 'id'].contains(language) ? Locale(language!) : null;
  }

  static Future<NotificationService> _initializeNotifications() async {
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
      return notifications;
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
