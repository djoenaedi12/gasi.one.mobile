import 'dart:collection';
import 'dart:convert';
import 'package:epeoplecare/model/response.dart';
import 'package:epeoplecare/module/leave/model/whereabout_transaction.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class WhereaboutRepository extends BaseRepository<WhereaboutTransaction> {

  WhereaboutRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/leave/whereabouts");
  }

  Future<Response> whereaboutReturn(int id, String reason) async {
    Response<WhereaboutTransaction?> result = Response();
    Map<String, dynamic> parameters = HashMap();
    parameters.putIfAbsent("reason", () => reason);
    var response = await getApiProvider().post(
      url: "${getBaseUrl()}${getUrl()}/return/$id",
      headers: generateHeader(),
      body: parameters,
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

  Future<Response> whereaboutCancel(int id) async {
    Response<WhereaboutTransaction?> result = Response();
    var response = await getApiProvider().post(
      url: "${getBaseUrl()}${getUrl()}/cancel/$id",
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
  WhereaboutTransaction? fromJson(Map<String, dynamic>? json) {
    return WhereaboutTransaction.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(WhereaboutTransaction entity) {
    return entity.toJson();
  }

}