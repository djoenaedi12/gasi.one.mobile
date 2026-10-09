import 'package:gasione_core_starter/gasione_core_starter.dart';
import 'package:gasione_plugin_auth/src/data/datasources/auth_remote_data_source.dart';
import 'package:gasione_plugin_auth/src/domain/entities/auth_user.dart';
import 'package:gasione_plugin_auth/src/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remoteDataSource, this._sessionStore);

  final AuthRemoteDataSource _remoteDataSource;
  final SessionStore _sessionStore;

  @override
  Future<Result<AuthUser?>> restoreSession() {
    return guardResult(() async {
      final accessToken = await _sessionStore.readAccessToken();
      final refreshToken = await _sessionStore.readRefreshToken();
      if ((accessToken == null || accessToken.isEmpty) &&
          (refreshToken == null || refreshToken.isEmpty)) {
        return null;
      }

      final user = await _remoteDataSource.getCurrentUser();
      return user.toEntity();
    });
  }

  @override
  Future<Result<AuthUser>> login({
    required String username,
    required String password,
  }) {
    final version = _sessionStore.beginSession();
    return guardResult(() async {
      final response = await _remoteDataSource.login(
        username: username,
        password: password,
      );
      final saved = await _sessionStore.saveTokens(
        version: version,
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
      if (!saved) throw const ApiException(ApiExceptionType.cancelled);
      return response.toEntity();
    });
  }

  @override
  Future<Result<void>> logout() {
    return guardResult(_sessionStore.clearTokens);
  }
}
