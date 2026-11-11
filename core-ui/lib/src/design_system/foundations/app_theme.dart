import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_semantic_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Maps the GASI:One web color roles onto Flutter's existing design-system APIs.
abstract final class AppTheme {
  static ThemeData light() => _build(AppColors.light);
  static ThemeData dark() => _build(AppColors.dark);

  static ThemeData _build(AppPalette palette) {
    final colors = ColorScheme(
      brightness: palette.brightness,
      primary: palette.primary,
      onPrimary: palette.primaryForeground,
      primaryContainer: palette.accent,
      onPrimaryContainer: palette.accentForeground,
      secondary: palette.secondary,
      onSecondary: palette.secondaryForeground,
      secondaryContainer: palette.secondary,
      onSecondaryContainer: palette.secondaryForeground,
      tertiary: palette.info,
      onTertiary: palette.infoForeground,
      error: palette.destructive,
      onError: palette.destructiveForeground,
      surface: palette.background,
      onSurface: palette.foreground,
      surfaceContainerLowest: palette.card,
      surfaceContainerLow: palette.card,
      surfaceContainer: palette.surface,
      surfaceContainerHigh: palette.muted,
      onSurfaceVariant: palette.mutedForeground,
      outline: palette.input,
      outlineVariant: palette.border,
      inverseSurface: palette.foreground,
      onInverseSurface: palette.background,
      inversePrimary: palette.primary,
      surfaceTint: palette.primary,
    );
    final base = ThemeData(useMaterial3: false, colorScheme: colors);
    final textTheme = AppTypography.apply(base.textTheme);
    final isDark = palette.brightness == Brightness.dark;

    // Web defines solid status colors. Mobile adds 12% tinted containers for
    // badges; their foregrounds use the readable web foreground in light mode
    // and the brighter status color in dark mode.
    Color container(Color color) =>
        Color.alphaBlend(color.withValues(alpha: 0.12), palette.background);

    return base.copyWith(
      primaryColor: palette.primary,
      scaffoldBackgroundColor: palette.background,
      textTheme: textTheme,
      dividerColor: palette.border,
      extensions: [
        AppSemanticColors(
          success: palette.success,
          onSuccess: palette.successForeground,
          successContainer: container(palette.success),
          onSuccessContainer: isDark
              ? palette.success
              : palette.successForeground,
          warning: palette.warning,
          onWarning: palette.warningForeground,
          warningContainer: container(palette.warning),
          onWarningContainer: isDark
              ? palette.warning
              : palette.warningForeground,
          info: palette.info,
          onInfo: palette.infoForeground,
          infoContainer: container(palette.info),
          onInfoContainer: isDark ? palette.info : palette.infoForeground,
        ),
      ],
      cardTheme: CardThemeData(
        color: palette.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      dialogTheme: DialogThemeData(backgroundColor: palette.popover),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: palette.input),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: palette.ring, width: 2),
        ),
      ),
    );
  }
}
