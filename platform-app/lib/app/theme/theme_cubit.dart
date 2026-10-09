import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gasione/app/theme/app_theme_config.dart';
import 'package:gasione/app/theme/app_theme_defaults.dart';
import 'package:gasione/app/theme/app_theme_settings.dart';
import 'package:gasione_core_starter/gasione_core_starter.dart';

class ThemeCubit extends Cubit<AppThemeSettings> {
  ThemeCubit(this._preferences) : super(const AppThemeSettings());

  static const _preferenceKey = 'settings.theme_mode';

  final PreferencesStorage _preferences;

  Future<void> load() async {
    final storedValue = await _preferences.readString(_preferenceKey);
    if (isClosed) return;
    final themeMode = switch (storedValue) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    emit(state.copyWith(themeMode: themeMode));
  }

  Future<void> toggle(Brightness currentBrightness) async {
    final useDarkTheme = state.themeMode == ThemeMode.system
        ? currentBrightness != Brightness.dark
        : state.themeMode != ThemeMode.dark;
    await setThemeMode(useDarkTheme ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    if (isClosed || state.themeMode == themeMode) {
      return;
    }
    emit(state.copyWith(themeMode: themeMode));
    await _preferences.writeString(_preferenceKey, themeMode.name);
  }

  /// Applies optional values loaded from an API/database over code defaults.
  /// Calling this with `null` restores all color tokens to code defaults.
  void applyThemeOverride(AppThemeConfigOverride? override) {
    if (isClosed) return;
    final config =
        override?.resolve(AppThemeDefaults.config) ?? AppThemeDefaults.config;
    emit(state.copyWith(config: config));
  }
}
