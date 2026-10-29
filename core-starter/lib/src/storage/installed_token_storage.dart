import 'package:shared_preferences/shared_preferences.dart';

import 'token_storage.dart';

/// COMPAT[INSTALLED-DATA]: one backing store and the installed EPC keys.
/// Account history remains owned by authentication; this adapter only handles
/// the active tokens and must not create a second session store.
final class InstalledTokenStorage implements TokenStorage {
  InstalledTokenStorage(this.preferences);
  final SharedPreferences preferences;
  @override
  Future<String?> readAccessToken() async =>
      preferences.getString('access_token');
  @override
  Future<String?> readRefreshToken() async =>
      preferences.getString('refresh_token');
  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    if (!await preferences.setString('access_token', accessToken) ||
        !await preferences.setString('refresh_token', refreshToken)) {
      throw StateError('Could not persist the active session.');
    }
  }

  @override
  Future<void> clearTokens() async {
    for (final key in ['access_token', 'refresh_token', 'isLogin']) {
      if (!await preferences.remove(key)) {
        throw StateError('Could not clear the active session.');
      }
    }
  }
}
