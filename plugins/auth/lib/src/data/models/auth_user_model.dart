import 'package:gasione_plugin_auth/src/domain/entities/auth_user.dart';
import 'package:json_annotation/json_annotation.dart';

part 'auth_user_model.g.dart';

@JsonSerializable(checked: true)
class AuthUserModel {
  const AuthUserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.image,
  });

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    return _$AuthUserModelFromJson(json);
  }

  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String image;

  AuthUser toEntity() {
    return AuthUser(
      id: id,
      username: username,
      email: email,
      firstName: firstName,
      lastName: lastName,
      imageUrl: image,
    );
  }

  Map<String, dynamic> toJson() => _$AuthUserModelToJson(this);
}
