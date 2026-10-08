import 'package:gasione_core_starter/src/network/api_exception.dart';

abstract final class ApiResponseParser {
  static T object<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json) parser, {
    String? dataKey,
  }) {
    try {
      final payload = dataKey == null ? json : json[dataKey];
      if (payload is! Map<String, dynamic>) {
        throw const FormatException('Expected a JSON object.');
      }
      return parser(payload);
    } on ApiException {
      rethrow;
    } on Object {
      throw const ApiException(ApiExceptionType.invalidResponse);
    }
  }

  static List<T> list<T>(
    Map<String, dynamic> json,
    String dataKey,
    T Function(Map<String, dynamic> json) parser,
  ) {
    try {
      final payload = json[dataKey];
      if (payload is! List) {
        throw const FormatException('Expected a JSON array.');
      }
      return payload
          .map((item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException('Expected a JSON object.');
            }
            return parser(item);
          })
          .toList(growable: false);
    } on ApiException {
      rethrow;
    } on Object {
      throw const ApiException(ApiExceptionType.invalidResponse);
    }
  }
}
