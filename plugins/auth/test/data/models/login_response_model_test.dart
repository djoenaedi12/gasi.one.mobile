import 'package:flutter_test/flutter_test.dart';
import 'package:gasione_plugin_auth/src/data/models/login_response_model.dart';

void main() {
  test('converts a login response to an auth user', () {
    final model = LoginResponseModel.fromJson({
      'id': 1,
      'username': 'emilys',
      'email': 'emily@example.com',
      'firstName': 'Emily',
      'lastName': 'Johnson',
      'image': 'https://example.com/emily.png',
      'accessToken': 'access-token',
      'refreshToken': 'refresh-token',
    });

    final user = model.toEntity();

    expect(user.id, 1);
    expect(user.fullName, 'Emily Johnson');
    expect(model.accessToken, 'access-token');
  });
}
