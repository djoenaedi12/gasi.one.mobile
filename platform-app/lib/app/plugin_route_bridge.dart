import 'package:flutter/material.dart';
import 'package:gasione_core_api/gasione_core_api.dart';

/// Resolves compiled plugin contributions before the legacy fallback.
final class PluginRouteBridge {
  PluginRouteBridge(Iterable<PluginPageRoute> contributions, {this.fallback}) {
    for (final route in contributions) {
      if (_routes.containsKey(route.path)) {
        throw ArgumentError('Duplicate plugin route: ${route.path}');
      }
      _routes[route.path] = route;
    }
  }
  final Map<String, PluginPageRoute> _routes = {};
  final Route<dynamic>? Function(RouteSettings)? fallback;
  Route<dynamic>? call(RouteSettings settings) {
    final name = settings.name;
    final route = name == null ? null : _routes[Uri.parse(name).path];
    if (route == null) return fallback?.call(settings);
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (context) => route.builder(context, settings),
    );
  }
}
