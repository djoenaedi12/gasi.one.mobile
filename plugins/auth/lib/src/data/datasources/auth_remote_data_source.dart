import 'package:gasione_core_starter/gasione_core_starter.dart';
import 'package:gasione_plugin_auth/src/data/models/auth_user_model.dart';
import 'package:gasione_plugin_auth/src/data/models/login_response_model.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<LoginResponseModel> login({
    required String username,
    required String password,
  }) async {
    final json = await _apiClient.postJson(
      '/auth/login',
      data: {'username': username, 'password': password, 'expiresInMins': 30},
      authenticated: false,
    );

    return ApiResponseParser.object(json, LoginResponseModel.fromJson);
  }

  Future<AuthUserModel> getCurrentUser() async {
    final json = await _apiClient.getJson('/auth/me');
    return ApiResponseParser.object(json, AuthUserModel.fromJson);
  }
}
