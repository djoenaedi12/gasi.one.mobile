import 'package:flutter/material.dart';
import 'package:gasione/app/theme/app_theme_config.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';

/// Source-code fallback when cached or remote theme configuration is absent.
abstract final class AppThemeDefaults {
  static const config = AppThemeConfig(
    // Main brand blue. Keeping it as the single source of truth makes the
    // brand consistent across buttons, links, focus states, and navigation.
    seedColor: Color(0xFF0072CE),
    lightSemanticColors: AppSemanticColors(
      success: Color(0xFF146C43),
      onSuccess: Color(0xFFFFFFFF),
      successContainer: Color(0xFFD1E7DD),
      onSuccessContainer: Color(0xFF0A3622),
      warning: Color(0xFF997404),
      onWarning: Color(0xFFFFFFFF),
      warningContainer: Color(0xFFFFF3CD),
      onWarningContainer: Color(0xFF664D03),
      info: Color(0xFF087990),
      onInfo: Color(0xFFFFFFFF),
      infoContainer: Color(0xFFCFF4FC),
      onInfoContainer: Color(0xFF055160),
    ),
    darkSemanticColors: AppSemanticColors(
      success: Color(0xFF75B798),
      onSuccess: Color(0xFF052E1C),
      successContainer: Color(0xFF0F5132),
      onSuccessContainer: Color(0xFFD1E7DD),
      warning: Color(0xFFFFDA6A),
      onWarning: Color(0xFF332701),
      warningContainer: Color(0xFF664D03),
      onWarningContainer: Color(0xFFFFF3CD),
      info: Color(0xFF6EDFF6),
      onInfo: Color(0xFF032830),
      infoContainer: Color(0xFF055160),
      onInfoContainer: Color(0xFFCFF4FC),
    ),
  );
}
