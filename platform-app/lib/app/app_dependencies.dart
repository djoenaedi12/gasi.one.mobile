import 'package:gasione/app/app_config.dart';
import 'package:gasione/app/localization/locale_cubit.dart';
import 'package:gasione/app/plugin_registry.dart';
import 'package:gasione/app/theme/theme_cubit.dart';
import 'package:gasione/app/widgets/app_settings_actions.dart';
import 'package:gasione_core_starter/gasione_core_starter.dart';
import 'package:gasione_plugin_auth/gasione_plugin_auth.dart';
import 'package:gasione_plugin_catalog/gasione_plugin_catalog.dart';

class AppDependencies {
  AppDependencies._({
    required this.apiClient,
    required this.locationService,
    required this.notificationService,
    required this.permissionService,
    required this.authPlugin,
    required this.pluginRegistry,
    required this.themeCubit,
    required this.localeCubit,
    required this.authCubit,
  });

  static Future<AppDependencies> create() async {
    final tokenStorage = SecureTokenStorage();
    final apiClient = ApiClient(
      tokenStorage: tokenStorage,
      baseUrl: AppConfig.apiBaseUrl,
    );
    final preferences = SharedPreferencesStorage();
    final permissionService = DevicePermissionService();
    final locationService = DeviceLocationService(permissionService);
    final notificationService = FirebaseNotificationService();
    final themeCubit = ThemeCubit(preferences);
    final localeCubit = LocaleCubit(preferences);

    await Future.wait([
      themeCubit.load(),
      localeCubit.load(),
      notificationService.initializeLocal(),
    ]);
    final authPlugin = await AuthPlugin.create(
      apiClient: apiClient,
      loginActionsBuilder: (_) => const AppSettingsActions(),
      initialUsername: AppConfig.demoUsername,
      initialPassword: AppConfig.demoPassword,
    );
    apiClient.setSessionExpiredHandler(authPlugin.authCubit.sessionExpired);
    final pluginRegistry = PluginRegistry([
      // DummyJSON simulates product mutations without persisting them.
      CatalogPlugin(apiClient: apiClient, reloadProductsAfterMutation: false),
    ]);

    return AppDependencies._(
      apiClient: apiClient,
      locationService: locationService,
      notificationService: notificationService,
      permissionService: permissionService,
      authPlugin: authPlugin,
      pluginRegistry: pluginRegistry,
      themeCubit: themeCubit,
      localeCubit: localeCubit,
      authCubit: authPlugin.authCubit,
    );
  }

  final ApiClient apiClient;
  final LocationService locationService;
  final NotificationService notificationService;
  final PermissionService permissionService;
  final AuthPlugin authPlugin;
  final PluginRegistry pluginRegistry;
  final ThemeCubit themeCubit;
  final LocaleCubit localeCubit;
  final AuthCubit authCubit;

  Future<void> dispose() async {
    await Future.wait([
      themeCubit.close(),
      localeCubit.close(),
      authCubit.close(),
      notificationService.dispose(),
    ]);
    pluginRegistry.dispose();
    apiClient.close();
  }
}
