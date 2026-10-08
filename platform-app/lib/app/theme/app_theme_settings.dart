import 'package:flutter/material.dart';
import 'package:gasione/app/theme/app_theme_config.dart';
import 'package:gasione/app/theme/app_theme_defaults.dart';

@immutable
class AppThemeSettings {
  const AppThemeSettings({
    this.themeMode = ThemeMode.system,
    this.config = AppThemeDefaults.config,
  });

  final ThemeMode themeMode;
  final AppThemeConfig config;

  AppThemeSettings copyWith({ThemeMode? themeMode, AppThemeConfig? config}) {
    return AppThemeSettings(
      themeMode: themeMode ?? this.themeMode,
      config: config ?? this.config,
    );
  }
}
