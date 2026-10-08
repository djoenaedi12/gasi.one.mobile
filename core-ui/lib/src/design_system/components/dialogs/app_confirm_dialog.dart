import 'package:flutter/material.dart';
import 'package:gasione_core_ui/src/design_system/components/buttons/app_button.dart';

class AppConfirmDialog extends StatefulWidget {
  const AppConfirmDialog({
    required this.title,
    required this.message,
    required this.cancelLabel,
    required this.confirmLabel,
    this.destructive = false,
    this.onConfirm,
    super.key,
  });

  final String title;
  final String message;
  final String cancelLabel;
  final String confirmLabel;
  final bool destructive;
  final Future<bool> Function()? onConfirm;

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    required String cancelLabel,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AppConfirmDialog(
            title: title,
            message: message,
            cancelLabel: cancelLabel,
            confirmLabel: confirmLabel,
            destructive: destructive,
          ),
        ) ??
        false;
  }

  /// Shows a confirmation dialog that stays open while [onConfirm] runs.
  ///
  /// Returns `null` when cancelled, otherwise the result of [onConfirm].
  static Future<bool?> showAsync(
    BuildContext context, {
    required String title,
    required String message,
    required String cancelLabel,
    required String confirmLabel,
    required Future<bool> Function() onConfirm,
    bool destructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AppConfirmDialog(
        title: title,
        message: message,
        cancelLabel: cancelLabel,
        confirmLabel: confirmLabel,
        destructive: destructive,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<AppConfirmDialog> createState() => _AppConfirmDialogState();
}

class _AppConfirmDialogState extends State<AppConfirmDialog> {
  bool _isLoading = false;

  Future<void> _confirm() async {
    final action = widget.onConfirm;
    if (action == null) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() => _isLoading = true);

    var result = false;
    try {
      result = await action();
    } on Object {
      result = false;
    }
    if (mounted) {
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isLoading,
      child: AlertDialog(
        title: Text(widget.title),
        content: Text(widget.message),
        actions: [
          AppButton.ghost(
            label: widget.cancelLabel,
            onPressed: _isLoading
                ? null
                : () =>
                      Navigator.of(context)
                          .pop<bool>(widget.onConfirm == null ? false : null),
          ),
          if (widget.destructive)
            AppButton.destructive(
              label: widget.confirmLabel,
              onPressed: _confirm,
              isLoading: _isLoading,
            )
          else
            AppButton.primary(
              label: widget.confirmLabel,
              onPressed: _confirm,
              isLoading: _isLoading,
            ),
        ],
      ),
    );
  }
}
