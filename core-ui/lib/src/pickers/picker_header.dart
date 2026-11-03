import 'package:flutter/material.dart';

import '../design_system/components/typography/app_text.dart';
import '../design_system/foundations/app_spacing.dart';

/// Shared header for the dialog and bottom-sheet picker containers.
class PickerHeader extends StatelessWidget {
  const PickerHeader({super.key, this.title});

  final String? title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(
      left: AppSpacing.lg,
      right: AppSpacing.xs,
      bottom: AppSpacing.xs,
    ),
    child: Row(
      children: [
        Expanded(
          child: title == null
              ? const SizedBox.shrink()
              : AppText(title!, variant: AppTextVariant.title),
        ),
        IconButton(
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ],
    ),
  );
}
