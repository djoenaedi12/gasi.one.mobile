import 'package:flutter_bloc/flutter_bloc.dart';
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

  void signedIn(AuthUser user) {
    emit(AuthAuthenticated(user));
  }

  Future<void> logout() async {
    await _repository.logout();
    emit(const AuthUnauthenticated());
  }

  void sessionExpired() {
    emit(const AuthUnauthenticated());
  }
}
