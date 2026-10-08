import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gasione_core_starter/gasione_core_starter.dart';
import 'package:gasione_plugin_auth/src/domain/repositories/auth_repository.dart';
import 'package:gasione_plugin_auth/src/presentation/cubits/login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit(this._repository) : super(const LoginInitial());

  final AuthRepository _repository;

  void clearFailure() {
    if (state is LoginFailure) {
      emit(const LoginInitial());
    }
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    if (state is LoginLoading) {
      return;
    }

    emit(const LoginLoading());

    final result = await _repository.login(
      username: username.trim(),
      password: password,
    );
    switch (result) {
      case Success(:final data):
        emit(LoginSuccess(data));
      case FailureResult(:final failure):
        emit(LoginFailure(failure));
    }
  }
}
