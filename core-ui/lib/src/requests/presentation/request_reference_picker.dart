import 'package:flutter/material.dart';
import 'package:gasione_core_api/gasione_core_api.dart';

import '../../pickers/app_picker_dialog.dart';
import '../../pickers/app_picker_sheet.dart';
import 'request_reference_picker_content.dart';

/// Page wrapper for reference picker content; modal wrappers share the content.
class RequestReferencePicker extends StatelessWidget {
  const RequestReferencePicker({
    super.key,
    required this.title,
    required this.repository,
    required this.kind,
    this.filters = const {},
    this.isEligible,
  });
  final String title;
  final RequestReferenceRepository repository;
  final RequestReferenceKind kind;
  final Map<String, Object?> filters;
  final bool Function(RequestReference)? isEligible;

  /// Opens a modal picker without nesting a Scaffold inside the sheet.
  static Future<RequestReference?> showModal(
    BuildContext context, {
    required String title,
    required RequestReferenceRepository repository,
    required RequestReferenceKind kind,
    Map<String, Object?> filters = const {},
    bool Function(RequestReference)? isEligible,
  }) => AppPickerSheet.show<RequestReference>(
    context,
    title: title,
    builder: (context) => RequestReferencePickerContent(
      repository: repository,
      kind: kind,
      filters: filters,
      isEligible: isEligible,
      onSelected: (value) => Navigator.of(context).pop(value),
    ),
  );

  /// Opens the same reference content as a centered dialog.
  static Future<RequestReference?> showDialog(
    BuildContext context, {
    required String title,
    required RequestReferenceRepository repository,
    required RequestReferenceKind kind,
    Map<String, Object?> filters = const {},
    bool Function(RequestReference)? isEligible,
  }) => AppPickerDialog.show<RequestReference>(
    context,
    title: title,
    builder: (context) => RequestReferencePickerContent(
      repository: repository,
      kind: kind,
      filters: filters,
      isEligible: isEligible,
      onSelected: (value) => Navigator.of(context).pop(value),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: RequestReferencePickerContent(
      repository: repository,
      kind: kind,
      filters: filters,
      isEligible: isEligible,
      onSelected: (value) => Navigator.of(context).pop(value),
    ),
  );
}
