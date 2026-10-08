import 'package:flutter/material.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';

/// Maps design-system foundations to Flutter's built-in component themes.
abstract final class AppComponentThemes {
  static ThemeData apply(ThemeData theme) {
    final colors = theme.colorScheme;
    final text = theme.textTheme;
    final roundedShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    );
    final buttonStyle = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
      shape: WidgetStatePropertyAll(roundedShape),
      textStyle: WidgetStatePropertyAll(text.labelLarge),
    );
    final isLight = theme.brightness == Brightness.light;
    final componentSurface = isLight ? Colors.white : colors.surfaceContainer;

    return theme.copyWith(
      filledButtonTheme: FilledButtonThemeData(style: buttonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: buttonStyle.copyWith(
          side: WidgetStatePropertyAll(
            BorderSide(color: colors.outlineVariant),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(style: buttonStyle),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: componentSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        labelStyle: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        floatingLabelStyle: text.labelMedium?.copyWith(color: colors.primary),
        hintStyle: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
        errorStyle: text.bodySmall?.copyWith(color: colors.error),
        prefixStyle: text.bodyLarge?.copyWith(color: colors.onSurface),
        prefixIconColor: colors.onSurfaceVariant,
        suffixIconColor: colors.onSurfaceVariant,
        border: _border(colors.outlineVariant),
        enabledBorder: _border(colors.outlineVariant),
        focusedBorder: _border(colors.primary, width: 2),
        errorBorder: _border(colors.error),
        focusedErrorBorder: _border(colors.error, width: 2),
        disabledBorder: _border(colors.outlineVariant),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: componentSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        titleTextStyle: text.headlineSmall?.copyWith(color: colors.onSurface),
        contentTextStyle: text.bodyMedium?.copyWith(color: colors.onSurface),
      ),
      cardTheme: CardThemeData(
        color: componentSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: roundedShape.copyWith(
          side: BorderSide(color: colors.outlineVariant),
        ),
      ),
      dividerTheme: DividerThemeData(color: colors.outlineVariant, space: 1),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        elevation: 2,
        shape: roundedShape,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: colors.onInverseSurface,
        ),
        shape: roundedShape,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
