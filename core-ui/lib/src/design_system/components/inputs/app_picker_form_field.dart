import 'package:flutter/material.dart';
import 'package:gasione_core_ui/src/design_system/components/inputs/app_field_error.dart';
import 'package:gasione_core_ui/src/design_system/components/typography/app_label.dart';
import 'package:gasione_core_ui/src/design_system/foundations/app_radius.dart';
import 'package:gasione_core_ui/src/design_system/foundations/app_spacing.dart';

/// A form field that opens a picker and stores its selected value.
///
/// The picker launcher is supplied by the caller, allowing the component to remain
/// independent of every feature or plugin that provides a picker.
class AppPickerFormField<T> extends StatefulWidget {
  const AppPickerFormField({
    required this.label,
    required this.value,
    required this.labelOf,
    required this.onPick,
    required this.onChanged,
    this.hint,
    this.enabled = true,
    this.labelAbove = true,
    this.requiredIndicator = false,
    this.validator,
    this.errorText,
    this.autovalidateMode = AutovalidateMode.disabled,
    super.key,
  });

  final String label;
  final T? value;
  final String Function(T value) labelOf;
  final Future<T?> Function(BuildContext context) onPick;
  final ValueChanged<T?>? onChanged;
  final String? hint;
  final bool enabled;
  final bool labelAbove;
  final bool requiredIndicator;
  final FormFieldValidator<T>? validator;
  final String? errorText;
  final AutovalidateMode autovalidateMode;

  @override
  State<AppPickerFormField<T>> createState() => _AppPickerFormFieldState<T>();
}

class _AppPickerFormFieldState<T> extends State<AppPickerFormField<T>> {
  bool _picking = false;

  @override
  Widget build(BuildContext context) {
    final field = FormField<T>(
      key: ValueKey(widget.value),
      initialValue: widget.value,
      enabled: widget.enabled,
      validator: widget.validator,
      forceErrorText: widget.errorText,
      autovalidateMode: widget.autovalidateMode,
      builder: (fieldState) {
        final canInteract =
            widget.enabled && widget.onChanged != null && !_picking;
        final selected = fieldState.value;

        return Semantics(
          button: true,
          enabled: canInteract,
          label: widget.label,
          child: InkWell(
            onTap: canInteract ? () => _openPicker(fieldState) : null,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: InputDecorator(
              isEmpty: selected == null,
              decoration: InputDecoration(
                enabled: canInteract,
                label: widget.labelAbove
                    ? null
                    : AppLabel(
                        text: widget.label,
                        requiredIndicator: widget.requiredIndicator,
                      ),
                hintText: widget.hint,
                error: fieldState.errorText == null
                    ? null
                    : AppInputDecorationError(fieldState.errorText!),
                suffixIcon: const Icon(Icons.chevron_right),
              ),
              child: selected == null ? null : Text(widget.labelOf(selected)),
            ),
          ),
        );
      },
    );

    if (!widget.labelAbove) {
      return field;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppLabel(
          text: widget.label,
          requiredIndicator: widget.requiredIndicator,
        ),
        const SizedBox(height: AppSpacing.xs),
        field,
      ],
    );
  }

  Future<void> _openPicker(FormFieldState<T> field) async {
    if (_picking || !widget.enabled || widget.onChanged == null) return;
    setState(() => _picking = true);
    try {
      final selected = await widget.onPick(context);
      // An external value update can replace the FormField while this state
      // remains mounted. Do not apply a late result to that abandoned field.
      if (!mounted ||
          !field.mounted ||
          !widget.enabled ||
          widget.onChanged == null ||
          selected == null) {
        return;
      }
      field.didChange(selected);
      widget.onChanged?.call(selected);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }
}
