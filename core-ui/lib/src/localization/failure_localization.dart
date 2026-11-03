import 'package:gasione_core_api/gasione_core_api.dart';
import 'package:gasione_core_ui/src/localization/l10n/app_localizations.dart';

extension FailureLocalization on Failure {
  /// Technical failures use translated guidance rather than transport details.
  /// Business failures retain a non-empty API message (for example validation).
  String localizedMessage(AppLocalizations localizations) {
    final backendMessage = message?.trim();
    final businessMessage = backendMessage == null || backendMessage.isEmpty
        ? null
        : backendMessage;

    return switch (this) {
      NetworkFailure() => localizations.networkError,
      TimeoutFailure() => localizations.timeoutError,
      UnauthorizedFailure() => localizations.unauthorizedError,
      ForbiddenFailure() => businessMessage ?? localizations.forbiddenError,
      NotFoundFailure() => businessMessage ?? localizations.notFoundError,
      ValidationFailure() => businessMessage ?? localizations.validationError,
      ConflictFailure() => businessMessage ?? localizations.conflictError,
      RateLimitFailure() => businessMessage ?? localizations.rateLimitError,
      ServerFailure() => localizations.serverError,
      HttpFailure() => businessMessage ?? localizations.operationFailed,
      InvalidResponseFailure() => localizations.invalidResponseError,
      CancelledFailure() => localizations.requestCancelled,
      UnknownFailure() => localizations.unknownError,
    };
  }
}
