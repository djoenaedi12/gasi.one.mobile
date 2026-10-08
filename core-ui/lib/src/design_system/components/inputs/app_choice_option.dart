import 'package:flutter/material.dart';

class AppChoiceOption<T> {
  const AppChoiceOption({
    required this.value,
    required this.label,
    this.enabled = true,
    this.icon,
  });

  final T value;
  final String label;
  final bool enabled;
  final IconData? icon;
}
