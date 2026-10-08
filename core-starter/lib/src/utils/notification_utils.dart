import 'dart:convert';

abstract final class NotificationUtils {
  static int stableId(String seed) {
    var hash = 0x811c9dc5;
    for (final codeUnit in seed.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }

  static String encodePayload(Map<String, Object?> data) {
    return jsonEncode(data);
  }

  static Map<String, Object?> decodePayload(String? payload) {
    if (payload == null || payload.trim().isEmpty) {
      return const {};
    }

    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        return Map.unmodifiable(Map<String, Object?>.from(decoded));
      }
      if (decoded is Map) {
        return Map.unmodifiable(
          decoded.map((key, value) => MapEntry(key.toString(), value)),
        );
      }
    } on Object {
      return const {};
    }
    return const {};
  }
}
