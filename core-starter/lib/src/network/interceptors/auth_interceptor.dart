import 'dart:async';

import 'package:dio/dio.dart';
import 'package:gasione_core_starter/src/errors/error_reporter.dart';
import 'package:gasione_core_starter/src/storage/session_store.dart';

typedef SessionExpiredCallback = FutureOr<void> Function();

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._dio, this._refreshDio, this._sessions);

  static const skipAuthKey = 'skipAuth';
  static const _authRetriedKey = 'authRetried';
  static const _sessionVersionKey = 'sessionVersion';

  final Dio _dio;
  final Dio _refreshDio;
  final SessionStore _sessions;

  Future<String?>? _refreshFuture;
  int? _refreshVersion;
  SessionExpiredCallback? onSessionExpired;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      if (options.extra[skipAuthKey] != true) {
        final version = options.extra.putIfAbsent(
          _sessionVersionKey,
          () => _sessions.version,
        ) as int;
        final accessToken = await _sessions.readAccessToken();
        if (!_sessions.isCurrent(version)) {
          handler.reject(_cancelled(options));
          return;
        }
        options.headers.remove('Authorization');
        if (accessToken != null && accessToken.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $accessToken';
        }
      }
      handler.next(options);
    } on Object catch (error, stackTrace) {
      reportUnexpectedError(error, stackTrace);
      handler.reject(
        DioException(
          requestOptions: options,
          error: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final version = response.requestOptions.extra[_sessionVersionKey];
    if (version is int && !_sessions.isCurrent(version)) {
      handler.reject(_cancelled(response.requestOptions));
      return;
    }
    handler.next(response);
  }

  DioException _cancelled(RequestOptions request) => DioException(
    requestOptions: request,
    type: DioExceptionType.cancel,
    message: 'The request belongs to an inactive session.',
  );

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final request = err.requestOptions;
    final shouldRefresh =
        err.response?.statusCode == 401 &&
        request.extra[skipAuthKey] != true &&
        request.extra[_authRetriedKey] != true;
    final version = request.extra[_sessionVersionKey];
    if (!shouldRefresh || version is! int || !_sessions.isCurrent(version)) {
      handler.next(err);
      return;
    }

    final accessToken = await _refreshAccessToken(version);
    if (accessToken == null || !_sessions.isCurrent(version)) {
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

  Future<String?> _refreshAccessToken(int version) {
    final activeRefresh = _refreshFuture;
    if (activeRefresh != null && _refreshVersion == version) {
      return activeRefresh;
    }

    final refresh = _performRefresh(version);
    _refreshVersion = version;
    _refreshFuture = refresh;
    return refresh.whenComplete(() {
      if (identical(_refreshFuture, refresh)) {
        _refreshFuture = null;
      }
    });
  }

  Future<String?> _performRefresh(int version) async {
    try {
      final refreshToken = await _sessions.readRefreshToken();
      if (!_sessions.isCurrent(version)) return null;
      if (refreshToken == null || refreshToken.isEmpty) {
        await _expireSession(version);
        return null;
      }

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
        await _expireSession(version);
        return null;
      }

      final saved = await _sessions.saveTokens(
        version: version,
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );
      return saved ? newAccessToken : null;
    } on DioException catch (error) {
      if (error.response?.statusCode case 400 || 401 || 403) {
        await _expireSession(version);
      }
      return null;
    } on Object catch (error, stackTrace) {
      reportUnexpectedError(error, stackTrace);
      await _expireSession(version);
      return null;
    }
  }

  Future<void> _expireSession(int version) async {
    if (!_sessions.isCurrent(version)) return;
    try {
      await _sessions.expire(version);
    } on Object catch (error, stackTrace) {
      reportUnexpectedError(error, stackTrace);
    }
    if (_sessions.version == version + 1) {
      await onSessionExpired?.call();
    }
  }
}
