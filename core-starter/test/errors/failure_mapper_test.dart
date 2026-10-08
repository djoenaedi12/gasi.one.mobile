import 'package:flutter_test/flutter_test.dart';
import 'package:gasione_core_starter/gasione_core_starter.dart';

void main() {
  test('maps API error types and status codes to typed failures', () {
    expect(
      FailureMapper.from(const ApiException(ApiExceptionType.network)),
      isA<NetworkFailure>(),
    );
    expect(
      FailureMapper.from(const ApiException(ApiExceptionType.timeout)),
      isA<TimeoutFailure>(),
    );
    expect(
      FailureMapper.from(
        const ApiException(ApiExceptionType.badResponse, statusCode: 401),
      ),
      isA<UnauthorizedFailure>(),
    );
    expect(
      FailureMapper.from(
        const ApiException(ApiExceptionType.badResponse, statusCode: 422),
      ),
      isA<ValidationFailure>(),
    );
    expect(
      FailureMapper.from(
        const ApiException(ApiExceptionType.badResponse, statusCode: 503),
      ),
      isA<ServerFailure>(),
    );
    expect(FailureMapper.from(StateError('unexpected')), isA<UnknownFailure>());
  });
}
