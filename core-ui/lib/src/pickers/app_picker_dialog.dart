import 'package:flutter/material.dart';

import '../design_system/foundations/app_radius.dart';
import '../design_system/foundations/app_spacing.dart';
import 'picker_header.dart';

/// Centered, keyboard-aware container for picker content with its own list.
/// Content returns a typed selection through Navigator.pop(dialogContext, value).
abstract final class AppPickerDialog {
  static Future<T?> show<T>(
    BuildContext context, {
    String? title,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
  }) => showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.5),
    builder: (context) => Dialog(
      alignment: Alignment.center,
      constraints: const BoxConstraints(maxWidth: 520, maxHeight: 600),
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      clipBehavior: Clip.antiAlias,
      child: FractionallySizedBox(
        heightFactor: 0.85,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: PickerHeader(title: title),
            ),
            Expanded(child: builder(context)),
          ],
        ),
      ),
    ),
  );
}
