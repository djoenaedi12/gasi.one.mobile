/// Local application metadata, independent of a platform plugin or auth state.
class AppInfo {
  const AppInfo({
    required this.appName,
    required this.packageName,
    required this.version,
    required this.buildNumber,
  });

  final String appName;
  final String packageName;
  final String version;
  final String buildNumber;
}

class DeviceSecurity {
  const DeviceSecurity({
    required this.unsafeDevice,
    required this.signatureValid,
  });

  final bool unsafeDevice;
  final bool signatureValid;
}

/// Created once by the host before any feature sends requests.
/// FOUNDATION: shared runtime contract, retained after legacy migration.
class AppRuntime {
  const AppRuntime({
    required this.info,
    required this.deviceId,
    required this.security,
  });

  final AppInfo info;
  final String deviceId;
  final DeviceSecurity security;
}
