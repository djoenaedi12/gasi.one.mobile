import 'package:dio/dio.dart';

class RetryInterceptor extends Interceptor {
  RetryInterceptor(this._dio, {this.maxRetries = 2});

  static const _retryCountKey = 'retryCount';

  final Dio _dio;
  final int maxRetries;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final request = err.requestOptions;
    final retryCount = request.extra[_retryCountKey] as int? ?? 0;
    if (!_canRetry(err, retryCount)) {
      handler.next(err);
      return;
    }

    request.extra[_retryCountKey] = retryCount + 1;
    await Future<void>.delayed(Duration(milliseconds: 250 * (1 << retryCount)));

    try {
      handler.resolve(await _dio.fetch<dynamic>(request));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  bool _canRetry(DioException error, int retryCount) {
    if (retryCount >= maxRetries) {
      return false;
    }

    final method = error.requestOptions.method.toUpperCase();
    if (method != 'GET' && method != 'HEAD') {
      return false;
    }

    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.transformTimeout) {
      return true;
    }

    return const {
      408,
      429,
      500,
      502,
      503,
      504,
    }.contains(error.response?.statusCode);
  }
}
