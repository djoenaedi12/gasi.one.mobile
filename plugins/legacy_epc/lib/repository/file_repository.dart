import 'dart:convert';
import 'dart:io';

import 'package:epeoplecare/model/response.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class FileRepository extends BaseRepository<String> {
  
  FileRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/file");
  }
  
  Future<Response> upload(File file, String fileParamName) async {
    Response<String?> result = Response();
    var response = await getApiProvider().postMultipart(
      url: "${getBaseUrl()}${getUrl()}/upload",
      headers: generateHeader(),
      fileParam: file,
      fileParamName: fileParamName,
    );

    var data = jsonDecode(response.body);
    if(response.statusCode == 200 && data['success'] == true) {
      result.fromJson(data, fromJson(data));
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
      url: "${getBaseUrl()}${getUrl()}/download/$fileName",
      // isValidate: false,
    );

    if(response.statusCode == 200) {
      result = response.bodyBytes;
    }

    return result;
  }

  @override
  String? fromJson(Map<String, dynamic>? json) {
    return json!['data'];
  }

  @override
  Map<String, dynamic> toJson(String entity) {
    throw UnimplementedError();
  }
}