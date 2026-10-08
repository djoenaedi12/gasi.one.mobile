import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class SafeLogInterceptor extends Interceptor {
  static const _sensitiveKeys = {
    'authorization',
    'cookie',
    'password',
    'accesstoken',
    'refreshtoken',
    'access_token',
    'refresh_token',
  };

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _log(
      '--> ${options.method} ${options.uri}\n'
      'headers: ${_redact(options.headers)}\n'
      'data: ${_redact(options.data)}',
    );
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _log(
      '<-- ${response.statusCode} ${response.requestOptions.uri}\n'
      'data: ${_redact(response.data)}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log(
      '<-- ERROR ${err.response?.statusCode ?? '-'} '
      '${err.requestOptions.uri}\n'
      'data: ${_redact(err.response?.data)}',
    );
    handler.next(err);
  }

  Object? _redact(Object? value) {
    if (value is FormData) {
      return '<multipart form data>';
    }
    if (value is Map) {
      return value.map((key, item) {
        final normalizedKey = key.toString().toLowerCase();
        final isSensitive = _sensitiveKeys.any(normalizedKey.contains);
        return MapEntry(key, isSensitive ? '<redacted>' : _redact(item));
      });
    }
    if (value is Iterable) {
      return value.map(_redact).toList(growable: false);
    }
    return value;
  }

  void _log(String message) {
    final output = message.length > 3000
        ? '${message.substring(0, 3000)}…'
        : message;
    debugPrint(output);
  }
}
