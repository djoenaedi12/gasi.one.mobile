import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasione/app/theme/app_theme.dart';
import 'package:gasione/app/theme/app_theme_config.dart';
import 'package:gasione/app/theme/app_theme_defaults.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';

void main() {
  test('builds different light and dark color tokens', () {
    final lightTheme = AppTheme.light(AppThemeDefaults.config);
    final darkTheme = AppTheme.dark(AppThemeDefaults.config);

    expect(lightTheme.brightness, Brightness.light);
    expect(darkTheme.brightness, Brightness.dark);
    expect(
      lightTheme.colorScheme.primaryContainer,
      isNot(darkTheme.colorScheme.primaryContainer),
    );
    expect(
      lightTheme.extension<AppSemanticColors>()!.success,
      isNot(darkTheme.extension<AppSemanticColors>()!.success),
    );
  });

  test('keeps the exact brand color as primary', () {
    final lightTheme = AppTheme.light(AppThemeDefaults.config);
    final darkTheme = AppTheme.dark(AppThemeDefaults.config);

    expect(AppThemeDefaults.config.seedColor, const Color(0xFF0072CE));
    expect(lightTheme.colorScheme.primary, const Color(0xFF0072CE));
    expect(darkTheme.colorScheme.primary, const Color(0xFF0072CE));
  });

  test('remote values override only defined tokens', () {
    const remoteSuccess = Color(0xFF00AA55);
    const remoteConfig = AppThemeConfigOverride(
      lightSemanticColors: AppSemanticColorsOverride(success: remoteSuccess),
    );

    final resolved = remoteConfig.resolve(AppThemeDefaults.config);

    expect(resolved.lightSemanticColors.success, remoteSuccess);
    expect(
      resolved.lightSemanticColors.warning,
      AppThemeDefaults.config.lightSemanticColors.warning,
    );
    expect(
      resolved.darkSemanticColors.success,
      AppThemeDefaults.config.darkSemanticColors.success,
    );
  });
}
