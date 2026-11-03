import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Diagnostic metadata only. URLs (including path parameters), headers, bodies,
/// and exception messages can all contain credentials or employee information.
class SafeLogInterceptor extends Interceptor {
  SafeLogInterceptor({void Function(String)? log}) : _log = log ?? debugPrint;

  final void Function(String) _log;

  String _method(RequestOptions request) => switch (request.method) {
    'GET' ||
    'HEAD' ||
    'POST' ||
    'PUT' ||
    'PATCH' ||
    'DELETE' ||
    'OPTIONS' => request.method,
    _ => 'REQUEST',
  };

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _log('--> ${_method(options)}');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _log('<-- ${_method(response.requestOptions)} ${response.statusCode}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log(
      '<-- ${_method(err.requestOptions)} ERROR '
      '${err.response?.statusCode ?? '-'} ${err.type.name}',
    );
    handler.next(err);
  }
}
