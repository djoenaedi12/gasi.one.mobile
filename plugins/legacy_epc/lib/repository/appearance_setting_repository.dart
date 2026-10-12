import 'dart:convert';

import 'package:epeoplecare/repository/base_repository.dart';
import 'package:epeoplecare/model/appearance_setting.dart';

class AppearanceSettingRepository extends BaseRepository<AppearanceSetting> {
  
  AppearanceSettingRepository(String url, String language) : super(url,"","",language) {
    setUrl("/api/v1/appearance-setting");
  }


  Future<AppearanceSetting?> getAppearanceSetting() async {
    var response = await getApiProvider().get(
      url: "${getBaseUrl()}${getUrl()}/get-appearance-setting",
    );

    AppearanceSetting? result;
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

  Future<dynamic> getAppearanceSettingImage(String imageType) async {
    late dynamic result;
    var response = await getApiProvider().get(
      url: "${getBaseUrl()}${getUrl()}/get-appearance-setting/image?imageType=$imageType",
    );

    if(response.statusCode == 200) {
      result = response.bodyBytes;
    }

    return result;
  }

  @override
  AppearanceSetting? fromJson(Map<String, dynamic>? json) {
    return AppearanceSetting.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(AppearanceSetting entity) {
    return entity.toJson();
  }

}