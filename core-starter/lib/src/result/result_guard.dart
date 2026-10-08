import 'package:gasione_core_api/gasione_core_api.dart';
import 'package:gasione_core_starter/src/errors/failure_mapper.dart';

Future<Result<T>> guardResult<T>(Future<T> Function() operation) async {
  try {
    return Success(await operation());
  } on Object catch (error) {
    return FailureResult(FailureMapper.from(error));
  }
}
