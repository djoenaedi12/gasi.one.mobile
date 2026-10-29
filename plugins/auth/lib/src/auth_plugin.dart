import 'package:flutter/widgets.dart';
import 'package:gasione_core_api/gasione_core_api.dart';

/// Foundation registration. The Pre-Home CR contributes its concrete pages.
final class AuthPlugin implements AppPlugin, PageRouteContributor {
  const AuthPlugin({this.pageRoutes = const []});
  @override
  final List<PluginPageRoute> pageRoutes;
  @override
  String get code => 'auth';
  @override
  List<PluginRoute> get routes => const [];
  @override
  List<PluginMenuItem> get menus => const [];
  @override
  List<LocalizationsDelegate<dynamic>> get localizationsDelegates => const [];
  @override
  List<Locale> get supportedLocales => const [Locale('en'), Locale('id')];
}
