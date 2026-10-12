import 'dart:convert';

import 'package:epeoplecare/model/license.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class LicenseRepository extends BaseRepository<License> {
  
  LicenseRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/license");
  }

  Future<License?> getLicense() async {
    License? result;
    var response = await getApiProvider().get(
      url: "${getBaseUrl()}${getUrl()}",
      headers: generateHeader(),
    );

    if(response.statusCode == 200) {
      var json = jsonDecode(response.body);
      if(json['success'] == true) {
        result = fromJson(json['data']);
      }
    }

    return result;
  }

  @override
  License? fromJson(Map<String, dynamic>? json) {
    return License.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(License entity) {
    return entity.toJson();
  }

}