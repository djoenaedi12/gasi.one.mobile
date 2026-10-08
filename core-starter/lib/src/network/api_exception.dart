import 'package:gasione_core_api/gasione_core_api.dart';

enum ApiExceptionType {
  network,
  timeout,
  cancelled,
  badResponse,
  invalidResponse,
  unknown,
}

class ApiException implements Exception {
  const ApiException(
    this.type, {
    this.message,
    this.statusCode,
    this.code,
    this.errors = const [],
  });

  final ApiExceptionType type;
  final String? message;
  final int? statusCode;
  final String? code;
  final List<ErrorDetail> errors;

  @override
  String toString() => message ?? type.name;
}
