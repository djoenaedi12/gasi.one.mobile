import 'package:shared_preferences/shared_preferences.dart';

abstract interface class PreferencesStorage {
  Future<String?> readString(String key);

  Future<void> writeString(String key, String value);
}

/// Uses the existing Flutter SharedPreferences keys and backend.
///
/// Useful when an installed app must retain its preferences during migration.
/// SharedPreferencesAsync's default Android backend may be a different store.
/// COMPAT[INSTALLED-DATA]: this reusable storage implementation is not disposable
/// legacy glue. Keep its backend/keys until an explicit data migration replaces
/// them, including for users upgrading after all EPC source has been removed.
class CachedPreferencesStorage implements PreferencesStorage {
  CachedPreferencesStorage(this._preferences);

  final SharedPreferences _preferences;

  @override
  Future<String?> readString(String key) async => _preferences.getString(key);

  @override
  Future<void> writeString(String key, String value) async {
    if (!await _preferences.setString(key, value)) {
      throw StateError('Unable to persist application preference');
    }
  }
}

class SharedPreferencesStorage implements PreferencesStorage {
  SharedPreferencesStorage({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> readString(String key) {
    return _preferences.getString(key);
  }

  @override
  Future<void> writeString(String key, String value) {
    return _preferences.setString(key, value);
  }
}
