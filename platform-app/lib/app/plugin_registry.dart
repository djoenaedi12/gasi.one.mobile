import 'package:flutter/material.dart';
import 'package:gasione_core_api/gasione_core_api.dart';

final class PluginRegistry implements PickerLauncher {
  PluginRegistry(Iterable<AppPlugin> plugins)
    : _plugins = List.unmodifiable(plugins) {
    _activePluginCodes = _plugins.map((plugin) => plugin.code).toSet();

    for (final plugin in _plugins) {
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
  final Map<String, _RegisteredPicker> _pickers = {};
  late Set<String> _activePluginCodes;

  List<PluginRoute> get routes => [
    for (final plugin in _plugins) ...plugin.routes,
  ];

  List<PluginMenuItem> get activeMenus => [
    for (final plugin in _plugins)
      if (_activePluginCodes.contains(plugin.code)) ...plugin.menus,
  ];

  List<LocalizationsDelegate<dynamic>> get localizationsDelegates => [
    for (final plugin in _plugins)
      if (_activePluginCodes.contains(plugin.code))
        ...plugin.localizationsDelegates,
  ];

  List<Locale> get supportedLocales => [
    for (final plugin in _plugins)
      if (_activePluginCodes.contains(plugin.code)) ...plugin.supportedLocales,
  ];

  void activate(Iterable<String> pluginCodes) {
    _activePluginCodes = pluginCodes.toSet();
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
        builder: (pageContext) => definition.pageBuilder(
          pageContext,
          request ?? PickerRequest<T>(),
        ),
      ),
    );
  }

  bool isLocationEnabled(String location) {
    for (final plugin in _plugins) {
      final ownsLocation = plugin.routes.any((route) => route.path == location);
      if (ownsLocation) {
        return _activePluginCodes.contains(plugin.code);
      }
    }
    return true;
  }
}

final class _RegisteredPicker {
  const _RegisteredPicker({required this.pluginCode, required this.definition});

  final String pluginCode;
  final PickerDefinitionBase definition;
}
