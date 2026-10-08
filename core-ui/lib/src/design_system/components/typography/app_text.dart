import 'package:flutter/material.dart';
import 'package:gasione_core_ui/src/design_system/foundations/app_semantic_colors.dart';

enum AppTextVariant {
  display,
  headingLarge,
  headingMedium,
  headingSmall,
  title,
  body,
  bodySmall,
  label,
  caption,
}

enum AppTextTone {
  standard,
  muted,
  primary,
  success,
  warning,
  info,
  error,
  inverse,
}

/// Design-system text that resolves typography and color from the active theme.
///
/// Consumers choose semantic variants instead of supplying a [TextStyle] or
/// raw [Color], keeping visual decisions inside the design system.
class AppText extends StatelessWidget {
  const AppText(
    this.data, {
    this.variant = AppTextVariant.body,
    this.tone = AppTextTone.standard,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    super.key,
  });

  final String data;
  final AppTextVariant variant;
  final AppTextTone tone;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = _styleFor(theme.textTheme)
        .copyWith(color: _colorFor(context, theme.colorScheme));

    return Text(
      data,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
    );
  }

  TextStyle _styleFor(TextTheme textTheme) {
    return switch (variant) {
      AppTextVariant.display => textTheme.displaySmall!,
      AppTextVariant.headingLarge => textTheme.headlineLarge!,
      AppTextVariant.headingMedium => textTheme.headlineMedium!,
      AppTextVariant.headingSmall => textTheme.headlineSmall!,
      AppTextVariant.title => textTheme.titleMedium!,
      AppTextVariant.body => textTheme.bodyMedium!,
      AppTextVariant.bodySmall => textTheme.bodySmall!,
      AppTextVariant.label => textTheme.labelLarge!,
      AppTextVariant.caption => textTheme.labelSmall!,
    };
  }

  Color _colorFor(BuildContext context, ColorScheme colors) {
    return switch (tone) {
      AppTextTone.standard => colors.onSurface,
      AppTextTone.muted => colors.onSurfaceVariant,
      AppTextTone.primary => colors.primary,
      AppTextTone.success => context.semanticColors.success,
      AppTextTone.warning => context.semanticColors.warning,
      AppTextTone.info => context.semanticColors.info,
      AppTextTone.error => colors.error,
      AppTextTone.inverse => colors.onInverseSurface,
    };
  }
}
