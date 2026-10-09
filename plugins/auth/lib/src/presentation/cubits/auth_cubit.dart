import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gasione_core_api/gasione_core_api.dart';
import 'package:gasione_plugin_auth/src/domain/entities/auth_user.dart';
import 'package:gasione_plugin_auth/src/domain/repositories/auth_repository.dart';
import 'package:gasione_plugin_auth/src/presentation/cubits/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository, AuthUser? initialUser)
    : super(
        initialUser == null
            ? const AuthUnauthenticated()
            : AuthAuthenticated(initialUser),
      );

  final AuthRepository _repository;
  int _version = 0;

  void signedIn(AuthUser user) {
    if (isClosed) return;
    ++_version;
    emit(AuthAuthenticated(user));
  }

  Future<Result<void>> logout() async {
    final current = state;
    if (isClosed || current is! AuthAuthenticated || current.isLoggingOut) {
      return const FailureResult(CancelledFailure());
    }
    final version = ++_version;
    emit(AuthAuthenticated(current.user, isLoggingOut: true));
    final result = await _repository.logout();
    if (!isClosed && version == _version) {
      switch (result) {
        case Success():
          emit(const AuthUnauthenticated());
        case FailureResult():
          emit(AuthAuthenticated(current.user));
      }
    }
    return result;
  }

  void sessionExpired() {
    if (isClosed) return;
    ++_version;
    emit(const AuthUnauthenticated());
  }
}
