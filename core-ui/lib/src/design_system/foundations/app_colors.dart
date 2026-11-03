import 'package:flutter/material.dart';

/// Shared color roles copied from gasi.one.web/core-ui/src/index.css.
/// Components consume these through AppTheme, ColorScheme, and AppSemanticColors.
abstract final class AppColors {
  static const light = AppPalette(
    brightness: Brightness.light,
    background: Color(0xFFF8FAFC),
    foreground: Color(0xFF0F172A),
    card: Color(0xFFFFFFFF),
    cardForeground: Color(0xFF0F172A),
    popover: Color(0xFFFFFFFF),
    popoverForeground: Color(0xFF0F172A),
    primary: Color(0xFF0072CE),
    primaryForeground: Color(0xFFFFFFFF),
    secondary: Color(0xFFE6F1FA),
    secondaryForeground: Color(0xFF0059A1),
    surface: Color(0xFFDBE2EA),
    surfaceForeground: Color(0xFF0F172A),
    neutral: Color(0xFFFFFFFF),
    neutralForeground: Color(0xFF0F172A),
    muted: Color(0xFFDBE2EA),
    mutedForeground: Color(0xFF475569),
    accent: Color(0xFFEBF4FB),
    accentForeground: Color(0xFF0F172A),
    success: Color(0xFF0CE956),
    successForeground: Color(0xFF052E16),
    warning: Color(0xFFEEBD2B),
    warningForeground: Color(0xFF422006),
    info: Color(0xFF59A3DF),
    infoForeground: Color(0xFF0F172A),
    destructive: Color(0xFFEF0619),
    destructiveForeground: Color(0xFFFFFFFF),
    link: Color(0xFF0072CE),
    border: Color(0xFFE2E8F0),
    input: Color(0xFFCBD5E1),
    ring: Color(0xFF0072CE),
  );

  static const dark = AppPalette(
    brightness: Brightness.dark,
    background: Color(0xFF0F172A),
    foreground: Color(0xFFFFFFFF),
    card: Color(0xFF1E293B),
    cardForeground: Color(0xFFFFFFFF),
    popover: Color(0xFF1E293B),
    popoverForeground: Color(0xFFFFFFFF),
    primary: Color(0xFF1188E7),
    primaryForeground: Color(0xFF0F172A),
    secondary: Color(0xFF10375F),
    secondaryForeground: Color(0xFFC4E1F9),
    surface: Color(0xFF1E293B),
    surfaceForeground: Color(0xFFFFFFFF),
    neutral: Color(0xFF0F172A),
    neutralForeground: Color(0xFFFFFFFF),
    muted: Color(0xFF1E293B),
    mutedForeground: Color(0xFFCBD5E1),
    accent: Color(0xFF0F2948),
    accentForeground: Color(0xFFCBE5FA),
    success: Color(0xFF42FF82),
    successForeground: Color(0xFF052E16),
    warning: Color(0xFFFBD76A),
    warningForeground: Color(0xFF422006),
    info: Color(0xFF58ACEE),
    infoForeground: Color(0xFF0F172A),
    destructive: Color(0xFFFF4252),
    destructiveForeground: Color(0xFFFFFFFF),
    link: Color(0xFF1188E7),
    border: Color(0xFF334155),
    input: Color(0xFF334155),
    ring: Color(0xFF1188E7),
  );
}

/// The web semantic role names remain recognizable across both codebases.
@immutable
class AppPalette {
  const AppPalette({
    required this.brightness,
    required this.background,
    required this.foreground,
    required this.card,
    required this.cardForeground,
    required this.popover,
    required this.popoverForeground,
    required this.primary,
    required this.primaryForeground,
    required this.secondary,
    required this.secondaryForeground,
    required this.surface,
    required this.surfaceForeground,
    required this.neutral,
    required this.neutralForeground,
    required this.muted,
    required this.mutedForeground,
    required this.accent,
    required this.accentForeground,
    required this.success,
    required this.successForeground,
    required this.warning,
    required this.warningForeground,
    required this.info,
    required this.infoForeground,
    required this.destructive,
    required this.destructiveForeground,
    required this.link,
    required this.border,
    required this.input,
    required this.ring,
  });

  final Brightness brightness;
  final Color background;
  final Color foreground;
  final Color card;
  final Color cardForeground;
  final Color popover;
  final Color popoverForeground;
  final Color primary;
  final Color primaryForeground;
  final Color secondary;
  final Color secondaryForeground;
  final Color surface;
  final Color surfaceForeground;
  final Color neutral;
  final Color neutralForeground;
  final Color muted;
  final Color mutedForeground;
  final Color accent;
  final Color accentForeground;
  final Color success;
  final Color successForeground;
  final Color warning;
  final Color warningForeground;
  final Color info;
  final Color infoForeground;
  final Color destructive;
  final Color destructiveForeground;
  final Color link;
  final Color border;
  final Color input;
  final Color ring;
}
