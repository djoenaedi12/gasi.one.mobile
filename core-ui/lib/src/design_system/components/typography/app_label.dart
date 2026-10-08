import 'package:flutter/material.dart';
import 'package:gasione_core_ui/src/design_system/foundations/app_spacing.dart';

class AppLabel extends StatelessWidget {
  const AppLabel({
    required this.text,
    this.requiredIndicator = false,
    this.trailing,
    super.key,
  });

  final String text;
  final bool requiredIndicator;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelLarge?.copyWith(
      color: theme.colorScheme.onSurface,
    );
    final label = Text.rich(
      TextSpan(
        text: text,
        children: [
          if (requiredIndicator)
            TextSpan(
              text: ' *',
              style: labelStyle?.copyWith(color: theme.colorScheme.error),
            ),
        ],
      ),
      style: labelStyle,
    );

    if (trailing == null) {
      return label;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        label,
        const SizedBox(width: AppSpacing.xs),
        trailing!,
      ],
    );
  }
}
