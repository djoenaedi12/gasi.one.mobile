import 'package:gasione_core_api/gasione_core_api.dart';
import 'package:gasione_core_starter/src/errors/error_reporter.dart';
import 'package:gasione_core_starter/src/errors/failure_mapper.dart';
import 'package:gasione_core_starter/src/network/api_exception.dart';

Future<Result<T>> guardResult<T>(
  Future<T> Function() operation, {
  ErrorReporter reportError = reportUnexpectedError,
}) async {
  try {
    return Success(await operation());
  } on Object catch (error, stackTrace) {
    if (error is! ApiException) reportError(error, stackTrace);
    return FailureResult(FailureMapper.from(error));
  }
}
