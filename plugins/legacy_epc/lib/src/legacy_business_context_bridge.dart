// TRANSITION[LEGACY-BUSINESS-CONTEXT]: isolates all Config/model/provider access
// required by the new business-context integration. Remove this entire bridge
// after Home and remaining EPC pages consume the new context directly.
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/license.dart';
import 'package:epeoplecare/model/user.dart';
import 'package:epeoplecare/model/verification_type.dart';
import 'package:epeoplecare/provider/appearance_setting_provider.dart';
import 'package:epeoplecare/provider/client_provider.dart';
import 'package:epeoplecare/provider/enum_provider.dart';
import 'package:epeoplecare/provider/session_provider.dart';
import 'package:epeoplecare/provider/string_provider.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:flutter/material.dart';
import 'package:gasione_core_api/gasione_core_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'legacy_auth_transport.dart';

final class LegacyInstalledBusinessState {
  const LegacyInstalledBusinessState({
    required this.hasCompany,
    required this.username,
    required this.verificationConfigured,
  });

  final bool hasCompany;
  final String? username;
  final bool verificationConfigured;
}

final class LegacyLicenseSnapshot {
  const LegacyLicenseSnapshot({
    required this.value,
    required this.expiryDate,
    required this.modules,
    required this.companyCode,
    required this.hostName,
  });

  final String value;
  final String expiryDate;
  final List<String> modules;
  final String companyCode;
  final String hostName;
}

final class LegacyBusinessContextBridge {
  LegacyBusinessContextBridge(this._preferences, this._onChanged);

  final SharedPreferences _preferences;
  final VoidCallback _onChanged;

  Future<LegacyInstalledBusinessState> restoreInstalledState() async {
    Config.client = null;
    Config.session = null;
    Config.user = null;
    Config.verificationType = null;
    Config.license = null;
    Config.serverTimezone = '+07:00';
    Config.showDisabledMenu = true;
    Config.switchAccount = false;
    Config.isManager = false;
    Config.fcmToken = _preferences.getString('fcmToken') ?? '';

    final verification = _preferences.getString('verificationType');
    if (verification != null && verification.isNotEmpty) {
      Config.verificationType = EnumProvider.fromString(
        VerificationType.values,
        verification,
      );
    }

    if (_preferences.getString('isClient') != '1') {
      Config.appearanceSetting = null;
      Config.DEFAULT_COLOR = const Color(0xFF1E88E5);
      Config.DEFAULT_ACCENT_COLOR = Colors.white;
      _onChanged();
      return LegacyInstalledBusinessState(
        hasCompany: false,
        username: null,
        verificationConfigured: Config.verificationType != null,
      );
    }

    final appearance = await AppearanceSettingProvider().getAppearanceSetting();
    var client = await ClientProvider().getClient('');
    if (client == null) {
      _onChanged();
      return LegacyInstalledBusinessState(
        hasCompany: false,
        username: null,
        verificationConfigured: Config.verificationType != null,
      );
    }
    client = await repairLegacyCompany(client);
    Config.appearanceSetting = appearance;
    Config.client = client;
    Config.DEFAULT_COLOR =
        StringProvider.hexToColor(appearance?.colorMobile ?? '') ??
        const Color(0xFF1E88E5);
    Config.DEFAULT_ACCENT_COLOR =
        StringProvider.hexToColor(appearance?.accentColorMobile ?? '') ??
        Colors.white;
    await Repository().initData();

    if (!await SessionProvider().isLogin()) {
      _onChanged();
      return LegacyInstalledBusinessState(
        hasCompany: true,
        username: null,
        verificationConfigured: Config.verificationType != null,
      );
    }
    final session = await SessionProvider().getSession('');
    Config.session = session;
    _onChanged();
    return LegacyInstalledBusinessState(
      hasCompany: true,
      username: session?.username,
      verificationConfigured: Config.verificationType != null,
    );
  }

  void install({
    required Map<String, dynamic> userPayload,
    required LegacyLicenseSnapshot? license,
    required String serverTimezone,
    required bool showDisabledMenu,
    required bool switchAccountEnabled,
    required bool isManager,
  }) {
    final user = User.fromJson(userPayload);
    if (user == null) throw StateError('Legacy user mapping failed.');
    Config.user = user;
    Config.license = license == null
        ? null
        : License(
            license.value,
            license.expiryDate,
            [...license.modules],
            license.companyCode,
            license.hostName,
          );
    Config.serverTimezone = serverTimezone;
    Config.showDisabledMenu = showDisabledMenu;
    Config.switchAccount = switchAccountEnabled;
    Config.isManager = isManager;
    _onChanged();
  }

  void installPushToken(String token) {
    Config.fcmToken = token;
  }
}

/// TRANSITION[LEGACY-BUSINESS-CONTEXT]: migrate readers to the plugin provider
/// after legacy login/settings no longer mutate Config directly.
ActiveBusinessContext? legacyActiveContext(String sessionId) {
  final company = Config.client;
  final user = Config.user;
  final employee = user?.employee;
  if (company == null ||
      user == null ||
      employee?.id == null ||
      Config.session == null) {
    return null;
  }
  final permissions = <BusinessAccess>{};
  for (final role in user.roles) {
    for (final right in role.accessRights) {
      if (right.entity != null && right.action != null) {
        permissions.add(BusinessAccess(right.entity!.name, right.action!.name));
      }
    }
  }
  return ActiveBusinessContext(
    company: CompanyIdentity(code: company.code, baseUrl: company.url),
    employee: EmployeeIdentity(
      id: employee!.id!,
      name: employee.name,
      number: employee.code,
    ),
    username: user.username,
    serverTimezone: Config.serverTimezone,
    isManager: Config.isManager,
    permissions: permissions,
    sessionId: sessionId,
  );
}
