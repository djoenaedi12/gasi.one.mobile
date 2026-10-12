import 'dart:collection';
import 'dart:convert';

import 'package:epeoplecare/model/response.dart';
import 'package:epeoplecare/model/user.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class UserRepository extends BaseRepository<User> {
  
  UserRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/user");
  }

  Future<User?> findByUsername(String username) async {
    Map<String, dynamic> parameters = HashMap();
    parameters['username'] = username;
    return await find(parameters: parameters);
  }

  Future<Response<User?>> setFcm({required String token}) async {
    Response<User?> result = Response();
    var response = await getApiProvider().put(
      url: "${getBaseUrl()}${getUrl()}/set-fcm?token=$token",
      headers: generateHeader(),
    );

    var data = jsonDecode(response.body);
    if(response.statusCode == 200 && data['success'] == true) {
      result.fromJson(data, fromJson(data['data']));
    } else {
      var message = "";
      if(data['message'] != null) {
        message = (response.statusCode == 200) ? "${response.statusCode}${data['message']}" : data['message'].toString();
      } else if (data['error_description'] != null) {
        message = (response.statusCode == 200) ? "${response.statusCode}${data['error_description']}" : data['error_description'].toString();
      }
      throw Exception(message);
    }

    return result;
  }

  Future<Response<User?>> setDeviceId({required String deviceId}) async {
    Response<User?> result = Response();
    var response = await getApiProvider().put(
      url: "${getBaseUrl()}${getUrl()}/set-device-id?deviceId=$deviceId",
      headers: generateHeader(),
    );

    var data = jsonDecode(response.body);
    if(response.statusCode == 200 && data['success'] == true) {
      result.fromJson(data, fromJson(data['data']));
    } else {
      var message = "";
      if(data['message'] != null) {
        message = (response.statusCode == 200) ? "${response.statusCode}${data['message']}" : data['message'].toString();
      } else if (data['error_description'] != null) {
        message = (response.statusCode == 200) ? "${response.statusCode}${data['error_description']}" : data['error_description'].toString();
      }
      throw Exception(message);
    }

    return result;
  }

  @override
  User? fromJson(Map<String, dynamic>? json) {
    return User.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(User entity) {
    return entity.toJson();
  }

}