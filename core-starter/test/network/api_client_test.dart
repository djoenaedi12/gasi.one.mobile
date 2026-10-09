import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasione_core_starter/gasione_core_starter.dart';

import '../helpers/memory_token_storage.dart';

void main() {
  test('refreshes once and replays concurrent unauthorized requests', () async {
    final tokenStorage = MemoryTokenStorage()
      ..accessToken = 'expired-access'
      ..refreshToken = 'valid-refresh';
    var protectedCalls = 0;
    var refreshCalls = 0;

    final requestDio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    requestDio.httpClientAdapter = _CallbackAdapter((options) async {
      if (options.path == '/protected') {
        protectedCalls++;
        if (options.headers['Authorization'] == 'Bearer fresh-access') {
          return _jsonResponse({'value': 'ok'}, 200);
        }
        return _jsonResponse({'message': 'Token expired'}, 401);
      }
      return _jsonResponse({'message': 'Not found'}, 404);
    });

    final refreshDio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    refreshDio.httpClientAdapter = _CallbackAdapter((options) async {
      refreshCalls++;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return _jsonResponse({
        'accessToken': 'fresh-access',
        'refreshToken': 'fresh-refresh',
      }, 200);
    });

    final client = ApiClient(
      dio: requestDio,
      refreshDio: refreshDio,
      tokenStorage: tokenStorage,
      enableRetry: false,
      enableLogging: false,
    );
    addTearDown(client.close);

    final responses = await Future.wait([
      client.getJson('/protected', queryParameters: {'request': 1}),
      client.getJson('/protected', queryParameters: {'request': 2}),
    ]);

    expect(responses.map((item) => item['value']), everyElement('ok'));
    expect(protectedCalls, 4);
    expect(refreshCalls, 1);
    expect(tokenStorage.accessToken, 'fresh-access');
    expect(tokenStorage.refreshToken, 'fresh-refresh');
  });

  test('converts a backend validation response into a typed failure', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.httpClientAdapter = _CallbackAdapter((options) async {
      return _jsonResponse({
        'message': 'Invalid product',
        'errors': [
          {
            'code': 'INVALID_PRODUCT',
            'field': 'title',
            'message': 'Title is invalid',
          },
        ],
      }, 422);
    });
    final client = ApiClient(
      dio: dio,
      tokenStorage: MemoryTokenStorage(),
      enableRetry: false,
      enableLogging: false,
    );
    addTearDown(client.close);

    final result = await guardResult(() => client.getJson('/products'));

    expect(result, isA<FailureResult<Map<String, dynamic>>>());
    final failure = (result as FailureResult<Map<String, dynamic>>).failure;
    expect(failure, isA<ValidationFailure>());
    expect(failure.message, 'Invalid product');
    expect(failure.code, 'INVALID_PRODUCT');
    expect(failure.statusCode, 422);
    expect(failure.errors.single.field, 'title');
  });

  test('does not expose an HTML error page as the failure message', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.httpClientAdapter = _CallbackAdapter((options) async {
      return ResponseBody.fromString(
        '<!doctype html><html><body>Not Found</body></html>',
        404,
        headers: {
          Headers.contentTypeHeader: ['text/html; charset=utf-8'],
        },
      );
    });
    final client = ApiClient(
      dio: dio,
      tokenStorage: MemoryTokenStorage(),
      enableRetry: false,
      enableLogging: false,
    );
    addTearDown(client.close);

    final result = await guardResult(() => client.getJson('/categories'));

    expect(result, isA<FailureResult<Map<String, dynamic>>>());
    final failure = (result as FailureResult<Map<String, dynamic>>).failure;
    expect(failure, isA<NotFoundFailure>());
    expect(failure.message, isNull);
  });

  test('retries an idempotent request after transient server errors', () async {
    var requestCount = 0;
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.httpClientAdapter = _CallbackAdapter((options) async {
      requestCount++;
      return requestCount < 3
          ? _jsonResponse({'message': 'Unavailable'}, 503)
          : _jsonResponse({'value': 'recovered'}, 200);
    });
    final client = ApiClient(
      dio: dio,
      tokenStorage: MemoryTokenStorage(),
      enableLogging: false,
    );
    addTearDown(client.close);

    final response = await client.getJson('/unstable');

    expect(response['value'], 'recovered');
    expect(requestCount, 3);
  });

  test('expires the session when the refresh token is rejected', () async {
    final tokenStorage = MemoryTokenStorage()
      ..accessToken = 'expired-access'
      ..refreshToken = 'rejected-refresh';
    var sessionExpired = false;

    final requestDio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    requestDio.httpClientAdapter = _CallbackAdapter((options) async {
      return _jsonResponse({'message': 'Token expired'}, 401);
    });
    final refreshDio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    refreshDio.httpClientAdapter = _CallbackAdapter((options) async {
      return _jsonResponse({'message': 'Refresh token expired'}, 401);
    });
    final client = ApiClient(
      dio: requestDio,
      refreshDio: refreshDio,
      tokenStorage: tokenStorage,
      enableRetry: false,
      enableLogging: false,
    );
    client.setSessionExpiredHandler(() {
      sessionExpired = true;
    });
    addTearDown(client.close);

    final result = await guardResult(() => client.getJson('/protected'));

    expect(result, isA<FailureResult<Map<String, dynamic>>>());
    expect(
      (result as FailureResult<Map<String, dynamic>>).failure,
      isA<UnauthorizedFailure>(),
    );
    expect(sessionExpired, isTrue);
    expect(tokenStorage.accessToken, isNull);
    expect(tokenStorage.refreshToken, isNull);
  });
  test('in-flight refresh cannot restore tokens after logout', () async {
    final storage = MemoryTokenStorage()
      ..accessToken = 'old'
      ..refreshToken = 'old';
    final started = Completer<void>();
    final response = Completer<ResponseBody>();
    var requests = 0;
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.httpClientAdapter = _CallbackAdapter((_) async {
      requests++;
      return _jsonResponse({'message': 'expired'}, 401);
    });
    final refresh = Dio(BaseOptions(baseUrl: 'https://example.test'));
    refresh.httpClientAdapter = _CallbackAdapter((_) {
      started.complete();
      return response.future;
    });
    final client = ApiClient(
      dio: dio,
      refreshDio: refresh,
      tokenStorage: storage,
      enableRetry: false,
      enableLogging: false,
    );
    addTearDown(client.close);
    final pending = guardResult(() => client.getJson('/protected'));
    await started.future;
    await client.sessionStore.clearTokens();
    response.complete(
      _jsonResponse({'accessToken': 'new', 'refreshToken': 'new'}, 200),
    );
    expect(await pending, isA<FailureResult<Map<String, dynamic>>>());
    expect(storage.accessToken, isNull);
    expect(storage.refreshToken, isNull);
    expect(requests, 1);
  });

  test('rejected old refresh cannot expire a newer login', () async {
    final storage = MemoryTokenStorage()
      ..accessToken = 'old'
      ..refreshToken = 'old';
    final started = Completer<void>();
    final response = Completer<ResponseBody>();
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.httpClientAdapter = _CallbackAdapter(
      (_) async => _jsonResponse({'message': 'expired'}, 401),
    );
    final refresh = Dio(BaseOptions(baseUrl: 'https://example.test'));
    refresh.httpClientAdapter = _CallbackAdapter((_) {
      started.complete();
      return response.future;
    });
    final client = ApiClient(
      dio: dio,
      refreshDio: refresh,
      tokenStorage: storage,
      enableRetry: false,
      enableLogging: false,
    );
    var expired = false;
    client.setSessionExpiredHandler(() => expired = true);
    addTearDown(client.close);
    final pending = guardResult(() => client.getJson('/protected'));
    await started.future;
    final version = client.sessionStore.beginSession();
    await client.sessionStore.saveTokens(
      version: version,
      accessToken: 'new-login',
      refreshToken: 'new-login',
    );
    response.complete(_jsonResponse({'message': 'rejected'}, 401));
    await pending;
    expect(expired, isFalse);
    expect(storage.accessToken, 'new-login');
  });

  test(
    'storage read failure rejects the request instead of leaving it pending',
    () async {
      final client = ApiClient(
        tokenStorage: _FailingStorage(),
        enableRetry: false,
        enableLogging: false,
      );
      addTearDown(client.close);
      final result = await guardResult(() => client.getJson('/protected'))
          .timeout(const Duration(seconds: 2));
      expect(result, isA<FailureResult<Map<String, dynamic>>>());
    },
  );
}

typedef _RequestHandler = Future<ResponseBody> Function(RequestOptions options);

class _CallbackAdapter implements HttpClientAdapter {
  _CallbackAdapter(this._handler);

  final _RequestHandler _handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return _handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(Map<String, Object?> data, int statusCode) {
  return ResponseBody.fromString(
    jsonEncode(data),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

class _FailingStorage extends MemoryTokenStorage {
  @override
  Future<String?> readAccessToken() async =>
      throw StateError('Storage unavailable');
}
