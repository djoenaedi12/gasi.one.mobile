import 'package:dio/dio.dart';
import 'package:gasione_core_starter/gasione_core_starter.dart';

/// Shared transport for the installed API. Features supply endpoint and mapping.
final class RequestApi {
  RequestApi({
    required this.client,
    required this.context,
    required this.headers,
  });
  final ApiClient client;
  final BusinessContextProvider context;
  final Map<String, Object?> Function() headers;

  Future<Object?> get(String path, {Map<String, Object?> query = const {}}) =>
      _call(
        (url, values) =>
            client.getJson(url, queryParameters: query, headers: values),
        path,
      );
  Future<Object?> post(String path, Map<String, Object?> data) => _call(
    (url, values) => client.postJson(url, data: data, headers: values),
    path,
  );
  Future<Object?> put(String path, Map<String, Object?> data) => _call(
    (url, values) => client.putJson(url, data: data, headers: values),
    path,
  );
  Future<Object?> upload(String path, FormData data) => _call(
    (url, values) => client.upload(url, data: data, headers: values),
    path,
  );
  Future<List<int>> bytes(String path) async {
    final active = _requireContext();
    final data = await client.getBytes(_url(active, path), headers: headers());
    _checkSession(active);
    return data;
  }

  Future<Object?> _call(
    Future<Map<String, dynamic>> Function(String, Map<String, Object?>)
    operation,
    String path,
  ) async {
    final active = _requireContext();
    final response = await operation(_url(active, path), headers());
    _checkSession(active);
    if (response['success'] != true) {
      throw const ApiException(ApiExceptionType.badResponse);
    }
    return response['data'];
  }

  ActiveBusinessContext _requireContext() =>
      context.activeContext ??
      (throw const ApiException(ApiExceptionType.badResponse, statusCode: 401));
  void _checkSession(ActiveBusinessContext active) {
    final now = context.activeContext;
    if (now?.sessionId != active.sessionId ||
        now?.company.code != active.company.code ||
        now?.company.baseUrl != active.company.baseUrl) {
      throw const ApiException(ApiExceptionType.cancelled);
    }
  }

  String _url(ActiveBusinessContext active, String path) {
    if (!path.startsWith('/api/') ||
        path.contains('://') ||
        path.contains('..')) {
      throw ArgumentError('Expected an installed API path.');
    }
    return '${active.company.baseUrl.replaceAll(RegExp(r'/+$'), '')}$path';
  }
}

Map<String, dynamic> requestObject(Object? value) {
  if (value is! Map) throw const FormatException('Expected an object.');
  return Map<String, dynamic>.from(value);
}

List<Map<String, dynamic>> requestObjects(Object? value) {
  if (value is! List) throw const FormatException('Expected a list.');
  return value.map(requestObject).toList();
}

int requestInt(Map<String, dynamic> value, String key) {
  final item = value[key];
  if (item is! int) throw FormatException('Invalid $key.');
  return item;
}

String requestString(Map<String, dynamic> value, String key) {
  final item = value[key];
  if (item is! String) throw FormatException('Invalid $key.');
  return item;
}

EmployeeIdentity requestEmployee(Map<String, dynamic> value) =>
    EmployeeIdentity(
      id: requestInt(value, 'id'),
      name: requestString(value, 'name'),
      number: value['code'] as String?,
    );
PageResult<T> requestPage<T>(
  Object? value,
  T Function(Map<String, dynamic>) decode,
) {
  final data = requestObject(value);
  return PageResult(
    content: requestObjects(data['content']).map(decode).toList(),
    page: requestInt(data, 'number'),
    size: requestInt(data, 'size'),
    totalElements: requestInt(data, 'total_elements'),
    totalPages: requestInt(data, 'total_pages'),
  );
}

Future<Result<T>> requestResult<T>(Future<T> Function() operation) =>
    guardResult(() async {
      try {
        return await operation();
      } on FormatException {
        throw const ApiException(ApiExceptionType.invalidResponse);
      } on TypeError {
        throw const ApiException(ApiExceptionType.invalidResponse);
      }
    });
