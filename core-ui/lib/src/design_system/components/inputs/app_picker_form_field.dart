import 'package:flutter/material.dart';
import 'package:gasione_core_ui/src/design_system/components/inputs/app_field_error.dart';
import 'package:gasione_core_ui/src/design_system/components/typography/app_label.dart';
import 'package:gasione_core_ui/src/design_system/foundations/app_spacing.dart';

/// A form field that opens a separate page and stores its selected value.
///
/// The page itself is supplied by the caller, allowing the component to remain
/// independent of every feature or plugin that provides a picker.
class AppPickerFormField<T> extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final field = FormField<T>(
      key: ValueKey(value),
      initialValue: value,
      enabled: enabled,
      validator: validator,
      forceErrorText: errorText,
      autovalidateMode: autovalidateMode,
      builder: (fieldState) {
        final canInteract = enabled && onChanged != null;
        final selected = fieldState.value;

        return Semantics(
          button: true,
          enabled: canInteract,
          label: label,
          child: InkWell(
            onTap: canInteract ? () => _openPicker(context, fieldState) : null,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              isEmpty: selected == null,
              decoration: InputDecoration(
                enabled: canInteract,
                label: labelAbove
                    ? null
                    : AppLabel(
                        text: label,
                        requiredIndicator: requiredIndicator,
                      ),
                hintText: hint,
                error: fieldState.errorText == null
                    ? null
                    : AppInputDecorationError(fieldState.errorText!),
                suffixIcon: const Icon(Icons.chevron_right),
              ),
              child: selected == null ? null : Text(labelOf(selected)),
            ),
          ),
        );
      },
    );

    if (!labelAbove) {
      return field;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppLabel(text: label, requiredIndicator: requiredIndicator),
        const SizedBox(height: AppSpacing.xs),
        field,
      ],
    );
  }

  Future<void> _openPicker(
    BuildContext context,
    FormFieldState<T> field,
  ) async {
    final selected = await onPick(context);
    if (selected == null || !context.mounted) {
      return;
    }

    field.didChange(selected);
    onChanged?.call(selected);
  }
}
