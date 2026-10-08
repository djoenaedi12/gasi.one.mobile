import 'package:flutter/material.dart';
import 'package:gasione/app/theme/app_component_themes.dart';
import 'package:gasione/app/theme/app_theme_config.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';

abstract final class AppTheme {
  static ThemeData light(AppThemeConfig config) {
    return _create(Brightness.light, config);
  }

  static ThemeData dark(AppThemeConfig config) {
    return _create(Brightness.dark, config);
  }

  static ThemeData _create(Brightness brightness, AppThemeConfig config) {
    final generatedScheme = ColorScheme.fromSeed(
      seedColor: config.seedColor,
      brightness: brightness,
    );
    final colorScheme = generatedScheme.copyWith(
      // ColorScheme.fromSeed adjusts the supplied seed tonally. Primary is
      // kept exact so branded controls always render as #0072CE.
      primary: config.seedColor,
      onPrimary: Colors.white,
    );

    final baseTheme = ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      extensions: [config.semanticColorsFor(brightness)],
      scaffoldBackgroundColor: brightness == Brightness.light
          ? Colors.white
          : colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: brightness == Brightness.light
            ? Colors.white
            : colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
      ),
    );
    final theme = baseTheme.copyWith(
      textTheme: AppTypography.apply(baseTheme.textTheme),
    );

    return AppComponentThemes.apply(theme);
  }
}
