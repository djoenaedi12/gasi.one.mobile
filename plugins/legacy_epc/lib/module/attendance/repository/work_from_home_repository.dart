import 'dart:collection';
import 'dart:convert';

import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/module/attendance/model/work_from_home.dart';
import 'package:epeoplecare/module/workflow/repository/app_workflow_repository.dart';
import 'package:epeoplecare/provider/date_provider.dart';

class WorkFromHomeRepository extends AppWorkflowRepository<WorkFromHome> {

  WorkFromHomeRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/attendance/wfh");
  }
  
  Future<double> getDuration(Employee employee, DateTime dateFrom, DateTime dateTo) async {
    double duration = 0;
    Map<String, dynamic> parameters = HashMap();
    parameters['employee'] = employee.id;
    parameters['dateFrom'] = DateProvider.convertDate2Str(dateFrom, "yyyy-MM-dd");
    parameters['dateTo'] = DateProvider.convertDate2Str(dateTo, "yyyy-MM-dd");
    var response = await getApiProvider().get(
      url: "${getBaseUrl()}${getUrl()}/duration${buildParameter(parameters, true)}",
      headers: generateHeader(),
    );

    var data = jsonDecode(response.body);
    if(response.statusCode == 200 && data['success'] == true) {
      duration = data['data'];
    }

    return duration;
  }

  @override
  WorkFromHome? fromJson(Map<String, dynamic>? json) {
    return WorkFromHome.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(WorkFromHome entity) {
    return entity.toJson();
  }

}