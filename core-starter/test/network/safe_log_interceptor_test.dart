import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasione_core_starter/src/network/interceptors/safe_log_interceptor.dart';

void main() {
  test(
    'logs metadata without URI, header, payload or exception secrets',
    () async {
      final lines = <String>[];
      final dio = Dio()..httpClientAdapter = _ResponseAdapter(503);
      dio.interceptors.add(SafeLogInterceptor(log: lines.add));
      addTearDown(() => dio.close(force: true));
      Future<Response<dynamic>> request() => dio.get<dynamic>(
        'https://user:credential@tenant.test/media/signed-secret',
        queryParameters: {'remark': 'private', 'signature': 'signed'},
        data: {'pin': '123456', 'otp': '654321', 'client_secret': 'secret'},
        options: Options(
          headers: {'Authorization': 'Bearer secret', 'X-Custom': 'sensitive'},
        ),
      );
      await expectLater(request(), throwsA(isA<DioException>()));
      dio.httpClientAdapter = _ResponseAdapter(200);
      await request();
      expect(lines, [
        '--> GET',
        '<-- GET ERROR 503 badResponse',
        '--> GET',
        '<-- GET 200',
      ]);
    },
  );
}

class _ResponseAdapter implements HttpClientAdapter {
  _ResponseAdapter(this.status);
  final int status;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async => ResponseBody.fromString(
    '{"remark":"personal","url":"https://secret"}',
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
  @override
  void close({bool force = false}) {}
}
