import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gasione_core_ui/src/design_system/components/inputs/app_field_error.dart';
import 'package:gasione_core_ui/src/design_system/components/typography/app_label.dart';
import 'package:gasione_core_ui/src/design_system/foundations/app_spacing.dart';

class AppTextFormField extends StatelessWidget {
  const AppTextFormField({
    required this.controller,
    required this.label,
    this.hint,
    this.labelAbove = true,
    this.requiredIndicator = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.validator,
    this.errorText,
    this.autovalidateMode = AutovalidateMode.disabled,
    this.onChanged,
    this.onFieldSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.prefixText,
    this.minLines = 1,
    this.maxLines = 1,
    this.maxLength,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool labelAbove;
  final bool requiredIndicator;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;
  final String? errorText;
  final AutovalidateMode autovalidateMode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? prefixText;
  final int minLines;
  final int maxLines;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
      controller: controller,
      enabled: enabled,
      readOnly: readOnly,
      autofocus: autofocus,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      validator: validator,
      forceErrorText: errorText,
      errorBuilder: (_, errorText) => AppInputDecorationError(errorText),
      autovalidateMode: autovalidateMode,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      minLines: obscureText ? 1 : minLines,
      maxLines: obscureText ? 1 : maxLines,
      maxLength: maxLength,
      decoration: InputDecoration(
        label: labelAbove
            ? null
            : AppLabel(text: label, requiredIndicator: requiredIndicator),
        hintText: hint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        prefixText: prefixText,
      ),
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
