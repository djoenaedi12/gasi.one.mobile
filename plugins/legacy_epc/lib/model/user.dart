import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/model/role.dart';
import 'package:epeoplecare/model/user_repository.dart';
import 'package:epeoplecare/provider/enum_provider.dart';

class User extends BaseModel {

  String username;
  String name;
  String? password;
  String? lastLogin;
  int loginFailure = 0;
  bool enabled = true;
  Employee? employee;
  String? expiryDate;
  List<Role> roles = [];
  String? resetPasswordToken;
  String? tokenExpiryDate;
  String? lastUpdatedPassword;
  String? fcmToken;
  String? deviceId;
  UserRepository? userRepository;

  User(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.username,
    this.name,
    this.password,
    this.lastLogin,
    this.loginFailure,
    this.enabled,
    this.employee,
    this.expiryDate,
    this.roles,
    this.resetPasswordToken,
    this.tokenExpiryDate,
    this.lastUpdatedPassword,
    this.fcmToken,
    this.deviceId,
    this.userRepository,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static User? fromJson(dynamic json) {
    if (json == null) return null;
    
    List<Role> roles = [];
    for (var i = 0; i < json['roles'].length; i++) {
      var role = Role.fromJson(json['roles'][i]);
      if(role != null) {
        roles.add(role);
      }
    }

    return User(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      json['username'],
      json['name'],
      json['password'],
      json['last_login'],
      json['login_failure'],
      json['enabled'],
      Employee.fromJson(json['employee']),
      json['expiry_date'],
      roles,
      json['reset_password_token'],
      json['token_expiry_date'],
      json['last_updated_password'],
      json['fcm_token'],
      json['device_id'],
      EnumProvider.fromString(UserRepository.values, json['user_repository']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "creator": creator,
      "creation_time": creationTime,
      "updater": updater,
      "update_time": updateTime,
      "version": version,
      "custom_values": customValues,
      "medias": medias,
      "username": username,
      "name": name,
      "password": password,
      "last_login": lastLogin,
      "login_failure": loginFailure,
      "enabled": enabled,
      "employee": employee,
      "expiry_date": expiryDate,
      "roles": roles,
      "reset_password_token": resetPasswordToken,
      "token_expiry_date": tokenExpiryDate,
      "last_updated_password": lastUpdatedPassword,
      "fcm_token": fcmToken,
      "device_id": deviceId,
      "user_repository": EnumProvider.convertToString(userRepository),
    };
  }

  @override
  String toString() {
    return toJson().toString();
  }

}