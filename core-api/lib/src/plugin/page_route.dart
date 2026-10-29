import 'package:flutter/widgets.dart';

/// A page contribution usable by the installed Navigator host during migration.
final class PluginPageRoute {
  const PluginPageRoute({required this.path, required this.builder});

  final String path;
  final Widget Function(BuildContext, RouteSettings) builder;
}

abstract interface class PageRouteContributor {
  List<PluginPageRoute> get pageRoutes;
}
