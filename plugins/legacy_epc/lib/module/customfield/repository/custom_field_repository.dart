import 'dart:collection';

import 'package:epeoplecare/model/sort.dart';
import 'package:epeoplecare/model/sort_direction.dart';
import 'package:epeoplecare/module/customfield/model/custom_field.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class CustomFieldRepository extends BaseRepository<CustomField> {
  
  CustomFieldRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/customfield");
  }

  Future<List<CustomField>> listByType(String type) async {
    Map<String, dynamic> parameters = HashMap();
    List<Sort> sorts = [];
    parameters['type'] = type;
    sorts.add(Sort("position", SortDirection.ASC));
    return list(parameters: parameters, sorts: sorts);
  }

  @override
  CustomField? fromJson(Map<String, dynamic>? json) {
    return CustomField.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(CustomField entity) {
    return entity.toJson();  
  }

}