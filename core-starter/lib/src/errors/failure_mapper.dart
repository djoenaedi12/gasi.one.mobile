import 'package:gasione_core_api/gasione_core_api.dart';
import 'package:gasione_core_starter/src/network/api_exception.dart';

abstract final class FailureMapper {
  static Failure from(Object error) {
    if (error is! ApiException) {
      return const UnknownFailure();
    }

    return switch (error.type) {
      ApiExceptionType.network => NetworkFailure(message: error.message),
      ApiExceptionType.timeout => TimeoutFailure(message: error.message),
      ApiExceptionType.cancelled => const CancelledFailure(),
      ApiExceptionType.invalidResponse => InvalidResponseFailure(
        message: error.message,
      ),
      ApiExceptionType.badResponse => _fromStatusCode(error),
      ApiExceptionType.unknown => UnknownFailure(message: error.message),
    };
  }

  static Failure _fromStatusCode(ApiException error) {
    return switch (error.statusCode) {
      400 || 422 => ValidationFailure(
        message: error.message,
        statusCode: error.statusCode,
        code: error.code,
        errors: error.errors,
      ),
      401 => UnauthorizedFailure(
        message: error.message,
        statusCode: error.statusCode,
        code: error.code,
        errors: error.errors,
      ),
      403 => ForbiddenFailure(
        message: error.message,
        statusCode: error.statusCode,
        code: error.code,
        errors: error.errors,
      ),
      404 => NotFoundFailure(
        message: error.message,
        statusCode: error.statusCode,
        code: error.code,
        errors: error.errors,
      ),
      409 => ConflictFailure(
        message: error.message,
        statusCode: error.statusCode,
        code: error.code,
        errors: error.errors,
      ),
      429 => RateLimitFailure(
        message: error.message,
        statusCode: error.statusCode,
        code: error.code,
        errors: error.errors,
      ),
      final int statusCode when statusCode >= 500 => ServerFailure(
        message: error.message,
        statusCode: statusCode,
        code: error.code,
        errors: error.errors,
      ),
      _ => HttpFailure(
        message: error.message,
        statusCode: error.statusCode,
        code: error.code,
        errors: error.errors,
      ),
    };
  }
}
