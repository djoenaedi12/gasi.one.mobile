import 'package:flutter/material.dart';
import 'package:gasione_core_api/gasione_core_api.dart';

import 'app_picker_dialog.dart';
import 'app_picker_sheet.dart';

/// Compiled picker registry with early duplicate checks and typed launch results.
final class PickerRegistry implements PickerLauncher {
  PickerRegistry(Iterable<PickerDefinitionBase> definitions) {
    for (final definition in definitions) {
      if (_definitions.containsKey(definition.id)) {
        throw ArgumentError('Duplicate picker: ${definition.id}');
      }
      _definitions[definition.id] = definition;
    }
  }
  final Map<String, PickerDefinitionBase> _definitions = {};
  @override
  Future<T?> open<T>(
    BuildContext context,
    PickerKey<T> key, {
    PickerRequest<T>? request,
  }) {
    final definition = _definitions[key.id];
    if (definition == null) throw PickerUnavailableException(key.id);
    if (definition is! PickerDefinition<T>) {
      throw PickerTypeMismatchException(key.id, T);
    }
    final resolvedRequest = request ?? PickerRequest<T>();
    switch (definition.presentation) {
      case PickerPresentation.page:
        return Navigator.of(context).push<T>(
          MaterialPageRoute<T>(
            builder: (context) => definition.builder(context, resolvedRequest),
          ),
        );
      case PickerPresentation.sheet:
        return AppPickerSheet.show<T>(
          context,
          title: resolvedRequest.title,
          builder: (context) => definition.builder(context, resolvedRequest),
        );
      case PickerPresentation.dialog:
        return AppPickerDialog.show<T>(
          context,
          title: resolvedRequest.title,
          builder: (context) => definition.builder(context, resolvedRequest),
        );
    }
  }
}
