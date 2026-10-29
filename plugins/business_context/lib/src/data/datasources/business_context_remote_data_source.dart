import 'package:gasione_core_starter/gasione_core_starter.dart';

final class BusinessContextRemoteDataSource {
  BusinessContextRemoteDataSource({
    required this.api,
    required this.runtime,
    required this.baseUrl,
    required this.language,
    required this.device,
  });

  final ApiClient api;
  final AppRuntime runtime;
  final String Function() baseUrl;
  final String Function() language;
  final String device;

  Future<Map<String, dynamic>> findUser(String username) =>
      _object('/api/v1/user/get', queryParameters: {'username': username});

  Future<List<Map<String, dynamic>>> usersOnDevice({
    required String deviceId,
    required int? excludingUserId,
  }) async {
    final parameters = <String, Object?>{
      'page': 0,
      'size': -1,
      'deviceId': deviceId,
    };
    if (excludingUserId != null) {
      parameters['id.neq'] = excludingUserId;
    }
    final response = await _get('/api/v1/user', queryParameters: parameters);
    final data = response['data'];
    final content = data is Map ? data['content'] : null;
    if (content is! List) {
      throw const ApiException(ApiExceptionType.invalidResponse);
    }
    return [
      for (final item in content)
        if (item is Map)
          Map<String, dynamic>.from(item)
        else
          throw const ApiException(ApiExceptionType.invalidResponse),
    ];
  }

  Future<void> setDeviceId(String deviceId) => _put(
    '/api/v1/user/set-device-id',
    queryParameters: {'deviceId': deviceId},
  );

  Future<void> setFcm(String token) =>
      _put('/api/v1/user/set-fcm', queryParameters: {'token': token});

  Future<Map<String, dynamic>?> license() => _nullableObject('/api/v1/license');

  Future<String?> parameter(String name) async {
    final data = await _nullableObject(
      '/api/v1/parameter/get',
      queryParameters: {'name': name},
    );
    if (data == null) return null;
    final value = data['value'];
    if (value is! String) {
      throw const ApiException(ApiExceptionType.invalidResponse);
    }
    return value;
  }

  Future<bool> isManager() async {
    final response = await _get('/api/v1/employee/isManager');
    final data = response['data'];
    if (data is! bool) {
      throw const ApiException(ApiExceptionType.invalidResponse);
    }
    return data;
  }

  Future<Map<String, dynamic>> _object(
    String path, {
    Map<String, Object?>? queryParameters,
  }) async =>
      (await _nullableObject(path, queryParameters: queryParameters)) ??
      (throw const ApiException(ApiExceptionType.invalidResponse));

  Future<Map<String, dynamic>?> _nullableObject(
    String path, {
    Map<String, Object?>? queryParameters,
  }) async {
    final response = await _get(path, queryParameters: queryParameters);
    final data = response['data'];
    if (data == null) return null;
    if (data is! Map) {
      throw const ApiException(ApiExceptionType.invalidResponse);
    }
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, Object?>? queryParameters,
  }) async {
    final response = await api.getJson(
      '${_normalizedBaseUrl()}$path',
      queryParameters: queryParameters,
      headers: _headers,
    );
    _ensureSuccess(response);
    return response;
  }

  Future<void> _put(
    String path, {
    required Map<String, Object?> queryParameters,
  }) async {
    final response = await api.putJson(
      '${_normalizedBaseUrl()}$path',
      queryParameters: queryParameters,
      headers: _headers,
    );
    _ensureSuccess(response);
  }

  Map<String, Object?> get _headers => {
    'Device': device,
    'DeviceId': runtime.deviceId,
    'Version': runtime.info.version,
    'Accept-Language': language(),
  };

  String _normalizedBaseUrl() => baseUrl().replaceAll(RegExp(r'/+$'), '');

  void _ensureSuccess(Map<String, dynamic> response) {
    if (response['success'] == true) return;
    throw ApiException(
      ApiExceptionType.badResponse,
      message: response['message'] is String
          ? response['message'] as String
          : null,
    );
  }
}
