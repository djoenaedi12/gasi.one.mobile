import 'package:gasione_plugin_auth/src/domain/entities/auth_user.dart';

sealed class AuthState {
  const AuthState();
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user, {this.isLoggingOut = false});

  final AuthUser user;
  final bool isLoggingOut;
}
