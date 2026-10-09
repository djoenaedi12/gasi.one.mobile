import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gasione_core_api/gasione_core_api.dart';

final class PluginRegistry extends ChangeNotifier implements PickerLauncher {
  PluginRegistry(
    Iterable<AppPlugin> plugins, {
    Iterable<String> reservedPaths = const [],
  }) : _plugins = List.unmodifiable(plugins) {
    _activePluginCodes = {};
    final paths = <String>{for (final path in reservedPaths) _routeShape(path)};

    for (final plugin in _plugins) {
      if (plugin.code.isEmpty || !_activePluginCodes.add(plugin.code)) {
        throw ArgumentError(
          'Plugin codes must be nonempty and unique: ${plugin.code}',
        );
      }
      for (final route in plugin.routes) {
        if (!paths.add(_routeShape(route.path))) {
          throw ArgumentError(
            'Duplicate or reserved plugin route: ${route.path}',
          );
        }
        _routes.add(route);
        _routeOwners.add(_RouteOwner(plugin.code, route.path));
      }
      if (plugin is! PickerContributor) {
        continue;
      }
      final contributor = plugin as PickerContributor;
      for (final picker in contributor.pickers) {
        if (_pickers.containsKey(picker.id)) {
          throw ArgumentError.value(
            picker.id,
            'picker.id',
            'A picker with this identifier is already registered.',
          );
        }
        _pickers[picker.id] = _RegisteredPicker(
          pluginCode: plugin.code,
          definition: picker,
        );
      }
    }
  }

  final List<AppPlugin> _plugins;
  final List<PluginRoute> _routes = [];
  final List<_RouteOwner> _routeOwners = [];
  final Map<String, _RegisteredPicker> _pickers = {};
  late Set<String> _activePluginCodes;

  List<PluginRoute> get routes => List.unmodifiable(_routes);

  List<PluginMenuItem> get activeMenus => [
    for (final plugin in _plugins)
      if (_activePluginCodes.contains(plugin.code)) ...plugin.menus,
  ];

  // Keep resources installed while outgoing plugin routes finish disposal.
  List<LocalizationsDelegate<dynamic>> get localizationsDelegates => [
    for (final plugin in _plugins) ...plugin.localizationsDelegates,
  ];

  List<Locale> get supportedLocales => [
    for (final plugin in _plugins) ...plugin.supportedLocales,
  ];

  void activate(Iterable<String> pluginCodes) {
    final next = pluginCodes.toSet();
    final unknown = next.difference(
      _plugins.map((plugin) => plugin.code).toSet(),
    );
    if (unknown.isNotEmpty) throw ArgumentError('Unknown plugins: $unknown');
    if (setEquals(next, _activePluginCodes)) return;
    _activePluginCodes = next;
    notifyListeners();
  }

  void validateReservedPaths(Iterable<String> paths) {
    final reserved = paths.map(_routeShape).toSet();
    for (final route in _routes) {
      if (reserved.contains(_routeShape(route.path))) {
        throw ArgumentError(
          'Plugin route conflicts with an application route: ${route.path}',
        );
      }
    }
  }

  @override
  Future<T?> open<T>(
    BuildContext context,
    PickerKey<T> key, {
    PickerRequest<T>? request,
  }) {
    final registered = _pickers[key.id];
    if (registered == null ||
        !_activePluginCodes.contains(registered.pluginCode)) {
      throw PickerUnavailableException(key.id);
    }

    final definition = registered.definition;
    if (definition is! PickerDefinition<T>) {
      throw PickerTypeMismatchException(key.id, T);
    }

    return Navigator.of(context).push<T>(
      MaterialPageRoute(
        builder: (pageContext) => ListenableBuilder(
          listenable: this,
          builder: (_, _) {
            if (!_activePluginCodes.contains(registered.pluginCode)) {
              // Pop an already-open picker when its provider is disabled.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!pageContext.mounted) return;
                final route = ModalRoute.of(pageContext);
                if (route == null) return;
                final navigator = Navigator.of(pageContext);
                if (route.isCurrent) {
                  navigator.pop();
                } else {
                  navigator.removeRoute(route);
                }
              });
              return const SizedBox.shrink();
            }
            return definition.pageBuilder(
              pageContext,
              request ?? PickerRequest<T>(),
            );
          },
        ),
      ),
    );
  }

  bool isLocationEnabled(String location) {
    final path = Uri.parse(location).path;
    // Match in registration order, as the router does for overlapping patterns.
    for (final owner in _routeOwners) {
      if (owner.matches(path)) {
        return _activePluginCodes.contains(owner.pluginCode);
      }
    }
    return true;
  }
}

String _routeShape(String path) => path
    .toLowerCase()
    .split('/')
    .map((segment) => segment.startsWith(':') ? ':' : segment)
    .join('/');

final class _RouteOwner {
  _RouteOwner(this.pluginCode, String path)
    : _pattern = RegExp(
        '^${path.split('/').map((segment) => segment.startsWith(':') ? '[^/]+' : RegExp.escape(segment)).join('/')}\$',
        caseSensitive: false,
      );

  final String pluginCode;
  final RegExp _pattern;
  bool matches(String path) => _pattern.hasMatch(path);
}

final class _RegisteredPicker {
  const _RegisteredPicker({required this.pluginCode, required this.definition});

  final String pluginCode;
  final PickerDefinitionBase definition;
}
