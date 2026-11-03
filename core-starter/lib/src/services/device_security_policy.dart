import 'package:gasione_core_api/gasione_core_api.dart';

/// Preserves the installed EPC rules without depending on native plugins or UI.
class DeviceSecurityPolicy {
  const DeviceSecurityPolicy();

  DeviceSecurity evaluate(DeviceSecurityReport report) => DeviceSecurity(
    unsafeDevice:
        report.jailbroken ||
        !report.realDevice ||
        report.developmentMode ||
        report.externalStorage,
    signatureValid: report.signatureValid,
    report: report,
  );
}
