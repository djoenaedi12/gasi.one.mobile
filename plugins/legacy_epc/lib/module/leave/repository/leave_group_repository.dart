import 'dart:convert';

import 'package:epeoplecare/module/leave/model/leave_group.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class LeaveGroupRepository extends BaseRepository<LeaveGroup> {
  
  LeaveGroupRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/leave/group");
  }

  Future<List<LeaveGroup>> listHasCategory() async {
    List<LeaveGroup> result = [];
    var response = await getApiProvider().get(
      url: "${getBaseUrl()}${getUrl()}/gethascategory",
      headers: generateHeader(),
    );

    if(response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if(data['success'] == true) {
        for (var i = 0; i < data['data'].length; i++) {
          LeaveGroup? item = fromJson(data['data'][i]);
          if(item != null) {
            result.add(item);
          }
        }
      }
    }

    return result;
  }

  @override
  LeaveGroup? fromJson(Map<String, dynamic>? json) {
    return LeaveGroup.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(LeaveGroup entity) {
    return entity.toJson();
  }

}