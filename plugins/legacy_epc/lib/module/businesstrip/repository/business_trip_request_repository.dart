import 'dart:convert';

import 'package:epeoplecare/model/response.dart';
import 'package:epeoplecare/module/businesstrip/model/business_trip_request.dart';
import 'package:epeoplecare/module/workflow/repository/app_workflow_repository.dart';

class BusinessTripRequestRepository extends AppWorkflowRepository<BusinessTripRequest> {

  BusinessTripRequestRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/businesstrip");
  }

  Future<Response> settlement({
    required BusinessTripRequest entity,
    Map<String, String>? headers,
  }) async {
    Response<BusinessTripRequest?> result = Response();
    var response = await getApiProvider().put(
      url: "${getBaseUrl()}${getUrl()}/settlement/${entity.id}",
      headers: headers ?? generateHeader(),
      body: toJson(entity),
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

  Future<bool> isDeductionVisible() async {
    bool result = true;
    var response = await getApiProvider().get(
      url: "${getBaseUrl()}${getUrl()}/deduction-visibility",
      headers: generateHeader(),
    );

    if(response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if(data['success'] == true) {
        result = data['data'];
      }
    }
    return result;
  }

  @override
  BusinessTripRequest? fromJson(Map<String, dynamic>? json) {
    return BusinessTripRequest.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(BusinessTripRequest entity) {
    return entity.toJson();
  }

}