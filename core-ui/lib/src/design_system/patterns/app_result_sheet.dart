import 'package:flutter/material.dart';

import 'app_result_content.dart';

/// Scrollable result modal. Actions use the builder's sheet context to close
/// the modal and return a typed result; dismissing it returns null.
abstract final class AppResultSheet {
  static Future<T?> show<T>(
    BuildContext context, {
    required AppResultContent Function(BuildContext) builder,
  }) => showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(child: builder(context)),
      ),
    ),
  );
}
