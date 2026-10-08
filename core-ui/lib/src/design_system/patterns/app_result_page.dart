import 'package:flutter/material.dart';
import 'package:gasione_core_ui/src/design_system/components/buttons/app_button.dart';
import 'package:gasione_core_ui/src/design_system/components/typography/app_text.dart';
import 'package:gasione_core_ui/src/design_system/foundations/app_semantic_colors.dart';
import 'package:gasione_core_ui/src/design_system/foundations/app_spacing.dart';

enum AppResultStatus { success, failure }

/// Reusable full-page feedback for a completed process.
class AppResultPage extends StatelessWidget {
  const AppResultPage({
    required this.status,
    required this.title,
    required this.message,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    super.key,
  }) : assert(
         (secondaryActionLabel == null && onSecondaryAction == null) ||
             (secondaryActionLabel != null && onSecondaryAction != null),
         'secondaryActionLabel and onSecondaryAction must both be provided.',
       );

  final AppResultStatus status;
  final String title;
  final String message;
  final String primaryActionLabel;
  final VoidCallback onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final semanticColors = theme.extension<AppSemanticColors>();
    final isSuccess = status == AppResultStatus.success;
    final accentColor = isSuccess
        ? (semanticColors?.success ?? colors.primary)
        : colors.error;
    final containerColor = isSuccess
        ? (semanticColors?.successContainer ?? colors.primaryContainer)
        : colors.errorContainer;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: containerColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSuccess ? Icons.check_rounded : Icons.close_rounded,
                        color: accentColor,
                        size: 48,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppText(
                    title,
                    textAlign: TextAlign.center,
                    variant: AppTextVariant.headingMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AppText(
                    message,
                    textAlign: TextAlign.center,
                    tone: isSuccess ? AppTextTone.muted : AppTextTone.error,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton.primary(
                    label: primaryActionLabel,
                    onPressed: onPrimaryAction,
                    expand: true,
                  ),
                  if (secondaryActionLabel != null &&
                      onSecondaryAction != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    AppButton.ghost(
                      label: secondaryActionLabel!,
                      onPressed: onSecondaryAction,
                      expand: true,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
