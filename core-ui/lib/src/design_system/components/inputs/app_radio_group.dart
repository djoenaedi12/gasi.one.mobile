import 'package:flutter/material.dart';
import 'package:gasione_core_ui/src/design_system/components/inputs/app_choice_option.dart';
import 'package:gasione_core_ui/src/design_system/components/inputs/app_field_error.dart';
import 'package:gasione_core_ui/src/design_system/components/typography/app_label.dart';
import 'package:gasione_core_ui/src/design_system/foundations/app_spacing.dart';

class AppRadioGroup<T> extends StatelessWidget {
  const AppRadioGroup({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.enabled = true,
    this.requiredIndicator = false,
    this.validator,
    this.autovalidateMode = AutovalidateMode.disabled,
    super.key,
  });

  final String label;
  final T? value;
  final List<AppChoiceOption<T>> options;
  final ValueChanged<T?>? onChanged;
  final bool enabled;
  final bool requiredIndicator;
  final FormFieldValidator<T>? validator;
  final AutovalidateMode autovalidateMode;

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      key: ValueKey(value),
      initialValue: value,
      enabled: enabled,
      validator: validator,
      autovalidateMode: autovalidateMode,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppLabel(text: label, requiredIndicator: requiredIndicator),
            const SizedBox(height: AppSpacing.xs),
            RadioGroup<T>(
              groupValue: field.value,
              onChanged: (nextValue) {
                if (!enabled || onChanged == null) {
                  return;
                }
                field.didChange(nextValue);
                onChanged!(nextValue);
              },
              child: Column(
                children: [
                  for (final option in options)
                    RadioListTile<T>(
                      value: option.value,
                      enabled: enabled && option.enabled && onChanged != null,
                      contentPadding: EdgeInsets.zero,
                      title: Text(option.label),
                      secondary: option.icon == null ? null : Icon(option.icon),
                    ),
                ],
              ),
            ),
            if (field.errorText case final String error) AppFieldError(error),
          ],
        );
      },
    );
  }
}
