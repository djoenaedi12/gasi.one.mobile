import 'dart:collection';
import 'dart:convert';

import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/module/attendance/model/flex_hour.dart';
import 'package:epeoplecare/module/workflow/repository/app_workflow_repository.dart';
import 'package:epeoplecare/provider/date_provider.dart';

class FlexHourRepository extends AppWorkflowRepository<FlexHour> {

  FlexHourRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/attendance/flex-hour");
  }

  Future<List<FlexHour>> listByEmployeeWorkflowStatusAndDate(Employee employee,List<String> workflowStatus, DateTime startDate, DateTime endDate) async {
    List<FlexHour> result = [];
    Map<String, dynamic> parameters = HashMap();
    parameters.putIfAbsent("employee", () => employee.id);
    parameters.putIfAbsent("workflowStatus", () => workflowStatus);
    parameters.putIfAbsent("effectiveDate", () => DateProvider.convertDate2Str(startDate, "yyyy-MM-dd"));
    parameters.putIfAbsent("expiryDate", () => DateProvider.convertDate2Str(endDate, "yyyy-MM-dd"));
    
    var response = await getApiProvider().get(
      url: "${getBaseUrl()}${getUrl()}/getbyemployeeworkflowstatusanddate${buildParameter(parameters, true)}",
      headers: generateHeader(),
    );

    if(response.statusCode == 200) {
      var json = jsonDecode(response.body);
      if(json['success'] == true) {
        for (var i = 0; i < json['data'].length; i++) {
          FlexHour? item = fromJson(json['data'][i]);
          if(item != null) {
            result.add(item);
          }
        }
      }
    }

    return result;
  }

  @override
  FlexHour? fromJson(Map<String, dynamic>? json) {
    return FlexHour.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(FlexHour entity) {
    return entity.toJson();
  }

}