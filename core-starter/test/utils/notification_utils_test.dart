import 'package:flutter_test/flutter_test.dart';
import 'package:gasione_core_starter/gasione_core_starter.dart';

void main() {
  test('creates a stable positive notification id', () {
    final first = NotificationUtils.stableId('message-123');
    final second = NotificationUtils.stableId('message-123');

    expect(first, second);
    expect(first, greaterThanOrEqualTo(0));
    expect(first, lessThanOrEqualTo(0x7fffffff));
    expect(NotificationUtils.stableId('message-456'), isNot(first));
  });

  test('encodes and decodes notification payload data', () {
    final payload = NotificationUtils.encodePayload({
      'route': '/products',
      'id': 42,
      'enabled': true,
    });

    expect(NotificationUtils.decodePayload(payload), {
      'route': '/products',
      'id': 42,
      'enabled': true,
    });
  });

  test('returns empty data for missing or invalid payloads', () {
    expect(NotificationUtils.decodePayload(null), isEmpty);
    expect(NotificationUtils.decodePayload(''), isEmpty);
    expect(NotificationUtils.decodePayload('not-json'), isEmpty);
    expect(NotificationUtils.decodePayload('[1, 2, 3]'), isEmpty);
  });
}
