import 'dart:async';

// TRANSITION[LEGACY-UI]: preserve legacy page APIs until all callers migrate.
// See docs/migration-cleanup.md before removing these imports/wrappers.
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:easy_localization/easy_localization.dart';
// TRANSITION[LEGACY-EPC]: sole host import of the temporary EPC integration.
import 'package:epeoplecare/legacy_epc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:gasione_core_starter/gasione_core_starter.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';

import 'app_dependencies.dart';
import 'app_entry_page.dart';
import 'app_theme.dart';
import 'plugin_route_bridge.dart';

/// The host owns the application shell; features provide pages and routes.
class GasioneApp extends StatefulWidget {
  const GasioneApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<GasioneApp> createState() => _GasioneAppState();
}

class _GasioneAppState extends State<GasioneApp> {
  @override
  void initState() {
    super.initState();
    // TRANSITION[LEGACY-UI]: remove when legacy EasyLoading callers are replaced.
    EasyLoading.instance
      ..indicatorType = EasyLoadingIndicatorType.fadingCircle
      ..loadingStyle = EasyLoadingStyle.light
      ..maskType = EasyLoadingMaskType.black
      ..userInteractions = false
      ..dismissOnTap = false;
  }

  @override
  void dispose() {
    unawaited(widget.dependencies.dispose());
    super.dispose();
  }

  @override
  // TRANSITION[LEGACY-UI]: replace localization/restart wrappers after their
  // consumers migrate; GasioneApp and shared-service disposal remain permanent.
  Widget build(BuildContext context) => EasyLocalization(
    supportedLocales: const [Locale('en'), Locale('id')],
    path: 'assets/i18n',
    startLocale: widget.dependencies.initialLocale,
    fallbackLocale: const Locale('en'),
    child: Phoenix(child: _AppShell(dependencies: widget.dependencies)),
  );
}

class _AppShell extends StatefulWidget {
  const _AppShell({required this.dependencies});
  final AppDependencies dependencies;

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  // TRANSITION[LEGACY-EPC]: module creation, startup, listeners, and disposal
  // retire together once the new plugins own these responsibilities.
  LegacyEpcModule? _legacy;
  late final ApiClient _api;
  late final AuthRestorer _restorer;
  late final PluginRouteBridge _routes;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_legacy != null) return;
    final dependencies = widget.dependencies;
    _legacy = LegacyEpcModule(
      preferences: dependencies.preferences,
      runtime: dependencies.runtime,
      notifications: dependencies.notifications,
      navigatorKey: dependencies.navigatorKey,
      language: context.locale.languageCode,
      cameraPreference: dependencies.cameraPreference,
      directoryUrl: legacyDirectoryUrl,
      directoryToken: legacyDirectoryToken,
      onError: _reportIssue,
    )..addListener(_refreshTheme);
    final legacy = _legacy!;
    _api = ApiClient(
      tokenStorage: InstalledTokenStorage(dependencies.preferences),
      refreshTokens: refreshLegacyTokens,
      enableLogging: false,
    );
    _restorer = _CallbackRestorer(legacy.restore);
    _routes = PluginRouteBridge(
      legacy.authPageRoutes,
      fallback: buildLegacyRoute,
    );
    _api.setSessionExpiredHandler(() async {
      legacy.clearSessionContext();
      if (mounted) {
        unawaited(
          dependencies.navigatorKey.currentState?.pushNamedAndRemoveUntil<void>(
            '/auth/login',
            (_) => false,
          ),
        );
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _legacy!.start();
      unawaited(
        dependencies.requestNotificationPermission().catchError(
          (Object error, StackTrace stack) =>
              _reportIssue('notification_permission', error, stack),
        ),
      );
    });
  }

  String? _sessionId;
  bool _refreshQueued = false;
  void _refreshTheme() {
    if (!mounted) return;
    final current = _legacy!.activeContext?.sessionId;
    if (current != _sessionId) {
      _sessionId = current;
      _api.sessionStore.beginSession();
    }
    _legacy!.refreshContext();
    if (_refreshQueued) return;
    _refreshQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshQueued = false;
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    _api.close();
    _legacy?.removeListener(_refreshTheme);
    _legacy?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TRANSITION[LEGACY-EPC]: replace module-supplied theme inputs/home/routes.
    // Keep the platform MaterialApp, navigator, localization, and service owner.
    final legacy = _legacy!;
    // TRANSITION[LEGACY-UI]: replace this wrapper when theme consumers migrate.
    return AdaptiveTheme(
      light: buildAppTheme(
        primaryColor: legacy.primaryColor,
        accentColor: legacy.accentColor,
      ),
      initial: widget.dependencies.savedThemeMode ?? AdaptiveThemeMode.light,
      builder: (theme, darkTheme) => MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: widget.dependencies.navigatorKey,
        localizationsDelegates: [
          ...context.localizationDelegates,
          AppLocalizations.delegate,
        ],
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        theme: theme,
        darkTheme: darkTheme,
        home: AppEntryPage(
          auth: _restorer,
          buildDestination: (_, status) => legacy.buildBusinessPage(status),
          onError: _reportIssue,
        ),
        builder: (context, child) => SafeArea(
          bottom: true,
          top: false,
          // TRANSITION[LEGACY-UI]: host overlay for remaining EasyLoading calls.
          child: EasyLoading.init()(context, child),
        ),
        onGenerateRoute: _routes.call,
        navigatorObservers: [_ContextObserver(_refreshTheme)],
      ),
    );
  }
}

void _reportIssue(String operation, Object error, StackTrace stack) {
  // Preserve useful stack diagnostics without logging server payloads or tokens.
  FlutterError.reportError(
    FlutterErrorDetails(
      exception: StateError('$operation failed (${error.runtimeType})'),
      stack: stack,
      library: 'gasione',
    ),
  );
}

final class _CallbackRestorer implements AuthRestorer {
  _CallbackRestorer(this._restore);
  final Future<AuthStatus> Function() _restore;
  Future<AuthStatus>? _pending;
  @override
  Future<AuthStatus> restore() =>
      _pending ??= _restore().whenComplete(() => _pending = null);
}

final class _ContextObserver extends NavigatorObserver {
  _ContextObserver(this.refresh);
  final VoidCallback refresh;
  void _refresh() =>
      WidgetsBinding.instance.addPostFrameCallback((_) => refresh());
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _refresh();
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _refresh();
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _refresh();
}
