import 'package:flutter/widgets.dart';
import 'package:gasione_core_api/gasione_core_api.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';

import 'plugin_route_bridge.dart';

/// One validated registry for the installed Navigator host. Feature packages
/// remain compile-time contributions; they never import this composition root.
final class PluginComposition {
  PluginComposition({
    Iterable<AppPlugin> plugins = const [],
    Iterable<PluginPageRoute> pageRoutes = const [],
    Iterable<PickerDefinitionBase> pickers = const [],
    Route<dynamic>? Function(RouteSettings)? fallback,
  }) : _plugins = List.unmodifiable(plugins) {
    final codes = <String>{};
    final routes = [...pageRoutes];
    final definitions = [...pickers];
    final delegates = <LocalizationsDelegate<dynamic>>[];
    final locales = <Locale>{};
    final menuIds = <String>{};
    final menuItems = <PluginMenuItem>[];
    final resolvers = <NotificationDestinationResolver>[];
    for (final plugin in _plugins) {
      if (!codes.add(plugin.code)) {
        throw ArgumentError('Duplicate plugin: ${plugin.code}');
      }
      if (plugin is PageRouteContributor) {
        routes.addAll((plugin as PageRouteContributor).pageRoutes);
      } else if (plugin.routes.isNotEmpty) {
        throw ArgumentError(
          'Navigator plugins must implement PageRouteContributor: ${plugin.code}',
        );
      }
      if (plugin is PickerContributor) {
        definitions.addAll((plugin as PickerContributor).pickers);
      }
      if (plugin is NotificationDestinationResolver) {
        resolvers.add(plugin as NotificationDestinationResolver);
      }
      for (final delegate in plugin.localizationsDelegates) {
        if (delegates.any((existing) => existing.type == delegate.type)) {
          throw ArgumentError(
            'Duplicate localization delegate: ${delegate.type}',
          );
        }
        delegates.add(delegate);
      }
      locales.addAll(plugin.supportedLocales);
      for (final menu in plugin.menus) {
        if (!menuIds.add(menu.route)) {
          throw ArgumentError('Duplicate plugin menu: ${menu.route}');
        }
        menuItems.add(menu);
      }
    }
    this.routes = PluginRouteBridge(routes, fallback: fallback);
    this.pickers = PickerRegistry(definitions);
    localizationsDelegates = List.unmodifiable(delegates);
    supportedLocales = List.unmodifiable(locales);
    menus = List.unmodifiable(menuItems);
    notificationResolvers = List.unmodifiable(resolvers);
  }

  final List<AppPlugin> _plugins;
  late final PluginRouteBridge routes;
  late final PickerRegistry pickers;
  late final List<LocalizationsDelegate<dynamic>> localizationsDelegates;
  late final List<Locale> supportedLocales;
  late final List<PluginMenuItem> menus;
  late final List<NotificationDestinationResolver> notificationResolvers;
  Future<void>? _start;
  Future<void>? _disposal;

  Future<void> start() => _start ??= _startPlugins();
  Future<void> _startPlugins() async {
    if (_disposal != null) return;
    for (final plugin in _plugins) {
      if (_disposal != null) break;
      if (plugin is PluginLifecycle) {
        final lifecycle = plugin as PluginLifecycle;
        await lifecycle.start();
      }
    }
  }

  Future<void> dispose() => _disposal ??= _disposePlugins();
  Future<void> _disposePlugins() async {
    try {
      await _start;
    } catch (_) {
      // Even partially started services must be released.
    }
    Object? firstError;
    StackTrace? firstStack;
    for (final plugin in _plugins.reversed.whereType<PluginLifecycle>()) {
      try {
        await plugin.dispose();
      } catch (error, stack) {
        firstError ??= error;
        firstStack ??= stack;
      }
    }
    if (firstError != null) Error.throwWithStackTrace(firstError, firstStack!);
  }
}
