import 'dart:async';

// TRANSITION[LEGACY-UI]: preserve legacy page APIs until all callers migrate.
// See docs/migration-cleanup.md before removing these imports/wrappers.
import 'package:easy_localization/easy_localization.dart';
// TRANSITION[LEGACY-EPC]: sole host import of the temporary EPC integration.
import 'package:epeoplecare/legacy_epc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:gasione_core_starter/gasione_core_starter.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';

import 'app_dependencies.dart';
import 'app_entry_page.dart';
import 'device_access_gate.dart';
import 'notification_navigation_coordinator.dart';
import 'plugin_composition.dart';

/// The host owns the application shell; features provide pages and routes.
class GasioneApp extends StatefulWidget {
  const GasioneApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<GasioneApp> createState() => _GasioneAppState();
}

class _GasioneAppState extends State<GasioneApp> {
  @override
  void dispose() {
    unawaited(widget.dependencies.dispose());
    super.dispose();
  }

  @override
  // TRANSITION[LEGACY-UI]: replace localization/restart wrappers after their
  // consumers migrate; GasioneApp and shared-service disposal remain permanent.
  Widget build(BuildContext context) => DeviceAccessGate(
    security: widget.dependencies.runtime.security,
    locale: widget.dependencies.initialLocale,
    child: EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('id')],
      path: 'assets/i18n',
      startLocale: widget.dependencies.initialLocale,
      fallbackLocale: const Locale('en'),
      child: Phoenix(child: _AppShell(dependencies: widget.dependencies)),
    ),
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
  late final PluginComposition _composition;
  late final NotificationNavigationCoordinator _notificationNavigation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_legacy != null) return;
    _connectLegacyFeatures();
    _configureSessionExpiry();
    _startBackgroundServicesAfterFirstFrame();
  }

  // This is the only composition boundary that knows the legacy implementation.
  void _connectLegacyFeatures() {
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
      onAuthenticatedAreaReady: _authenticatedAreaReady,
    )..addListener(_refreshSessionContext);
    final legacy = _legacy!;
    _api = ApiClient(
      tokenStorage: InstalledTokenStorage(dependencies.preferences),
      refreshTokens: refreshLegacyTokens,
      enableLogging: false,
    );
    final requestApi = RequestApi(
      client: _api,
      context: legacy,
      headers: dependencies.requestHeaders,
    );
    _composition = PluginComposition(
      plugins: dependencies.createPlugins?.call() ?? const [],
      pageRoutes: legacy.authPageRoutes,
      pickers: RequestPickerContributor(
        ApiRequestReferenceRepository(requestApi),
      ).pickers,
      fallback: buildLegacyRoute,
    );
    _notificationNavigation = NotificationNavigationCoordinator(
      context: legacy,
      interactions: dependencies.notifications.interactions,
      initialInteraction: dependencies.notifications.getInitialInteraction,
      resolvers: _composition.notificationResolvers,
      isRegisteredRoute: _composition.routes.containsPath,
      navigate: (destination) {
        unawaited(
          dependencies.navigatorKey.currentState?.pushNamed<void>(
            destination.route,
            arguments: destination.arguments,
          ),
        );
      },
      schedule: (callback) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) callback();
        });
        WidgetsBinding.instance.ensureVisualUpdate();
      },
      onError: _reportIssue,
    );
  }

  void _configureSessionExpiry() {
    _api.setSessionExpiredHandler(() async {
      _notificationNavigation.setReady(false);
      _legacy!.clearSessionContext();
      if (mounted) {
        unawaited(
          widget.dependencies.navigatorKey.currentState
              ?.pushNamedAndRemoveUntil<void>('/auth/login', (_) => false),
        );
      }
    });
  }

  // Update checks, token refresh and notification permission do not choose
  // the first page. AppEntryPage alone restores the session and chooses it.
  void _startBackgroundServicesAfterFirstFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _legacy!.start();
      _notificationNavigation.start();
      unawaited(
        _composition.start().catchError(
          (Object error, StackTrace stack) =>
              _reportIssue('plugin_start', error, stack),
        ),
      );
      unawaited(
        widget.dependencies.requestNotificationPermission().catchError(
          (Object error, StackTrace stack) =>
              _reportIssue('notification_permission', error, stack),
        ),
      );
    });
  }

  String? _sessionId;
  bool _refreshQueued = false;
  void _refreshSessionContext() {
    if (!mounted) return;
    final current = _legacy!.activeContext?.sessionId;
    if (current != _sessionId) {
      _sessionId = current;
      _notificationNavigation.setReady(false);
      final version = _api.sessionStore.beginSession();
      // TRANSITION[LEGACY-SESSION]: legacy persists credentials before publishing
      // its context. Adopt that snapshot through the shared serialized owner.
      final preferences = widget.dependencies.preferences;
      final access = preferences.getString('access_token');
      final refresh = preferences.getString('refresh_token');
      if (current != null && access != null && refresh != null) {
        unawaited(
          _api.sessionStore
              .saveTokens(
                version: version,
                accessToken: access,
                refreshToken: refresh,
              )
              .then<void>((_) {})
              .catchError(
                (Object error, StackTrace stack) =>
                    _reportIssue('session_sync', error, stack),
              ),
        );
      }
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

  void _authenticatedAreaReady() {
    if (!mounted) return;
    _refreshSessionContext();
    _notificationNavigation.setReady(true);
  }

  @override
  void dispose() {
    unawaited(_notificationNavigation.dispose());
    unawaited(
      _composition
          .dispose()
          .whenComplete(_api.close)
          .catchError(
            (Object error, StackTrace stack) =>
                _reportIssue('plugin_dispose', error, stack),
          ),
    );
    _legacy?.removeListener(_refreshSessionContext);
    _legacy?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TRANSITION[LEGACY-EPC]: replace module-supplied home/routes.
    // Keep the platform MaterialApp, navigator, localization, and service owner.
    final legacy = _legacy!;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: widget.dependencies.navigatorKey,
      localizationsDelegates: [
        ...context.localizationDelegates,
        ..._composition.localizationsDelegates,
        RequestLocalizations.delegate,
        AppLocalizations.delegate,
      ],
      supportedLocales: {
        ...context.supportedLocales,
        ..._composition.supportedLocales,
      },
      locale: context.locale,
      theme: AppTheme.light(),
      home: AppEntryPage(
        auth: legacy,
        appVersion: widget.dependencies.runtime.info.version,
        buildDestination: (_, status) => legacy.buildEntryPage(status),
        onError: _reportIssue,
      ),
      builder: (context, child) => SafeArea(
        bottom: true,
        top: false,
        child: PickerScope(
          launcher: _composition.pickers,
          child: AppLoading.init()(context, child),
        ),
      ),
      onGenerateRoute: _composition.routes.call,
      navigatorObservers: [_ContextObserver(_refreshSessionContext)],
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
