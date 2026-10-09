import 'package:flutter_test/flutter_test.dart';
import 'package:gasione_core_starter/gasione_core_starter.dart';

void main() {
  test('reports the original unexpected exception and stack trace', () async {
    final original = StateError('Unexpected');
    Object? reported;
    StackTrace? trace;
    final result = await guardResult<int>(
      () async => throw original,
      reportError: (error, stack) {
        reported = error;
        trace = stack;
      },
    );
    expect(result, isA<FailureResult<int>>());
    expect(reported, same(original));
    expect(trace.toString(), isNotEmpty);
  });
  test('expected API failures are mapped without reporting a crash', () async {
    var reports = 0;
    await guardResult<int>(
      () async => throw const ApiException(ApiExceptionType.network),
      reportError: (_, _) => reports++,
    );
    expect(reports, 0);
  });
}
