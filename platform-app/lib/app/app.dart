import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gasione/app/app_dependencies.dart';
import 'package:gasione/app/localization/locale_cubit.dart';
import 'package:gasione/app/router/app_router.dart';
import 'package:gasione/app/theme/app_theme.dart';
import 'package:gasione/app/theme/app_theme_settings.dart';
import 'package:gasione/app/theme/theme_cubit.dart';
import 'package:gasione_core_api/gasione_core_api.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';
import 'package:gasione_plugin_auth/gasione_plugin_auth.dart';

class MyApp extends StatefulWidget {
  const MyApp({required this.dependencies, super.key});

  final AppDependencies dependencies;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppRouter _router;

  @override
  void initState() {
    super.initState();
    final dependencies = widget.dependencies;
    _router = AppRouter(
      authPlugin: dependencies.authPlugin,
      pluginRegistry: dependencies.pluginRegistry,
    );
  }

  @override
  void dispose() {
    _router.dispose();
    unawaited(widget.dependencies.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = widget.dependencies;

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<PickerLauncher>.value(
          value: dependencies.pluginRegistry,
        ),
        RepositoryProvider<AuthRepository>.value(
          value: dependencies.authPlugin.repository,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ThemeCubit>.value(value: dependencies.themeCubit),
          BlocProvider<LocaleCubit>.value(value: dependencies.localeCubit),
          BlocProvider<AuthCubit>.value(value: dependencies.authCubit),
        ],
        child: BlocBuilder<ThemeCubit, AppThemeSettings>(
          builder: (context, themeSettings) {
            return BlocBuilder<LocaleCubit, Locale?>(
              builder: (context, locale) {
                return MaterialApp.router(
                  onGenerateTitle: (context) =>
                      AppLocalizations.of(context).appName,
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.light(themeSettings.config),
                  darkTheme: AppTheme.dark(themeSettings.config),
                  themeMode: themeSettings.themeMode,
                  locale: locale,
                  localizationsDelegates: [
                    ...AppLocalizations.localizationsDelegates,
                    ...dependencies.pluginRegistry.localizationsDelegates,
                  ],
                  supportedLocales: {
                    ...AppLocalizations.supportedLocales,
                    ...dependencies.pluginRegistry.supportedLocales,
                  }.toList(),
                  routerConfig: _router.router,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
