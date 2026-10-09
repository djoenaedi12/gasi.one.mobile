import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gasione_core_api/gasione_core_api.dart';
import 'package:gasione_plugin_auth/gasione_plugin_auth.dart';

const _user = AuthUser(
  id: 1,
  username: 'test',
  email: '',
  firstName: '',
  lastName: '',
  imageUrl: '',
);

void main() {
  test(
    'logout failure retains authenticated state and permits retry',
    () async {
      final repository = _Repository();
      final cubit = AuthCubit(repository, _user);
      addTearDown(cubit.close);
      final loggingOut = cubit.logout();
      expect((cubit.state as AuthAuthenticated).isLoggingOut, isTrue);
      repository.logoutResult.complete(const FailureResult(UnknownFailure()));
      expect(await loggingOut, isA<FailureResult<void>>());
      expect(cubit.state, isA<AuthAuthenticated>());
      expect((cubit.state as AuthAuthenticated).isLoggingOut, isFalse);
      repository.logoutResult = Completer();
      final retry = cubit.logout();
      repository.logoutResult.complete(const Success(null));
      await retry;
      expect(cubit.state, isA<AuthUnauthenticated>());
    },
  );
  test(
    'logout completion cannot overwrite a newer login or a closed Cubit',
    () async {
      final repository = _Repository();
      final cubit = AuthCubit(repository, _user);
      final loggingOut = cubit.logout();
      cubit.signedIn(_user);
      repository.logoutResult.complete(const Success(null));
      await loggingOut;
      expect(cubit.state, isA<AuthAuthenticated>());
      repository.logoutResult = Completer();
      final pending = cubit.logout();
      await cubit.close();
      repository.logoutResult.complete(const Success(null));
      await pending;
    },
  );
  test('login completion after page disposal does not emit', () async {
    final repository = _Repository();
    final cubit = LoginCubit(repository);
    final pending = cubit.login(username: 'test', password: 'test');
    await cubit.close();
    repository.loginResult.complete(const Success(_user));
    await pending;
  });
}

class _Repository implements AuthRepository {
  Completer<Result<void>> logoutResult = Completer();
  final loginResult = Completer<Result<AuthUser>>();
  @override
  Future<Result<void>> logout() => logoutResult.future;
  @override
  Future<Result<AuthUser>> login({
    required String username,
    required String password,
  }) => loginResult.future;
  @override
  Future<Result<AuthUser?>> restoreSession() async => const Success(null);
}
