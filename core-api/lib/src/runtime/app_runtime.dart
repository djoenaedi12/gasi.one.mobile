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

/// Observations from native checks, before any access policy is applied.
class DeviceSecurityReport {
  const DeviceSecurityReport({
    required this.jailbroken,
    required this.realDevice,
    required this.developmentMode,
    required this.externalStorage,
    required this.signatureValid,
  });

  final bool jailbroken;
  final bool realDevice;
  final bool developmentMode;
  final bool externalStorage;
  final bool signatureValid;
}

/// Policy result consumed by the host and temporary legacy adapters.
class DeviceSecurity {
  const DeviceSecurity({
    required this.unsafeDevice,
    required this.signatureValid,
    this.report,
  });

  final bool unsafeDevice;
  final bool signatureValid;

  /// Native observations for explaining which requirements were not met.
  /// Older adapters may supply only the aggregate result.
  final DeviceSecurityReport? report;
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
