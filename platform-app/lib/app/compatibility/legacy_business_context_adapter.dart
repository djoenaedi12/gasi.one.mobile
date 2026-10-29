// TRANSITION[LEGACY-BUSINESS-CONTEXT]: this is the only platform mapping from
// BusinessContext into the public EPC compatibility bridge. Remove it together
// with LegacyBusinessContextBridge after Home no longer reads Config.
import 'package:epeoplecare/legacy_epc.dart';
import 'package:gasione_plugin_business_context/gasione_plugin_business_context.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class LegacyBusinessContextAdapter {
  LegacyBusinessContextAdapter(
    SharedPreferences preferences,
    void Function() onChanged,
  ) : _bridge = LegacyBusinessContextBridge(preferences, onChanged);

  final LegacyBusinessContextBridge _bridge;

  Future<LegacyInstalledBusinessState> restoreInstalledState() =>
      _bridge.restoreInstalledState();

  void install(BusinessContext context) {
    final license = context.license;
    _bridge.install(
      userPayload: context.user.compatibilityPayload,
      license: license == null
          ? null
          : LegacyLicenseSnapshot(
              value: license.value,
              expiryDate: license.expiryDate,
              modules: license.modules,
              companyCode: license.companyCode,
              hostName: license.hostName,
            ),
      serverTimezone: context.serverTimezone,
      showDisabledMenu: context.showDisabledMenu,
      switchAccountEnabled: context.switchAccountEnabled,
      isManager: context.isManager,
    );
  }

  void installPushToken(String token) => _bridge.installPushToken(token);
}
