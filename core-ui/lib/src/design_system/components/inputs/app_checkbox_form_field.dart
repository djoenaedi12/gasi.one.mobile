import 'package:flutter/material.dart';
import 'package:gasione_core_ui/src/design_system/components/inputs/app_field_error.dart';
import 'package:gasione_core_ui/src/design_system/components/typography/app_label.dart';

class AppCheckboxFormField extends StatelessWidget {
  const AppCheckboxFormField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.enabled = true,
    this.requiredIndicator = false,
    this.validator,
    this.autovalidateMode = AutovalidateMode.disabled,
    super.key,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? subtitle;
  final bool enabled;
  final bool requiredIndicator;
  final FormFieldValidator<bool>? validator;
  final AutovalidateMode autovalidateMode;

  @override
  Widget build(BuildContext context) {
    return FormField<bool>(
      key: ValueKey(value),
      initialValue: value,
      enabled: enabled,
      validator: validator,
      autovalidateMode: autovalidateMode,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              value: field.value ?? false,
              enabled: enabled && onChanged != null,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: AppLabel(
                text: label,
                requiredIndicator: requiredIndicator,
              ),
              subtitle: subtitle == null ? null : Text(subtitle!),
              onChanged: enabled && onChanged != null
                  ? (nextValue) {
                      final resolvedValue = nextValue ?? false;
                      field.didChange(resolvedValue);
                      onChanged!(resolvedValue);
                    }
                  : null,
            ),
            if (field.errorText case final String error) AppFieldError(error),
          ],
        );
      },
    );
  }
}
