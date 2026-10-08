import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gasione_core_starter/src/network/api_error_mapper.dart';
import 'package:gasione_core_starter/src/network/api_exception.dart';
import 'package:gasione_core_starter/src/network/interceptors/auth_interceptor.dart';
import 'package:gasione_core_starter/src/network/interceptors/retry_interceptor.dart';
import 'package:gasione_core_starter/src/network/interceptors/safe_log_interceptor.dart';
import 'package:gasione_core_starter/src/storage/token_storage.dart';

class ApiClient {
  ApiClient({
    Dio? dio,
    Dio? refreshDio,
    TokenStorage? tokenStorage,
    String baseUrl = '',
    bool enableRetry = true,
    bool enableLogging = kDebugMode,
  }) : _dio = dio ?? Dio(_baseOptions(baseUrl)),
       _refreshDio = refreshDio ?? Dio(_baseOptions(baseUrl)) {
    _authInterceptor = AuthInterceptor(
      _dio,
      _refreshDio,
      tokenStorage ?? SecureTokenStorage(),
    );

    _dio.interceptors.add(_authInterceptor);
    if (enableRetry) {
      _dio.interceptors.add(RetryInterceptor(_dio));
    }
    if (enableLogging) {
      _dio.interceptors.add(SafeLogInterceptor());
    }
  }

  final Dio _dio;
  final Dio _refreshDio;
  late final AuthInterceptor _authInterceptor;

  static BaseOptions _baseOptions(String baseUrl) {
    return BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    );
  }

  void setSessionExpiredHandler(SessionExpiredCallback callback) {
    _authInterceptor.onSessionExpired = callback;
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? queryParameters,
    CancelToken? cancelToken,
    bool authenticated = true,
  }) {
    return _jsonRequest(
      () => _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        options: _options(authenticated),
      ),
    );
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, Object?>? data,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    bool authenticated = true,
  }) {
    return _jsonRequest(
      () => _dio.post<dynamic>(
        path,
        data: data,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        options: _options(authenticated),
      ),
    );
  }

  Future<Map<String, dynamic>> putJson(
    String path, {
    Map<String, Object?>? data,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    bool authenticated = true,
  }) {
    return _jsonRequest(
      () => _dio.put<dynamic>(
        path,
        data: data,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        options: _options(authenticated),
      ),
    );
  }

  Future<Map<String, dynamic>> deleteJson(
    String path, {
    Map<String, Object?>? data,
    CancelToken? cancelToken,
    bool authenticated = true,
  }) {
    return _jsonRequest(
      () => _dio.delete<dynamic>(
        path,
        data: data,
        cancelToken: cancelToken,
        options: _options(authenticated),
      ),
    );
  }

  Future<Map<String, dynamic>> upload(
    String path, {
    required FormData data,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    bool authenticated = true,
  }) {
    return _jsonRequest(
      () => _dio.post<dynamic>(
        path,
        data: data,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        options: _options(authenticated),
      ),
    );
  }

  Future<void> download(
    String path,
    String savePath, {
    Map<String, Object?>? queryParameters,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
    bool authenticated = true,
  }) {
    return _guard(() async {
      await _dio.download(
        path,
        savePath,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
        options: _options(authenticated),
      );
    });
  }

  Future<Map<String, dynamic>> _jsonRequest(
    Future<Response<dynamic>> Function() request,
  ) {
    return _guard(() async {
      final response = await request();
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      throw const ApiException(ApiExceptionType.invalidResponse);
    });
  }

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on ApiException {
      rethrow;
    } on DioException catch (error) {
      throw ApiErrorMapper.fromDio(error);
    }
  }

  Options _options(bool authenticated) {
    return Options(
      extra: {if (!authenticated) AuthInterceptor.skipAuthKey: true},
    );
  }

  void close() {
    _dio.close(force: true);
    if (!identical(_dio, _refreshDio)) {
      _refreshDio.close(force: true);
    }
  }
}
