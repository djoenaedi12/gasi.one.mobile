import 'dart:convert';

import 'package:epeoplecare/model/company/announcement.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class AnnouncementRepository extends BaseRepository<Announcement> {
  AnnouncementRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/announcement");
  }

  Future<List<Announcement>> listByEmployee() async {
    List<Announcement> result = [];
    var response = await getApiProvider().get(
      url: "${getBaseUrl()}${getUrl()}/employee",
      headers: generateHeader(),
    );

    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      if (json['success'] == true) {
        for (var i = 0; i < json['data'].length; i++) {
          Announcement? item = fromJson(json['data'][i]);
          if(item != null) {
            result.add(item);
          }
        }
      }
    }

    return result;
  }

  @override
  Announcement? fromJson(Map<String, dynamic>? json) {
    return Announcement.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(Announcement entity) {
    return entity.toJson();
  }
}
