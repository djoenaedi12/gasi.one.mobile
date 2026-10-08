import 'package:flutter/material.dart';
import 'package:gasione_core_ui/src/design_system/foundations/app_spacing.dart';

enum AppButtonVariant { primary, secondary, destructive, outline, ghost, link }

class AppButton extends StatelessWidget {
  const AppButton.primary({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = false,
    super.key,
  }) : variant = AppButtonVariant.primary;

  const AppButton.secondary({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = false,
    super.key,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.destructive({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = false,
    super.key,
  }) : variant = AppButtonVariant.destructive;

  const AppButton.outline({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = false,
    super.key,
  }) : variant = AppButtonVariant.outline;

  const AppButton.ghost({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = false,
    super.key,
  }) : variant = AppButtonVariant.ghost;

  const AppButton.link({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = false,
    super.key,
  }) : variant = AppButtonVariant.link;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool expand;
  final AppButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final callback = isLoading ? null : onPressed;
    final child = _ButtonContent(
      label: label,
      icon: icon,
      isLoading: isLoading,
    );

    final button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
        onPressed: callback,
        style: _loadingStyle(context),
        child: child,
      ),
      AppButtonVariant.secondary => FilledButton.tonal(
        onPressed: callback,
        style: _loadingStyle(context),
        child: child,
      ),
      AppButtonVariant.destructive => FilledButton(
        onPressed: callback,
        style: isLoading ? _loadingStyle(context) : _destructiveStyle(context),
        child: child,
      ),
      AppButtonVariant.outline => OutlinedButton(
        onPressed: callback,
        style: _loadingStyle(context),
        child: child,
      ),
      AppButtonVariant.ghost => TextButton(
        onPressed: callback,
        style: _loadingStyle(context),
        child: child,
      ),
      AppButtonVariant.link => TextButton(
        onPressed: callback,
        style: isLoading ? _loadingStyle(context) : _linkStyle(context),
        child: child,
      ),
    };

    return Semantics(
      label: label,
      button: true,
      child: expand ? SizedBox(width: double.infinity, child: button) : button,
    );
  }

  ButtonStyle _destructiveStyle(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return FilledButton.styleFrom(
      backgroundColor: colors.error,
      foregroundColor: colors.onError,
    );
  }

  ButtonStyle? _loadingStyle(BuildContext context) {
    if (!isLoading) {
      return null;
    }

    final colors = Theme.of(context).colorScheme;
    return switch (variant) {
      AppButtonVariant.primary => FilledButton.styleFrom(
        disabledBackgroundColor: Color.alphaBlend(
          colors.primary.withValues(alpha: 0.78),
          colors.surface,
        ),
        disabledForegroundColor: colors.onPrimary,
      ),
      AppButtonVariant.secondary => FilledButton.styleFrom(
        disabledBackgroundColor: colors.secondaryContainer,
        disabledForegroundColor: colors.onSecondaryContainer,
      ),
      AppButtonVariant.destructive => FilledButton.styleFrom(
        disabledBackgroundColor: Color.alphaBlend(
          colors.error.withValues(alpha: 0.78),
          colors.surface,
        ),
        disabledForegroundColor: colors.onError,
      ),
      AppButtonVariant.outline => OutlinedButton.styleFrom(
        disabledForegroundColor: colors.primary,
        side: BorderSide(color: colors.primary),
      ),
      AppButtonVariant.ghost || AppButtonVariant.link => TextButton.styleFrom(
        disabledForegroundColor: colors.primary,
      ),
    };
  }

  ButtonStyle _linkStyle(BuildContext context) {
    final theme = Theme.of(context);
    return TextButton.styleFrom(
      foregroundColor: theme.colorScheme.primary,
      textStyle: theme.textTheme.labelLarge?.copyWith(
        decoration: TextDecoration.underline,
        decorationColor: theme.colorScheme.primary,
      ),
    );
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.icon,
    required this.isLoading,
  });

  final String label;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading) ...[
          SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: DefaultTextStyle.of(context).style.color,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
        ] else if (icon != null) ...[
          Icon(icon, size: 18),
          const SizedBox(width: AppSpacing.xs),
        ],
        Text(label),
      ],
    );
  }
}
