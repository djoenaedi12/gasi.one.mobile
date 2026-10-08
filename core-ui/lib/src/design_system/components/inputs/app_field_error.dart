import 'package:flutter/material.dart';
import 'package:gasione_core_ui/src/design_system/components/typography/app_text.dart';
import 'package:gasione_core_ui/src/design_system/foundations/app_spacing.dart';

class AppFieldError extends StatelessWidget {
  const AppFieldError(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.xxs),
      child: AppText(
        message,
        variant: AppTextVariant.bodySmall,
        tone: AppTextTone.error,
      ),
    );
  }
}

/// Error used inside an [InputDecoration].
///
/// Material aligns decoration errors with the field's content padding. The
/// design system uses labels above the field, so this removes that inset and
/// keeps the error aligned with both the label and the input outline.
class AppInputDecorationError extends StatelessWidget {
  const AppInputDecorationError(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.of(context);
    const decorationErrorInset = AppSpacing.md + AppSpacing.xxs;

    return Transform.translate(
      offset: Offset(
        direction == TextDirection.ltr
            ? -decorationErrorInset
            : decorationErrorInset,
        0,
      ),
      child: Text(message),
    );
  }
}
