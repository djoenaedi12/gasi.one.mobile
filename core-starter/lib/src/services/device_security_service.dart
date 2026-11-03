import 'dart:io';

import 'package:flutter/services.dart';
import 'package:gasione_core_api/gasione_core_api.dart';
import 'package:safe_device/safe_device.dart';

/// Reads native facts. It does not decide access, navigate, or display dialogs.
class DeviceSecurityService {
  Future<DeviceSecurityReport> inspect() async {
    final jailbroken = await SafeDevice.isJailBroken;
    final realDevice = await SafeDevice.isRealDevice;
    final developmentMode = await SafeDevice.isDevelopmentModeEnable;
    final externalStorage = await SafeDevice.isOnExternalStorage;
    final signatureValid =
        !Platform.isAndroid ||
        (await const MethodChannel('app_integrity')
                .invokeMethod<bool>('verifySignature') ??
            false);

    return DeviceSecurityReport(
      jailbroken: jailbroken,
      realDevice: realDevice,
      developmentMode: developmentMode,
      externalStorage: externalStorage,
      signatureValid: signatureValid,
    );
  }
}
