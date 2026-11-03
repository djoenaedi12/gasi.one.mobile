import 'package:flutter/material.dart';

import '../foundations/app_radius.dart';
import '../foundations/app_spacing.dart';
import 'app_result_content.dart';

/// Centered result modal. Actions use the builder's dialog context to return
/// a typed result; dismissing without an action returns null.
abstract final class AppResultDialog {
  static Future<T?> show<T>(
    BuildContext context, {
    required AppResultContent Function(BuildContext) builder,
    bool barrierDismissible = true,
  }) => showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.5),
    builder: (context) => Dialog(
      alignment: Alignment.center,
      constraints: const BoxConstraints(maxWidth: 520),
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(child: builder(context)),
    ),
  );
}
