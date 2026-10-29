import 'dart:async';

import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/provider/alert_provider.dart';
import 'package:epeoplecare/repository/parameter_repository.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/view/auth/client_page.dart';
import 'package:epeoplecare/view/auth/login_page.dart';
import 'package:epeoplecare/view/home_page.dart';
import 'package:epeoplecare/view/verification/verification_page.dart';
import 'package:epeoplecare/view/verification/verification_setup_page.dart';
import 'package:flutter/material.dart';
import 'package:gasione_core_api/gasione_core_api.dart';

import 'legacy_business_context_bridge.dart';

/// Temporary EPC pages and update policies until their owning plugins migrate.
/// TRANSITION[LEGACY-EPC]: the module is temporary; injected core services stay.
/// Retire duties incrementally according to docs/migration-cleanup.md.
///
/// This module never initializes Firebase, platform services, or an app shell.
/// Metadata and push access reference the instances supplied by the host.
class LegacyEpcModule extends ChangeNotifier
    implements BusinessContextProvider {
  LegacyEpcModule({
    required AppRuntime runtime,
    required PushTokenProvider notifications,
    required GlobalKey<NavigatorState> navigatorKey,
    required String language,
    required String cameraPreference,
    required this._directoryUrl,
    required this._directoryToken,
    this.onError,
  }) {
    Config.runtime = runtime;
    Config.notifications = notifications;
    Config.navigatorKey = navigatorKey;
    Config.language = language;
    Config.cameraPreference = cameraPreference;
  }

  // TRANSITION[LEGACY-UPDATE]: transport callbacks are supplied by the host.
  final String _directoryUrl;
  final Future<String> Function() _directoryToken;
  final void Function(String operation, Object error, StackTrace stack)?
  onError;
  bool _started = false;
  bool _disposed = false;

  final _contextChanges = StreamController<ActiveBusinessContext?>.broadcast();
  Object? _session;
  int _generation = 0;
  @override
  ActiveBusinessContext? get activeContext {
    if (!identical(_session, Config.session)) {
      _session = Config.session;
      _generation++;
    }
    return legacyActiveContext('legacy-$_generation');
  }

  @override
  Stream<ActiveBusinessContext?> get contextChanges => _contextChanges.stream;
  void refreshContext() {
    if (!_disposed) _contextChanges.add(activeContext);
  }

  Color get primaryColor => Config.DEFAULT_COLOR;
  Color get accentColor => Config.DEFAULT_ACCENT_COLOR;

  List<PluginPageRoute> get authPageRoutes => [
    PluginPageRoute(
      path: '/auth/company',
      builder: (_, _) => const ClientPage(),
    ),
    PluginPageRoute(path: '/auth/login', builder: (_, _) => const LoginPage()),
  ];

  void clearSessionContext() {
    Config.session = null;
    Config.user = null;
    Config.license = null;
    refreshContext();
  }

  // TRANSITION[LEGACY-AUTH]: retain installed entry destinations until the
  // Pre-Home CR replaces them with auth-plugin pages.
  Widget buildBusinessPage(AuthStatus status) => switch (status) {
    AuthStatus.companyRequired => const ClientPage(),
    AuthStatus.loginRequired => const LoginPage(),
    AuthStatus.verificationRequired => VerificationPage(
      verificationType: Config.verificationType!,
    ),
    AuthStatus.verificationSetupRequired => const VerificationSetupPage(
      isTwoFactorAuthentication: true,
    ),
    AuthStatus.authenticated => const HomePage(),
  };

  void setLanguage(String language) {
    Config.language = language;
    Repository().setLanguange(language);
  }

  // TRANSITION[LEGACY-ENTRY-NOTICES]: move these policies/dialogs with the
  // remaining pre-Home flows. CompanyPage does not depend on EPC globals.
  void showCompanyNotices() {
    Config.client = null;
    Config.session = null;
    Config.user = null;
    Config.license = null;
    Config.isManager = false;
    Config.switchAccount = false;
    AlertProvider.showUpdateAvailableDialog();
    AlertProvider.showUnSafeDeviceDialog();
    AlertProvider.showSignatureDialog();
  }

  void start() {
    if (_started || _disposed) return;
    _started = true;
    unawaited(_run('update_check', _checkForUpdates));
  }

  /// TRANSITION[LEGACY-BUSINESS-CONTEXT]: called only by the platform adapter
  /// after it updates Config. Remove with that adapter.
  void businessContextChanged() {
    if (!_disposed) {
      refreshContext();
      notifyListeners();
    }
  }

  Future<void> _run(String operation, Future<void> Function() task) async {
    try {
      if (!_disposed) await task();
    } catch (error, stack) {
      if (!_disposed) onError?.call(operation, error, stack);
    }
  }

  // TRANSITION[LEGACY-UPDATE]: replace with the host update service, preserving
  // version policy and rate-limit behavior before retiring this implementation.
  Future<void> _checkForUpdates() async {
    try {
      final token = await _directoryToken();
      if (_disposed) return;
      final version = await ParameterRepository(
        _directoryUrl,
        '',
        '',
        Config.language,
      ).getMobileAppVersion(token);
      if (_disposed || version == null || version.isEmpty) return;
      Config.version = version;
      final available = version.split('.').map(int.tryParse).toList();
      final installed = Config.packageInfo.version
          .split('.')
          .map(int.tryParse)
          .toList();
      if (available.length != 3 ||
          installed.length != 3 ||
          available.contains(null) ||
          installed.contains(null)) {
        return;
      }
      Config.updateAvailable = false;
      for (var index = 0; index < 3; index++) {
        if (available[index]! > installed[index]!) {
          Config.updateAvailable = true;
          break;
        }
        if (available[index]! < installed[index]!) break;
      }
    } catch (error) {
      if (!_disposed && error.toString().contains('429: ')) {
        Config.showRateLimitPopup = true;
      }
      rethrow;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_contextChanges.close());
    super.dispose();
  }
}
