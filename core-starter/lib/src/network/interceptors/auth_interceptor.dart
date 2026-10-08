import 'dart:async';

import 'package:dio/dio.dart';
import 'package:gasione_core_starter/src/storage/token_storage.dart';

typedef SessionExpiredCallback = FutureOr<void> Function();

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._dio, this._refreshDio, this._tokenStorage);

  static const skipAuthKey = 'skipAuth';
  static const _authRetriedKey = 'authRetried';

  final Dio _dio;
  final Dio _refreshDio;
  final TokenStorage _tokenStorage;

  Future<String?>? _refreshFuture;
  SessionExpiredCallback? onSessionExpired;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[skipAuthKey] != true) {
      final accessToken = await _tokenStorage.readAccessToken();
      if (accessToken != null && accessToken.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final request = err.requestOptions;
    final shouldRefresh =
        err.response?.statusCode == 401 &&
        request.extra[skipAuthKey] != true &&
        request.extra[_authRetriedKey] != true;
    if (!shouldRefresh) {
      handler.next(err);
      return;
    }

    final accessToken = await _refreshAccessToken();
    if (accessToken == null) {
      handler.next(err);
      return;
    }

    request.extra[_authRetriedKey] = true;
    request.headers['Authorization'] = 'Bearer $accessToken';
    try {
      handler.resolve(await _dio.fetch<dynamic>(request));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<String?> _refreshAccessToken() {
    final activeRefresh = _refreshFuture;
    if (activeRefresh != null) {
      return activeRefresh;
    }

    final refresh = _performRefresh();
    _refreshFuture = refresh;
    return refresh.whenComplete(() {
      if (identical(_refreshFuture, refresh)) {
        _refreshFuture = null;
      }
    });
  }

  Future<String?> _performRefresh() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await _expireSession();
      return null;
    }

    try {
      final response = await _refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken, 'expiresInMins': 30},
      );
      final data = response.data;
      final newAccessToken = data?['accessToken'];
      final newRefreshToken = data?['refreshToken'];
      if (newAccessToken is! String ||
          newAccessToken.isEmpty ||
          newRefreshToken is! String ||
          newRefreshToken.isEmpty) {
        await _expireSession();
        return null;
      }

      await _tokenStorage.saveTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );
      return newAccessToken;
    } on DioException catch (error) {
      if (error.response?.statusCode case 400 || 401 || 403) {
        await _expireSession();
      }
      return null;
    } on Object {
      await _expireSession();
      return null;
    }
  }

  Future<void> _expireSession() async {
    await _tokenStorage.clearTokens();
    await onSessionExpired?.call();
  }
}
