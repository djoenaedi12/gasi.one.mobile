import 'package:flutter/material.dart';
import 'package:gasione_core_ui/src/design_system/components/inputs/app_choice_option.dart';
import 'package:gasione_core_ui/src/design_system/components/inputs/app_field_error.dart';
import 'package:gasione_core_ui/src/design_system/components/typography/app_label.dart';
import 'package:gasione_core_ui/src/design_system/foundations/app_spacing.dart';

class AppSelectFormField<T> extends StatelessWidget {
  const AppSelectFormField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.hint,
    this.enabled = true,
    this.searchable = false,
    this.labelAbove = true,
    this.requiredIndicator = false,
    this.validator,
    this.autovalidateMode = AutovalidateMode.disabled,
    super.key,
  });

  final String label;
  final T? value;
  final List<AppChoiceOption<T>> options;
  final ValueChanged<T?>? onChanged;
  final String? hint;
  final bool enabled;
  final bool searchable;
  final bool labelAbove;
  final bool requiredIndicator;
  final FormFieldValidator<T>? validator;
  final AutovalidateMode autovalidateMode;

  @override
  Widget build(BuildContext context) {
    final field = DropdownMenuFormField<T>(
      initialSelection: value,
      enabled: enabled && onChanged != null,
      expandedInsets: EdgeInsets.zero,
      selectOnly: !searchable,
      enableFilter: searchable,
      enableSearch: searchable,
      label: labelAbove
          ? null
          : AppLabel(text: label, requiredIndicator: requiredIndicator),
      hintText: hint,
      validator: validator,
      errorBuilder: (_, errorText) => AppInputDecorationError(errorText),
      autovalidateMode: autovalidateMode,
      onSelected: onChanged,
      dropdownMenuEntries: [
        for (final option in options)
          DropdownMenuEntry<T>(
            value: option.value,
            label: option.label,
            enabled: option.enabled,
            leadingIcon: option.icon == null ? null : Icon(option.icon),
          ),
      ],
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
}
