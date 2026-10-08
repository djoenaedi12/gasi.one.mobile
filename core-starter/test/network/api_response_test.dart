import 'package:flutter_test/flutter_test.dart';
import 'package:gasione_core_starter/gasione_core_starter.dart';

void main() {
  test('parses the standard success envelope', () {
    final response = ApiResponse<Map<String, dynamic>>.fromJson({
      'success': true,
      'message': 'OK',
      'data': {'id': 1},
      'timestamp': '2026-03-03T10:15:30Z',
    }, (data) => Map<String, dynamic>.from(data! as Map));

    expect(response.requireData()['id'], 1);
    expect(response.errors, isEmpty);
    expect(response.timestamp, DateTime.utc(2026, 3, 3, 10, 15, 30));
  });

  test('preserves structured errors from an unsuccessful envelope', () {
    expect(
      () => ApiResponse<void>.fromJson({
        'success': false,
        'message': 'Business rule violation',
        'errors': [
          {
            'code': 'PRIMARY_EXISTS',
            'field': 'primaryIdentity',
            'message': 'Primary identity already exists',
          },
        ],
        'timestamp': '2026-03-03T10:15:30Z',
      }, (_) {}),
      throwsA(
        isA<ApiException>()
            .having((error) => error.code, 'code', 'PRIMARY_EXISTS')
            .having(
              (error) => error.errors.single.field,
              'field',
              'primaryIdentity',
            ),
      ),
    );
  });
}
