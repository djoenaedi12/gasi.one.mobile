import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/client.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class ClientRepository extends BaseRepository<Client> {
  
  ClientRepository(String url, String language) : super(url,"","",language) {
    setUrl("/api/v1/client");
  }


  Future<Client?> getClient(String code, String accessToken) async {
    Map<String, String> headers = HashMap();
    headers["Authorization"] = "Bearer $accessToken";
    headers["Content-Type"] = "application/json";
    headers["Device"] = "${Platform.operatingSystem}/${Platform.operatingSystemVersion}";
    headers["DeviceId"] = Config.deviceId;
    headers["Version"] = Config.packageInfo.version;

    var response = await getApiProvider().get(
      url: "${getBaseUrl()}${getUrl()}/getbycode/$code",
      headers: headers,
    );

    Client? result;
    var data = jsonDecode(response.body);
    if(response.statusCode == 200 && data['success'] == true) {
      result = fromJson(data['data']);
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
  Client? fromJson(Map<String, dynamic>? json) {
    return Client.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(Client entity) {
    return entity.toJson();
  }

}