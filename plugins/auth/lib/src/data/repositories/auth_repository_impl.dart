import 'package:gasione_core_starter/gasione_core_starter.dart';
import 'package:gasione_plugin_auth/src/data/datasources/auth_remote_data_source.dart';
import 'package:gasione_plugin_auth/src/domain/entities/auth_user.dart';
import 'package:gasione_plugin_auth/src/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remoteDataSource, this._tokenStorage);

  final AuthRemoteDataSource _remoteDataSource;
  final TokenStorage _tokenStorage;

  @override
  Future<Result<AuthUser?>> restoreSession() async {
    final accessToken = await _tokenStorage.readAccessToken();
    final refreshToken = await _tokenStorage.readRefreshToken();
    if ((accessToken == null || accessToken.isEmpty) &&
        (refreshToken == null || refreshToken.isEmpty)) {
      return const Success(null);
    }

    return guardResult(() async {
      final user = await _remoteDataSource.getCurrentUser();
      return user.toEntity();
    });
  }

  @override
  Future<Result<AuthUser>> login({
    required String username,
    required String password,
  }) {
    return guardResult(() async {
      final response = await _remoteDataSource.login(
        username: username,
        password: password,
      );
      await _tokenStorage.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
      return response.toEntity();
    });
  }

  @override
  Future<Result<void>> logout() {
    return guardResult(_tokenStorage.clearTokens);
  }
}
