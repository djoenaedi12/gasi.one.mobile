import 'package:gasione_core_api/gasione_core_api.dart';
import 'package:gasione_core_starter/src/network/api_exception.dart';

typedef ApiDataParser<T> = T Function(Object? json);

/// Standard response envelope used by the application's REST API.
class ApiResponse<T> {
  ApiResponse({
    required this.success,
    required this.message,
    required this.data,
    required List<ErrorDetail> errors,
    required this.timestamp,
  }) : errors = List.unmodifiable(errors);

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    ApiDataParser<T> parseData,
  ) {
    try {
      final errors = _parseErrors(json['errors']);
      final success = json['success'];
      if (success is! bool) {
        throw const FormatException('Expected a boolean success value.');
      }

      final response = ApiResponse<T>(
        success: success,
        message: json['message'] is String ? json['message'] as String : '',
        data: json.containsKey('data') ? parseData(json['data']) : null,
        errors: errors,
        timestamp: _parseTimestamp(json['timestamp']),
      );

      if (!response.success) {
        throw ApiException(
          ApiExceptionType.badResponse,
          message: response.message.isEmpty
              ? (errors.isEmpty ? null : errors.first.message)
              : response.message,
          code: errors.isEmpty ? null : errors.first.code,
          errors: errors,
        );
      }
      return response;
    } on ApiException {
      rethrow;
    } on Object {
      throw const ApiException(ApiExceptionType.invalidResponse);
    }
  }

  final bool success;
  final String message;
  final T? data;
  final List<ErrorDetail> errors;
  final DateTime? timestamp;

  T requireData() {
    final value = data;
    if (value == null) {
      throw const ApiException(
        ApiExceptionType.invalidResponse,
        message: 'Expected a non-null response data value.',
      );
    }
    return value;
  }

  static List<ErrorDetail> _parseErrors(Object? json) {
    if (json == null) {
      return const [];
    }
    if (json is! List) {
      throw const FormatException('Expected an errors array.');
    }
    return [
      for (final item in json)
        if (item is Map)
          ErrorDetail.fromJson(Map<String, dynamic>.from(item))
        else
          throw const FormatException('Expected an error object.'),
    ];
  }

  static DateTime? _parseTimestamp(Object? json) {
    if (json == null) {
      return null;
    }
    if (json is! String) {
      throw const FormatException('Expected a timestamp string.');
    }
    return DateTime.tryParse(json) ??
        (throw const FormatException('Expected an ISO-8601 timestamp.'));
  }
}
