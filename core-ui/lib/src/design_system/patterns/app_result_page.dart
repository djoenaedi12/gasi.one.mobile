import 'package:flutter/material.dart';

import 'app_result_content.dart';

export 'app_result_content.dart' show AppResultStatus;

/// Full-page wrapper for the reusable result content.
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          child: AppResultContent(
            status: status,
            title: title,
            message: message,
            primaryActionLabel: primaryActionLabel,
            onPrimaryAction: onPrimaryAction,
            secondaryActionLabel: secondaryActionLabel,
            onSecondaryAction: onSecondaryAction,
          ),
        ),
      ),
    ),
  );
}
