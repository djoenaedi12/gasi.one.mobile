import 'package:flutter/material.dart';
import 'package:gasione_core_ui/src/design_system/components/buttons/app_button.dart';
import 'package:gasione_core_ui/src/design_system/components/typography/app_text.dart';
import 'package:gasione_core_ui/src/design_system/foundations/app_spacing.dart';

class AppErrorView extends StatelessWidget {
  const AppErrorView({
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.icon = Icons.cloud_off_outlined,
    super.key,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;
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
              message,
              textAlign: TextAlign.center,
              tone: AppTextTone.error,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton.secondary(label: actionLabel, onPressed: onAction),
          ],
        ),
      ),
    );
  }
}
