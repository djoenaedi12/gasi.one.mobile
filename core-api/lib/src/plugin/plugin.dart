import 'package:flutter/widgets.dart';
import 'package:gasione_core_api/src/plugin/plugin_menu_item.dart';
import 'package:gasione_core_api/src/plugin/plugin_route.dart';

abstract interface class AppPlugin {
  String get code;

  List<PluginRoute> get routes;

  List<PluginMenuItem> get menus;

  /// Localization resources owned by this plugin.
  List<LocalizationsDelegate<dynamic>> get localizationsDelegates;

  /// Locales supported by this plugin's localization resources.
  List<Locale> get supportedLocales;
}
