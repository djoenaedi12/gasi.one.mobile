import 'dart:convert';

import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/module/workflow/model/workflow_detail.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class WorkflowDetailRepository extends BaseRepository<WorkflowDetail> {

  WorkflowDetailRepository(String url, String accessToken, String refreshToken, String language): super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/workflow/detail");
  }

  Future<List<WorkflowDetail>> listSendBack({
    required int workflowId
  }) async {
    List<WorkflowDetail> result = [];
    var response = await getApiProvider().get(
      url: "${getBaseUrl()}${getUrl()}/send-back/$workflowId",
      headers: generateHeader(),
    );

    if(response.statusCode == 200) {
      var json = jsonDecode(response.body);
      if(json['success'] == true) {
        for (var i = 0; i < json['data'].length; i++) {
          WorkflowDetail? item = fromJson(json['data'][i]);
          if(item != null) {
            result.add(item);
          }
        }
      }
    }

    return result;
  }

  Future<List<Employee>> listApproval({
    required int workflowId
  }) async {
    List<Employee> result = [];
    var response = await getApiProvider().get(
      url: "${getBaseUrl()}${getUrl()}/approval/$workflowId",
      headers: generateHeader(),
    );

    if(response.statusCode == 200) {
      var json = jsonDecode(response.body);
      if(json['success'] == true) {
        for (var i = 0; i < json['data'].length; i++) {
          Employee? item = Employee.fromJson(json['data'][i]);
          if(item != null) {
            result.add(item);
          }
        }
      }
    }

    return result;
  }

  @override
  WorkflowDetail? fromJson(Map<String, dynamic>? json) {
    return WorkflowDetail.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(WorkflowDetail entity) {
    return entity.toJson();
  }
}