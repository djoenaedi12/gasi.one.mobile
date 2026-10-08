import 'package:gasione_core_starter/gasione_core_starter.dart';

class MemoryPreferencesStorage implements PreferencesStorage {
  final Map<String, String> values = {};

  @override
  Future<String?> readString(String key) async => values[key];

  @override
  Future<void> writeString(String key, String value) async {
    values[key] = value;
  }
}
