import 'package:gasione_core_starter/gasione_core_starter.dart';
import 'package:gasione_plugin_auth/src/domain/entities/auth_user.dart';

sealed class LoginState {
  const LoginState();
}

final class LoginInitial extends LoginState {
  const LoginInitial();
}

final class LoginLoading extends LoginState {
  const LoginLoading();
}

final class LoginSuccess extends LoginState {
  const LoginSuccess(this.user);

  final AuthUser user;
}

final class LoginFailure extends LoginState {
  const LoginFailure(this.failure);

  final Failure failure;
}
