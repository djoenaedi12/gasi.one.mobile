import 'package:flutter/material.dart';
import 'package:gasione_core_api/gasione_core_api.dart';

import '../../../localization/failure_localization.dart';
import '../../../localization/l10n/app_localizations.dart';
import '../../foundations/app_radius.dart';
import '../../foundations/app_semantic_colors.dart';
import '../../foundations/app_spacing.dart';

/// Brief feedback on the current page. New messages replace pending feedback.
/// Use AppErrorView for a failed load and AppResultPage for a completed flow.
abstract final class AppSnackbar {
  static void success(BuildContext context, String message) =>
      _show(context, message, _SnackbarVariant.success);

  static void error(BuildContext context, String message) =>
      _show(context, message, _SnackbarVariant.error);

  static void warning(BuildContext context, String message) =>
      _show(context, message, _SnackbarVariant.warning);

  static void info(BuildContext context, String message) =>
      _show(context, message, _SnackbarVariant.info);

  /// Uses the shared localized failure message. Cancellation is silent;
  /// session expiry navigation remains the host's responsibility.
  static void failure(BuildContext context, Failure failure) {
    if (failure is CancelledFailure) return;
    error(context, failure.localizedMessage(AppLocalizations.of(context)));
  }

  static void _show(
    BuildContext context,
    String message,
    _SnackbarVariant variant,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final semantic = context.semanticColors;
    final (background, foreground, icon) = switch (variant) {
      _SnackbarVariant.success => (
        semantic.success,
        semantic.onSuccess,
        Icons.check_circle_outline,
      ),
      _SnackbarVariant.error => (
        colors.error,
        colors.onError,
        Icons.error_outline,
      ),
      _SnackbarVariant.warning => (
        semantic.warning,
        semantic.onWarning,
        Icons.warning_amber_rounded,
      ),
      _SnackbarVariant.info => (
        semantic.info,
        semantic.onInfo,
        Icons.info_outline,
      ),
    };

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          margin: const EdgeInsets.all(AppSpacing.md),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          showCloseIcon: true,
          closeIconColor: foreground,
          content: Row(
            children: [
              ExcludeSemantics(child: Icon(icon, color: foreground)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}

enum _SnackbarVariant { success, error, warning, info }
