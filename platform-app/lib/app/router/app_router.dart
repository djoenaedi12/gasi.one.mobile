import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gasione/app/home/home_page.dart';
import 'package:gasione/app/plugin_registry.dart';
import 'package:gasione/app/router/pages/unknown_route_page.dart';
import 'package:gasione_plugin_auth/gasione_plugin_auth.dart';
import 'package:go_router/go_router.dart';

abstract final class AppRoutes {
  static const home = '/home';
}

class AppRouter {
  AppRouter({
    required AuthPlugin authPlugin,
    required PluginRegistry pluginRegistry,
  }) : _authCubit = authPlugin.authCubit,
       _pluginRegistry = pluginRegistry {
    pluginRegistry.validateReservedPaths([
      AppRoutes.home,
      ...authPlugin.routes.map((route) => route.path),
    ]);
    _refreshListenable = _RouterRefreshListenable(
      authPlugin.authCubit.stream,
      pluginRegistry,
    );
    router = GoRouter(
      initialLocation: _authCubit.state is AuthAuthenticated
          ? AppRoutes.home
          : AuthRoutes.login,
      refreshListenable: _refreshListenable,
      redirect: _redirect,
      routes: [
        ...authPlugin.routes.map((route) => route.toGoRoute()),
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => HomePage(pluginRegistry: pluginRegistry),
        ),
        ...pluginRegistry.routes.map((route) => route.toGoRoute()),
      ],
      errorBuilder: (context, state) =>
          UnknownRoutePage(routeName: state.uri.toString()),
    );
  }

  final AuthCubit _authCubit;
  final PluginRegistry _pluginRegistry;
  late final _RouterRefreshListenable _refreshListenable;
  late final GoRouter router;

  String? _redirect(BuildContext context, GoRouterState state) {
    final isAuthenticated = _authCubit.state is AuthAuthenticated;
    final isOpeningLogin = state.matchedLocation == AuthRoutes.login;

    if (!isAuthenticated) {
      return isOpeningLogin ? null : AuthRoutes.login;
    }
    if (isOpeningLogin) {
      return AppRoutes.home;
    }
    if (!_pluginRegistry.isLocationEnabled(state.matchedLocation)) {
      return AppRoutes.home;
    }
    return null;
  }

  void dispose() {
    router.dispose();
    _refreshListenable.dispose();
  }
}

class _RouterRefreshListenable extends ChangeNotifier {
  _RouterRefreshListenable(Stream<Object?> stream, this._plugins) {
    _subscription = stream.listen((_) => notifyListeners());
    _plugins.addListener(_onPluginsChanged);
  }

  late final StreamSubscription<Object?> _subscription;
  final PluginRegistry _plugins;

  void _onPluginsChanged() => notifyListeners();

  @override
  void dispose() {
    _plugins.removeListener(_onPluginsChanged);
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
