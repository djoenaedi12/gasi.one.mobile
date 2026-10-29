import 'package:dio/dio.dart';
import 'package:gasione_core_api/gasione_core_api.dart';
import 'package:gasione_core_starter/src/network/api_exception.dart';

abstract final class ApiErrorMapper {
  static ApiException fromDio(DioException error) {
    return switch (error.type) {
      DioExceptionType.cancel => const ApiException(ApiExceptionType.cancelled),
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.transformTimeout => ApiException(
        ApiExceptionType.timeout,
        message: _responseMessage(error.response),
        statusCode: error.response?.statusCode,
        code: _code(error.response?.data),
        errors: _errors(error.response?.data),
      ),
      DioExceptionType.connectionError => ApiException(
        ApiExceptionType.network,
        message: _responseMessage(error.response),
      ),
      DioExceptionType.badResponse => ApiException(
        ApiExceptionType.badResponse,
        message: _responseMessage(error.response),
        statusCode: error.response?.statusCode,
        code: _code(error.response?.data),
        errors: _errors(error.response?.data),
      ),
      DioExceptionType.badCertificate ||
      DioExceptionType.unknown => ApiException(
        ApiExceptionType.unknown,
        message: _responseMessage(error.response),
        statusCode: error.response?.statusCode,
        code: _code(error.response?.data),
        errors: _errors(error.response?.data),
      ),
    };
  }

  static String? _responseMessage(Response<dynamic>? response) {
    return _message(
      response?.data,
      contentType: response?.headers.value(Headers.contentTypeHeader),
    );
  }

  static String? _message(Object? data, {String? contentType}) {
    if (data is String) {
      return _safeText(data, contentType: contentType);
    }
    if (data is! Map) {
      return null;
    }

    for (final key in [
      'message',
      'error_description',
      'error',
      'detail',
      'title',
    ]) {
      final value = data[key];
      if (value is String) {
        final message = _safeText(value);
        if (message != null) {
          return message;
        }
      }
    }

    final errors = data['errors'];
    if (errors is List && errors.isNotEmpty) {
      final first = errors.first;
      if (first is String) {
        final message = _safeText(first);
        if (message != null) {
          return message;
        }
      }
      if (first is Map) {
        final message = first['message'];
        if (message is String) {
          final safeMessage = _safeText(message);
          if (safeMessage != null) {
            return safeMessage;
          }
        }
      }
    }
    return null;
  }

  static String? _safeText(String value, {String? contentType}) {
    final text = value.trim();
    if (text.isEmpty || text.length > 500) {
      return null;
    }

    final normalizedType = contentType?.toLowerCase();
    final normalizedText = text.toLowerCase();
    final isHtml =
        normalizedType?.contains('text/html') == true ||
        normalizedText.startsWith('<!doctype html') ||
        normalizedText.startsWith('<html') ||
        normalizedText.contains('<body') ||
        normalizedText.contains('</html>');
    return isHtml ? null : text;
  }

  static String? _code(Object? data) {
    if (data is! Map) {
      return null;
    }
    final errors = _errors(data);
    final code =
        data['code'] ??
        data['errorCode'] ??
        (errors.isEmpty ? null : errors.first.code);
    return code is String && code.isNotEmpty ? code : null;
  }

  static List<ErrorDetail> _errors(Object? data) {
    if (data is! Map || data['errors'] is! List) {
      return const [];
    }

    return [
      for (final item in data['errors'] as List)
        if (item is Map) ErrorDetail.fromJson(Map<String, dynamic>.from(item)),
    ];
  }
}
