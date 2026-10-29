import 'package:flutter/material.dart';
import 'package:gasione_core_api/gasione_core_api.dart';

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
    return Navigator.of(context).push<T>(
      MaterialPageRoute<T>(
        builder: (context) =>
            definition.pageBuilder(context, request ?? PickerRequest<T>()),
      ),
    );
  }
}
