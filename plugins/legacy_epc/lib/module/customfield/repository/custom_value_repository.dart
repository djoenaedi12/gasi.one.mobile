import 'dart:collection';

import 'package:epeoplecare/model/sort.dart';
import 'package:epeoplecare/model/sort_direction.dart';
import 'package:epeoplecare/module/customfield/model/custom_value.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class CustomValuesRepository extends BaseRepository<CustomValue> {
  
  CustomValuesRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/customfield/value");
  }

  Future<List<CustomValue>> listByTypeAndRefId(String type, int refId, List<int> customFieldIds) async {
    Map<String, dynamic> parameters = HashMap();
    List<Sort> sorts = [];
    parameters['customizedType'] = type;
    parameters['customizedId'] = refId;
    parameters["customField.in"] = customFieldIds;
    sorts.add(Sort("customField.position", SortDirection.ASC));
    return list(parameters: parameters, sorts: sorts);
  }

  @override
  CustomValue? fromJson(Map<String, dynamic>? json) {
    return CustomValue.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(CustomValue entity) {
    return entity.toJson();  
  }

}