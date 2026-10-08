import 'package:gasione_core_api/src/errors/error_detail.dart';

sealed class Failure {
  const Failure({
    this.message,
    this.statusCode,
    this.code,
    this.errors = const [],
  });

  final String? message;
  final int? statusCode;
  final String? code;
  final List<ErrorDetail> errors;
}

final class NetworkFailure extends Failure {
  const NetworkFailure({super.message});
}

final class TimeoutFailure extends Failure {
  const TimeoutFailure({super.message});
}

final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({
    super.message,
    super.statusCode,
    super.code,
    super.errors,
  });
}

final class ForbiddenFailure extends Failure {
  const ForbiddenFailure({
    super.message,
    super.statusCode,
    super.code,
    super.errors,
  });
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure({
    super.message,
    super.statusCode,
    super.code,
    super.errors,
  });
}

final class ValidationFailure extends Failure {
  const ValidationFailure({
    super.message,
    super.statusCode,
    super.code,
    super.errors,
  });
}

final class ConflictFailure extends Failure {
  const ConflictFailure({
    super.message,
    super.statusCode,
    super.code,
    super.errors,
  });
}

final class RateLimitFailure extends Failure {
  const RateLimitFailure({
    super.message,
    super.statusCode,
    super.code,
    super.errors,
  });
}

final class ServerFailure extends Failure {
  const ServerFailure({
    super.message,
    super.statusCode,
    super.code,
    super.errors,
  });
}

final class HttpFailure extends Failure {
  const HttpFailure({
    super.message,
    super.statusCode,
    super.code,
    super.errors,
  });
}

final class InvalidResponseFailure extends Failure {
  const InvalidResponseFailure({super.message});
}

final class CancelledFailure extends Failure {
  const CancelledFailure();
}

final class UnknownFailure extends Failure {
  const UnknownFailure({super.message});
}
