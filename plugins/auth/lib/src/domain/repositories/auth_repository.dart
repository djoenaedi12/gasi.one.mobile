import 'package:gasione_core_api/gasione_core_api.dart';
import 'package:gasione_plugin_auth/src/domain/entities/auth_user.dart';

abstract interface class AuthRepository {
  Future<Result<AuthUser?>> restoreSession();

  Future<Result<AuthUser>> login({
    required String username,
    required String password,
  });

  Future<Result<void>> logout();
}
