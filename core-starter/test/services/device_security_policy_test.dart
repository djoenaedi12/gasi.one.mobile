import 'package:flutter_test/flutter_test.dart';
import 'package:gasione_core_starter/gasione_core_starter.dart';

DeviceSecurityReport _report({
  bool jailbroken = false,
  bool realDevice = true,
  bool developmentMode = false,
  bool externalStorage = false,
  bool signatureValid = true,
}) => DeviceSecurityReport(
  jailbroken: jailbroken,
  realDevice: realDevice,
  developmentMode: developmentMode,
  externalStorage: externalStorage,
  signatureValid: signatureValid,
);

void main() {
  const policy = DeviceSecurityPolicy();

  test('accepts a physical device meeting all existing requirements', () {
    final report = _report();
    final result = policy.evaluate(report);
    expect(result.unsafeDevice, false);
    expect(result.signatureValid, true);
    expect(result.report, same(report));
  });

  final unsafeReports = {
    'root/jailbreak': _report(jailbroken: true),
    'emulator': _report(realDevice: false),
    'developer mode': _report(developmentMode: true),
    'external storage': _report(externalStorage: true),
  };
  for (final entry in unsafeReports.entries) {
    test('rejects ${entry.key} independently of the other checks', () {
      final result = policy.evaluate(entry.value);
      expect(result.unsafeDevice, true);
      expect(result.signatureValid, true);
    });
  }

  test('retains an invalid signature even on a compliant device', () {
    final result = policy.evaluate(_report(signatureValid: false));
    expect(result.unsafeDevice, false);
    expect(result.signatureValid, false);
  });
}
