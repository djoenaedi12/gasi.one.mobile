import 'dart:collection';
import 'dart:convert';

import 'package:epeoplecare/module/workflow/model/workflow.dart';
import 'package:epeoplecare/module/workflow/model/workflow_detail.dart';

import '../../../model/pagination.dart';
import '../../../model/response.dart';
import '../../../model/sort.dart';
import '../../../repository/base_repository.dart';

abstract class AppWorkflowRepository<T>  extends BaseRepository<T> {

  AppWorkflowRepository(String url, String accessToken, String refreshToken, String language): super(url, accessToken, refreshToken, language) {
    //
  }

  Future<Pagination<T>> listPaginationPendingApproval({
    Map<String, String>? headers,
    Map<String, dynamic>? parameters,
    List<Sort>? sorts,
    int page = 0,
    int size = 10,
  }) async {
    Pagination<T> result = Pagination();
    var response = await getApiProvider().get(
      url: "${getBaseUrl()}${getUrl()}/approval/pending?page=$page&size=$size${buildParameter(parameters, false)}${buildSort(sorts, false)}",
      headers: headers ?? generateHeader(),
    );

    if(response.statusCode == 200) {
      var json = jsonDecode(response.body);
      if(json['success'] == true) {
        result.fromJson(json['data']);
        for (var i = 0; i < json['data']['content'].length; i++) {
          T? item = fromJson(json['data']['content'][i]);
          if(item != null) {
            result.add(item);
          }
        }
      }
    }

    return result;
  }

  Future<Pagination<T>> listPaginationHistoryApproval({
    Map<String, String>? headers,
    Map<String, dynamic>? parameters,
    List<Sort>? sorts,
    int page = 0,
    int size = 10,
  }) async {
    Pagination<T> result = Pagination();
    var response = await getApiProvider().get(
      url: "${getBaseUrl()}${getUrl()}/approval/history?page=$page&size=$size${buildParameter(parameters, false)}${buildSort(sorts, false)}",
      headers: headers ?? generateHeader(),
    );

    if(response.statusCode == 200) {
      var json = jsonDecode(response.body);
      if(json['success'] == true) {
        result.fromJson(json['data']);
        for (var i = 0; i < json['data']['content'].length; i++) {
          T? item = fromJson(json['data']['content'][i]);
          if(item != null) {
            result.add(item);
          }
        }
      }
    }

    return result;
  }

  Future<Response> approvalProcess(Map<String, dynamic>? parameters) async {
    Response<T?> result = Response();
    var response = await getApiProvider().post(
      url: "${getBaseUrl()}${getUrl()}/approval",
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

  Future<List<WorkflowDetail>> listHistoryApproval(Workflow workflow) async {
    List<WorkflowDetail> result = [];
    var response = await getApiProvider().get(
      url: "${getBaseUrl()}${getUrl()}/approval/history/${workflow.id}",
      headers: generateHeader(),
    );

    if(response.statusCode == 200) {
      var data = jsonDecode(response.body);      
      if(data['success'] == true) {
        for (var i = 0; i < data['data'].length; i++) {
          WorkflowDetail? workflowDetail = WorkflowDetail.fromJson(data['data'][i]);
          if(workflowDetail != null) {
            result.add(workflowDetail);
          }
        }
      }
    }

    return result;
  }

  Future<WorkflowDetail?> findLastWorkflowDetail(Workflow workflow) async {
    WorkflowDetail? result;
    List<WorkflowDetail> results = await listHistoryApproval(workflow);
    if(results.isNotEmpty) {
      result = results[results.length - 1];
    }

    return result;
  }

  Future<List<WorkflowDetail>> listSendBack(Workflow workflow) async {
    List<WorkflowDetail> result = [];
    var response = await getApiProvider().get(
      url: "${getBaseUrl()}${getUrl()}/send-back/${workflow.id}",
      headers: generateHeader(),
    );

    if(response.statusCode == 200) {
      var data = jsonDecode(response.body);      
      if(data['success'] == true) {
        for (var i = 0; i < data['data'].length; i++) {
          WorkflowDetail? workflowDetail = WorkflowDetail.fromJson(data['data'][i]);
          if(workflowDetail != null) {
            result.add(workflowDetail);
          }
        }
      }
    }

    return result;
  }

  Future<T?> findByWorkflow({
    required int workflowId,
    Map<String, String>? headers,
  }) async {
    T? result;
    Map<String, dynamic> parameters = HashMap();
    parameters["workflow"] = workflowId;
    var response = await getApiProvider().get(
      url: "${getBaseUrl()}${getUrl()}/get${buildParameter(parameters, true)}",
      headers: headers ?? generateHeader(),
    );

    if(response.statusCode == 200) {
      var json = jsonDecode(response.body);
      if(json['success'] == true) {
        result = fromJson(json['data']);
      }
    }

    return result;
  }

  Future<Response> revokedRequest(Map<String, dynamic>? parameters) async {
    Response<T> result = Response();
    var response = await getApiProvider().get(
      url: "${getBaseUrl()}${getUrl()}/revoked-request${buildParameter(parameters, true)}",
      headers: generateHeader(),
    );

    var data = jsonDecode(response.body);
    if(response.statusCode == 200 && data['success'] == false) {
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

}