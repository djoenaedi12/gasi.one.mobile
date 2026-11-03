import 'package:flutter/material.dart';

import 'picker_header.dart';

/// A bounded, keyboard-aware container for picker content with its own list.
/// Content returns a typed selection through Navigator.pop(sheetContext, value).
abstract final class AppPickerSheet {
  static Future<T?> show<T>(
    BuildContext context, {
    String? title,
    required WidgetBuilder builder,
  }) => showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: FractionallySizedBox(
        heightFactor: 0.85,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              PickerHeader(title: title),
              Expanded(child: builder(context)),
            ],
          ),
        ),
      ),
    ),
  );
}
