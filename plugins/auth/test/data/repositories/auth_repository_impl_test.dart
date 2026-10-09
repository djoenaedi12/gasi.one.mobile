import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gasione_core_starter/gasione_core_starter.dart';
import 'package:gasione_plugin_auth/src/data/datasources/auth_remote_data_source.dart';
import 'package:gasione_plugin_auth/src/data/models/login_response_model.dart';
import 'package:gasione_plugin_auth/src/data/repositories/auth_repository_impl.dart';
import 'package:gasione_plugin_auth/src/domain/entities/auth_user.dart';

const _response = LoginResponseModel(
  id: 1,
  username: 'test',
  email: '',
  firstName: '',
  lastName: '',
  image: '',
  accessToken: 'access',
  refreshToken: 'refresh',
);

void main() {
  test('late login response cannot recreate a logged out session', () async {
    final storage = _Storage();
    final client = ApiClient(tokenStorage: storage, enableLogging: false);
    addTearDown(client.close);
    final remote = _Remote(client);
    final repository = AuthRepositoryImpl(remote, client.sessionStore);
    final pending = repository.login(username: 'test', password: 'test');
    await repository.logout();
    remote.loginResult.complete(_response);
    final result = await pending;
    expect(
      (result as FailureResult<AuthUser>).failure,
      isA<CancelledFailure>(),
    );
    expect(storage.access, isNull);
  });
  test('restore storage failure is returned as a typed failure', () async {
    final storage = _Storage()..failRead = true;
    final client = ApiClient(tokenStorage: storage, enableLogging: false);
    addTearDown(client.close);
    final result = await AuthRepositoryImpl(
      _Remote(client),
      client.sessionStore,
    ).restoreSession();
    expect(result, isA<FailureResult<AuthUser?>>());
  });
}

class _Remote extends AuthRemoteDataSource {
  _Remote(super.client);
  final loginResult = Completer<LoginResponseModel>();
  @override
  Future<LoginResponseModel> login({
    required String username,
    required String password,
  }) => loginResult.future;
}

class _Storage implements TokenStorage {
  String? access;
  String? refresh;
  bool failRead = false;
  @override
  Future<String?> readAccessToken() async {
    if (failRead) throw StateError('Storage unavailable');
    return access;
  }

  @override
  Future<String?> readRefreshToken() async => refresh;
  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    access = accessToken;
    refresh = refreshToken;
  }

  @override
  Future<void> clearTokens() async {
    access = null;
    refresh = null;
  }
}
