import 'package:flutter/material.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';

/// Fully resolved theme tokens used to build light and dark [ThemeData].
///
/// This model deliberately contains no nullable values. Optional values from a
/// remote source are resolved through [AppThemeConfigOverride.resolve].
@immutable
class AppThemeConfig {
  const AppThemeConfig({
    required this.seedColor,
    required this.lightSemanticColors,
    required this.darkSemanticColors,
  });

  final Color seedColor;
  final AppSemanticColors lightSemanticColors;
  final AppSemanticColors darkSemanticColors;

  AppSemanticColors semanticColorsFor(Brightness brightness) {
    return brightness == Brightness.dark
        ? darkSemanticColors
        : lightSemanticColors;
  }
}

/// Nullable values coming from API/database configuration.
///
/// Any missing value falls back to the corresponding value supplied to
/// [resolve], normally [AppThemeDefaults.config].
@immutable
class AppThemeConfigOverride {
  const AppThemeConfigOverride({
    this.seedColor,
    this.lightSemanticColors,
    this.darkSemanticColors,
  });

  final Color? seedColor;
  final AppSemanticColorsOverride? lightSemanticColors;
  final AppSemanticColorsOverride? darkSemanticColors;

  AppThemeConfig resolve(AppThemeConfig fallback) {
    return AppThemeConfig(
      seedColor: seedColor ?? fallback.seedColor,
      lightSemanticColors:
          lightSemanticColors?.resolve(fallback.lightSemanticColors) ??
          fallback.lightSemanticColors,
      darkSemanticColors:
          darkSemanticColors?.resolve(fallback.darkSemanticColors) ??
          fallback.darkSemanticColors,
    );
  }
}

@immutable
class AppSemanticColorsOverride {
  const AppSemanticColorsOverride({
    this.success,
    this.onSuccess,
    this.successContainer,
    this.onSuccessContainer,
    this.warning,
    this.onWarning,
    this.warningContainer,
    this.onWarningContainer,
    this.info,
    this.onInfo,
    this.infoContainer,
    this.onInfoContainer,
  });

  final Color? success;
  final Color? onSuccess;
  final Color? successContainer;
  final Color? onSuccessContainer;
  final Color? warning;
  final Color? onWarning;
  final Color? warningContainer;
  final Color? onWarningContainer;
  final Color? info;
  final Color? onInfo;
  final Color? infoContainer;
  final Color? onInfoContainer;

  AppSemanticColors resolve(AppSemanticColors fallback) {
    return fallback.copyWith(
      success: success,
      onSuccess: onSuccess,
      successContainer: successContainer,
      onSuccessContainer: onSuccessContainer,
      warning: warning,
      onWarning: onWarning,
      warningContainer: warningContainer,
      onWarningContainer: onWarningContainer,
      info: info,
      onInfo: onInfo,
      infoContainer: infoContainer,
      onInfoContainer: onInfoContainer,
    );
  }
}
