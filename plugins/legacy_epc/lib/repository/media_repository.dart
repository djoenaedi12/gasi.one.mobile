import 'dart:convert';
import 'dart:io';

import 'package:epeoplecare/model/custom_value.dart';
import 'package:epeoplecare/model/response.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class MediaRepository extends BaseRepository<Media> {
  
  MediaRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/media");
  }
  
  Future<Response> upload(File file, String fileParamName, Map<String, String>? parameters) async {
    Response<Media?> result = Response();
    var response = await getApiProvider().postMultipart(
      url: "${getBaseUrl()}${getUrl()}/upload",
      headers: generateHeader(),
      fileParam: file,
      fileParamName: fileParamName,
      parameters: parameters,
    );

    var data = jsonDecode(response.body);
    if(response.statusCode == 200 && data['success'] == true) {
      result.fromJson(data, fromJson(data["data"]));
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

  Future<dynamic> download(String fileName) async {
    late dynamic result;
    var response = await getApiProvider().get(
      headers: generateHeader(),
      url: "${getBaseUrl()}${getUrl()}/downloadByName/$fileName",
    );

    if(response.statusCode == 200) {
      result = response.bodyBytes;
    }

    return result;
  }

  @override
  Media? fromJson(Map<String, dynamic>? json) {
    return Media.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(Media entity) {
    return entity.toJson();
  }
}