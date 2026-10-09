import 'dart:developer' as developer;

typedef ErrorReporter = void Function(Object error, StackTrace stackTrace);

/// Keeps the original diagnostic outside localized, user-facing failures.
void reportUnexpectedError(Object error, StackTrace stackTrace) {
  developer.log(
    'Unexpected application error',
    name: 'gasione',
    error: error,
    stackTrace: stackTrace,
  );
}
