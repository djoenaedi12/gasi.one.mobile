import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

typedef PluginRouteBuilder = Widget Function(
  BuildContext context,
  GoRouterState state,
);

class PluginRoute {
  const PluginRoute({required this.path, required this.builder});

  final String path;
  final PluginRouteBuilder builder;

  GoRoute toGoRoute() => GoRoute(path: path, builder: builder);
}
