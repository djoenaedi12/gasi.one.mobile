import 'package:gasione_core_api/gasione_core_api.dart';

extension FailureFormErrors on Failure {
  String? fieldError(String field) {
    final normalizedField = _normalizeField(field);
    for (final error in errors) {
      if (_normalizeField(error.field) == normalizedField) {
        final message = error.message.trim();
        if (message.isNotEmpty) {
          return message;
        }
      }
    }
    return null;
  }

  String? unboundErrorMessage({
    required Set<String> knownFields,
    required String fallbackMessage,
  }) {
    final normalizedFields = knownFields.map(_normalizeField).toSet();
    final unboundMessages = errors
        .where(
          (error) => !normalizedFields.contains(_normalizeField(error.field)),
        )
        .map((error) => error.message.trim())
        .where((message) => message.isNotEmpty)
        .toSet();

    if (unboundMessages.isNotEmpty) {
      return unboundMessages.join('\n');
    }

    final hasBoundError = errors.any(
      (error) => normalizedFields.contains(_normalizeField(error.field)),
    );
    return hasBoundError ? null : fallbackMessage;
  }
}

String? _normalizeField(String? field) => field?.trim().toLowerCase();
