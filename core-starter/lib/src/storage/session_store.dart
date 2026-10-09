import 'package:gasione_core_starter/src/storage/token_storage.dart';

/// Owns session generations and serializes credential writes and deletion.
/// All authentication flows sharing an ApiClient must use its sessionStore.
final class SessionStore {
  SessionStore(this._storage);

  final TokenStorage _storage;
  Future<void> _pending = Future.value();
  int _version = 0;
  bool _blocked = false;

  int get version => _version;

  bool isCurrent(int version) => version == _version;

  /// Invalidates previous login/refresh operations before starting a new login.
  int beginSession() {
    _blocked = true;
    return ++_version;
  }

  Future<String?> readAccessToken() => _read(_storage.readAccessToken);

  Future<String?> readRefreshToken() => _read(_storage.readRefreshToken);

  Future<String?> _read(Future<String?> Function() read) async {
    final version = _version;
    await _pending;
    if (_blocked || !isCurrent(version)) return null;
    final token = await read();
    return !_blocked && isCurrent(version) ? token : null;
  }

  Future<bool> saveTokens({
    required int version,
    required String accessToken,
    required String refreshToken,
  }) => _serialize(() async {
    if (!isCurrent(version)) return false;
    await _storage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    if (!isCurrent(version)) return false;
    _blocked = false;
    return true;
  });

  Future<void> clearTokens() {
    _blocked = true;
    ++_version;
    return _serialize(_storage.clearTokens);
  }

  /// An old request must never expire a newer session.
  Future<bool> expire(int version) async {
    if (!isCurrent(version)) return false;
    await clearTokens();
    return true;
  }

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = _pending.then((_) => operation());
    // Keep subsequent cleanup usable even after a storage operation fails.
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }
}
