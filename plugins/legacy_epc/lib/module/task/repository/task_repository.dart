import 'dart:convert';

import 'package:epeoplecare/module/task/model/task.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class TaskRepository extends BaseRepository<Task> {
  TaskRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/task");
  }

  Future<List<Task>> getListRelated(Map<String, dynamic> parameters) async {
    List<Task> result = [];
    var response = await getApiProvider().get(url: "${getBaseUrl()}${getUrl()}/getrelated${buildParameter(parameters, true)}", headers: generateHeader());

    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      if (json['success'] == true) {
        for (var i = 0; i < json['data'].length; i++) {
          Task? item = fromJson(json['data'][i]);
          if (item != null) {
            result.add(item);
          }
        }
      }
    }

    return result;
  }

  @override
  Task? fromJson(Map<String, dynamic>? json) {
    return Task.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(Task entity) {
    return entity.toJson();
  }
}
