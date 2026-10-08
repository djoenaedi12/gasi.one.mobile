import 'package:flutter/material.dart';
import 'package:gasione_core_ui/src/design_system/components/buttons/app_button.dart';
import 'package:gasione_core_ui/src/design_system/components/typography/app_text.dart';
import 'package:gasione_core_ui/src/design_system/foundations/app_spacing.dart';

class AppEmptyView extends StatelessWidget {
  const AppEmptyView({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.inbox_outlined,
    super.key,
  }) : assert(
         (actionLabel == null && onAction == null) ||
             (actionLabel != null && onAction != null),
         'actionLabel and onAction must either both be set or both be null.',
       );

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: AppSpacing.sm),
            AppText(
              title,
              textAlign: TextAlign.center,
              variant: AppTextVariant.title,
            ),
            const SizedBox(height: AppSpacing.xs),
            AppText(
              message,
              textAlign: TextAlign.center,
              tone: AppTextTone.muted,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.md),
              AppButton.secondary(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}
