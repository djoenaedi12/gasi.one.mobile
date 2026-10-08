import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasione_core_starter/gasione_core_starter.dart';

import '../helpers/memory_token_storage.dart';

void main() {
  test('maps the standard CRUD routes and response envelopes', () async {
    final requests = <RequestOptions>[];
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.httpClientAdapter = _CallbackAdapter((options) async {
      requests.add(options);
      final data = switch ((options.method, options.path)) {
        ('GET', '/categories/1') => _envelope({'id': 1, 'name': 'Hardware'}),
        ('POST', '/categories/query/one') => _envelope({
          'id': 1,
          'name': 'Hardware',
        }),
        ('POST', '/categories/query/list') => _envelope([
          {'id': 1, 'name': 'Hardware'},
        ]),
        ('POST', '/categories/query/page') => _envelope({
          'content': [
            {'id': 1, 'name': 'Hardware'},
          ],
          'page': 0,
          'size': 10,
          'totalElements': 11,
          'totalPages': 2,
        }),
        ('POST', '/categories') => _envelope({'id': 2, 'name': 'Office'}),
        ('PUT', '/categories/2') => _envelope({
          'id': 2,
          'name': 'Office supplies',
        }),
        ('DELETE', '/categories/2') => _envelope(null),
        _ => throw StateError('Unexpected request: ${options.path}'),
      };
      return _jsonResponse(data, 200);
    });
    final client = ApiClient(
      dio: dio,
      tokenStorage: MemoryTokenStorage(),
      enableRetry: false,
      enableLogging: false,
    );
    addTearDown(client.close);
    final dataSource =
        BaseCrudRemoteDataSource<
          _Category,
          int,
          Map<String, Object?>,
          Map<String, Object?>
        >(
          apiClient: client,
          basePath: '/categories/',
          modelFromJson: _Category.fromJson,
          createToJson: (payload) => payload,
          updateToJson: (payload) => payload,
        );

    expect((await dataSource.getById(1)).name, 'Hardware');
    expect((await dataSource.queryOne(const QueryRequest()))?.name, 'Hardware');
    expect(await dataSource.queryList(const QueryRequest()), hasLength(1));
    final page = await dataSource.queryPage(
      const QueryRequest(sorts: [SortOrder.desc('createdAt')]),
    );
    expect(page.content.single.name, 'Hardware');
    expect(page.hasNext, isTrue);
    expect((await dataSource.create({'name': 'Office'})).id, 2);
    expect(
      (await dataSource.update(2, {'name': 'Office supplies'})).name,
      'Office supplies',
    );
    await dataSource.delete(2);

    expect(requests, hasLength(7));
    expect(
      requests[3].data,
      containsPair('sorts', [
        {'field': 'createdAt', 'direction': 'DESC'},
      ]),
    );
  });
}

class _Category {
  const _Category({required this.id, required this.name});

  factory _Category.fromJson(Map<String, dynamic> json) {
    return _Category(id: json['id'] as int, name: json['name'] as String);
  }

  final int id;
  final String name;
}

Map<String, Object?> _envelope(Object? data) => {
  'success': true,
  'message': 'OK',
  'data': data,
  'errors': <Object?>[],
  'timestamp': '2026-03-03T10:15:30Z',
};

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
