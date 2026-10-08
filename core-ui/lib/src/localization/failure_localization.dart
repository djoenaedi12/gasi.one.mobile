import 'package:gasione_core_api/gasione_core_api.dart';
import 'package:gasione_core_ui/src/localization/l10n/app_localizations.dart';

extension FailureLocalization on Failure {
  String localizedMessage(AppLocalizations localizations) {
    final backendMessage = message?.trim();
    if (backendMessage != null && backendMessage.isNotEmpty) {
      return backendMessage;
    }

    return switch (this) {
      NetworkFailure() => localizations.networkError,
      TimeoutFailure() => localizations.timeoutError,
      UnauthorizedFailure() => localizations.unauthorizedError,
      ForbiddenFailure() => localizations.forbiddenError,
      NotFoundFailure() => localizations.notFoundError,
      ValidationFailure() => localizations.validationError,
      ConflictFailure() => localizations.conflictError,
      RateLimitFailure() => localizations.rateLimitError,
      ServerFailure() => localizations.serverError,
      HttpFailure() => localizations.operationFailed,
      InvalidResponseFailure() => localizations.invalidResponseError,
      CancelledFailure() => localizations.requestCancelled,
      UnknownFailure() => localizations.unknownError,
    };
  }
}
