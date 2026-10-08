import 'package:flutter/material.dart';
import 'package:gasione_core_ui/src/design_system/components/inputs/app_field_error.dart';
import 'package:gasione_core_ui/src/design_system/components/typography/app_label.dart';
import 'package:gasione_core_ui/src/design_system/foundations/app_spacing.dart';

typedef AppTimeFormatter = String Function(
  BuildContext context,
  TimeOfDay value,
);

class AppTimeFormField extends StatelessWidget {
  const AppTimeFormField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
    this.enabled = true,
    this.labelAbove = true,
    this.requiredIndicator = false,
    this.formatter,
    this.validator,
    this.autovalidateMode = AutovalidateMode.disabled,
    super.key,
  });

  final String label;
  final TimeOfDay? value;
  final ValueChanged<TimeOfDay?>? onChanged;
  final String? hint;
  final bool enabled;
  final bool labelAbove;
  final bool requiredIndicator;
  final AppTimeFormatter? formatter;
  final FormFieldValidator<TimeOfDay>? validator;
  final AutovalidateMode autovalidateMode;

  @override
  Widget build(BuildContext context) {
    final field = FormField<TimeOfDay>(
      key: ValueKey(value),
      initialValue: value,
      enabled: enabled,
      validator: validator,
      autovalidateMode: autovalidateMode,
      builder: (fieldState) {
        final selectedTime = fieldState.value;
        final formattedValue = selectedTime == null
            ? null
            : (formatter?.call(context, selectedTime) ??
                  MaterialLocalizations.of(context).formatTimeOfDay(
                    selectedTime,
                    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(
                      context,
                    ),
                  ));
        final canInteract = enabled && onChanged != null;

        return Semantics(
          button: true,
          enabled: canInteract,
          label: label,
          child: InkWell(
            onTap: canInteract ? () => _pickTime(context, fieldState) : null,
            child: InputDecorator(
              isEmpty: selectedTime == null,
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
                suffixIcon: const Icon(Icons.schedule_outlined),
              ),
              child: formattedValue == null ? null : Text(formattedValue),
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

  Future<void> _pickTime(
    BuildContext context,
    FormFieldState<TimeOfDay> field,
  ) async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: field.value ?? TimeOfDay.now(),
    );
    if (selectedTime == null || !context.mounted) {
      return;
    }

    field.didChange(selectedTime);
    onChanged?.call(selectedTime);
  }
}
