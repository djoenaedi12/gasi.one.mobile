import 'dart:convert';

import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/model/pagination.dart';
import 'package:epeoplecare/model/sort.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class EmployeeRepository extends BaseRepository<Employee> {  

  EmployeeRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/employee");
  }

  Future<Pagination<Employee>> listPaginationSubordinate({
    Map<String, String>? headers,
    Map<String, dynamic>? parameters,
    List<Sort>? sorts,
    int page = 0,
    int size = 10,
  }) async {
    Pagination<Employee> result = Pagination();
    var response = await getApiProvider().get(
      url: "${getBaseUrl()}${getUrl()}/subordinate?page=$page&size=$size${buildParameter(parameters, false)}${buildSort(sorts, false)}",
      headers: headers ?? generateHeader(),
    );

    if(response.statusCode == 200) {
      var json = jsonDecode(response.body);
      if(json['success'] == true) {
        result.fromJson(json['data']);
        for (var i = 0; i < json['data']['content'].length; i++) {
          Employee? item = fromJson(json['data']['content'][i]);
          if(item != null) {
            result.add(item);
          }
        }
      }
    }

    return result;
  }

  Future<bool> isManager() async {
    bool result = false;
    var response = await getApiProvider().get(
      url: "${getBaseUrl()}${getUrl()}/isManager",
      headers: generateHeader(),
    );

    if(response.statusCode == 200) {
      var json = jsonDecode(response.body);
      if(json['success'] == true) {
        result = json['data'];
      }
    }

    return result;
  }

  @override
  Employee? fromJson(Map<String, dynamic>? json) {
    return Employee.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(Employee entity) {
    return entity.toJson();
  }

}