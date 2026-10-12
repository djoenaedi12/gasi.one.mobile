import 'dart:collection';

import 'package:epeoplecare/module/payroll/model/employee_salary_slip.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class EmployeeSalarySlipRepository extends BaseRepository<EmployeeSalarySlip> {
  
  EmployeeSalarySlipRepository(String url, String accessToken, String refreshToken, String language): super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/payroll/employee/report");
  }

  Future<dynamic> print(List<int> ids) async {
    Map<String, dynamic> parameters = HashMap();
    parameters.putIfAbsent("id", () => ids);

    dynamic result;
    var response = await getApiProvider().get(
      url: "${getBaseUrl()}${getUrl()}/print${buildParameter(parameters, true)}",
      headers: generateHeader(),
    );

    if(response.statusCode == 200) {
      result = response.bodyBytes;
    }

    return result;
  }

  @override
  EmployeeSalarySlip? fromJson(Map<String, dynamic>? json) {
    return EmployeeSalarySlip.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(EmployeeSalarySlip entity) {
    return entity.toJson();
  }

}