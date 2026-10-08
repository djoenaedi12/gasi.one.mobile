import 'package:flutter/material.dart';
import 'package:gasione_core_ui/src/design_system/components/inputs/app_field_error.dart';
import 'package:gasione_core_ui/src/design_system/components/typography/app_label.dart';
import 'package:gasione_core_ui/src/design_system/foundations/app_spacing.dart';

typedef AppDateFormatter = String Function(
  BuildContext context,
  DateTime value,
);

class AppDateFormField extends StatelessWidget {
  AppDateFormField({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
    this.hint,
    this.enabled = true,
    this.labelAbove = true,
    this.requiredIndicator = false,
    this.currentDate,
    this.selectableDayPredicate,
    this.formatter,
    this.validator,
    this.autovalidateMode = AutovalidateMode.disabled,
    super.key,
  }) : assert(!lastDate.isBefore(firstDate));

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?>? onChanged;
  final DateTime firstDate;
  final DateTime lastDate;
  final String? hint;
  final bool enabled;
  final bool labelAbove;
  final bool requiredIndicator;
  final DateTime? currentDate;
  final SelectableDayPredicate? selectableDayPredicate;
  final AppDateFormatter? formatter;
  final FormFieldValidator<DateTime>? validator;
  final AutovalidateMode autovalidateMode;

  @override
  Widget build(BuildContext context) {
    final field = FormField<DateTime>(
      key: ValueKey(value),
      initialValue: value,
      enabled: enabled,
      validator: validator,
      autovalidateMode: autovalidateMode,
      builder: (fieldState) {
        final selectedDate = fieldState.value;
        final formattedValue = selectedDate == null
            ? null
            : (formatter?.call(context, selectedDate) ??
                  MaterialLocalizations.of(context)
                      .formatMediumDate(selectedDate));
        final canInteract = enabled && onChanged != null;

        return Semantics(
          button: true,
          enabled: canInteract,
          label: label,
          child: InkWell(
            onTap: canInteract ? () => _pickDate(context, fieldState) : null,
            child: InputDecorator(
              isEmpty: selectedDate == null,
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
                suffixIcon: const Icon(Icons.calendar_today_outlined),
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

  Future<void> _pickDate(
    BuildContext context,
    FormFieldState<DateTime> field,
  ) async {
    var initialDate = field.value ?? currentDate ?? DateTime.now();
    if (initialDate.isBefore(firstDate)) {
      initialDate = firstDate;
    } else if (initialDate.isAfter(lastDate)) {
      initialDate = lastDate;
    }

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      currentDate: currentDate,
      selectableDayPredicate: selectableDayPredicate,
    );
    if (selectedDate == null || !context.mounted) {
      return;
    }

    field.didChange(selectedDate);
    onChanged?.call(selectedDate);
  }
}
