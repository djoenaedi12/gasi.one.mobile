import 'dart:io';

import 'package:flutter/services.dart';
import 'package:gasione_core_api/gasione_core_api.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:safe_device/safe_device.dart';
import 'package:uuid/uuid.dart';

import '../storage/preferences_storage.dart';

/// Loads local runtime information; it never calls business APIs.
/// FOUNDATION: metadata, identity, and security service remains after migration.
class AppRuntimeService {
  AppRuntimeService(
    this._preferences, {
    Future<AppInfo> Function()? loadInfo,
    Future<DeviceSecurity> Function()? checkSecurity,
    String Function()? createDeviceId,
  }) : _loadInfo = loadInfo ?? _platformInfo,
       _checkSecurity = checkSecurity ?? _platformSecurity,
       _createDeviceId = createDeviceId ?? const Uuid().v1;

  final PreferencesStorage _preferences;
  final Future<AppInfo> Function() _loadInfo;
  final Future<DeviceSecurity> Function() _checkSecurity;
  final String Function() _createDeviceId;
  Future<AppRuntime>? _loading;

  /// Repeated calls share the same work. A failed load can be retried.
  Future<AppRuntime> load() =>
      _loading ??= _load().catchError((Object error, StackTrace stack) {
        _loading = null;
        Error.throwWithStackTrace(error, stack);
      });

  Future<AppRuntime> _load() async {
    final info = await _loadInfo();
    var deviceId = await _preferences.readString('deviceId');
    if (deviceId == null || deviceId.isEmpty) {
      deviceId = _createDeviceId();
      await _preferences.writeString('deviceId', deviceId);
    }
    final security = await _checkSecurity();
    return AppRuntime(info: info, deviceId: deviceId, security: security);
  }

  static Future<AppInfo> _platformInfo() async {
    final info = await PackageInfo.fromPlatform();
    return AppInfo(
      appName: info.appName,
      packageName: info.packageName,
      version: info.version,
      buildNumber: info.buildNumber,
    );
  }

  static Future<DeviceSecurity> _platformSecurity() async {
    // Preserve the EPC device policy while moving its implementation.
    final jailbroken = await SafeDevice.isJailBroken;
    final realDevice = await SafeDevice.isRealDevice;
    final developmentMode = await SafeDevice.isDevelopmentModeEnable;
    final externalStorage = await SafeDevice.isOnExternalStorage;
    final signatureValid =
        !Platform.isAndroid ||
        (await const MethodChannel('app_integrity')
                .invokeMethod<bool>('verifySignature') ??
            false);
    return DeviceSecurity(
      unsafeDevice:
          jailbroken || !realDevice || developmentMode || externalStorage,
      signatureValid: signatureValid,
    );
  }
}
