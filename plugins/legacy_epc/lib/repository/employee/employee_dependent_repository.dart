import 'dart:collection';
import 'dart:convert';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/model/employee/employee_dependent.dart';
import 'package:epeoplecare/provider/date_provider.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class EmployeeDependentRepository extends BaseRepository<EmployeeDependent> {
  
  EmployeeDependentRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/employee/dependent");
  }

  Future<List<EmployeeDependent>> listByEmployee(Employee employee) async {
    Map<String, dynamic> parameters = HashMap();
    parameters['employee'] = employee.id;
    return await list(parameters: parameters);
  }

  

  Future<List<EmployeeDependent>> listByEmployeeAndDate(Employee employee, DateTime effectiveDate, DateTime expiryDate) async {
    List<EmployeeDependent> result = [];
    Map<String, dynamic> parameters = HashMap();
    parameters.putIfAbsent("employee", () => employee.id);
    parameters.putIfAbsent("effectiveDate", () => DateProvider.convertDate2Str(effectiveDate, "yyyy-MM-dd"));
    parameters.putIfAbsent("expiryDate", () => DateProvider.convertDate2Str(expiryDate, "yyyy-MM-dd"));
    var response = await getApiProvider().get(
      url: "${getBaseUrl()}${getUrl()}/getbyemployeeanddate${buildParameter(parameters, true)}",
      headers: generateHeader(),
    );

    if(response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if(data['success'] == true) {
        for (var i = 0; i < data['data'].length; i++) {
          EmployeeDependent? item = fromJson(data['data'][i]);
          if(item != null) {
            result.add(item);
          }
        }
      }
    }
    return result;
  }

  @override
  EmployeeDependent? fromJson(Map<String, dynamic>? json) {
    return EmployeeDependent.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(EmployeeDependent entity) {
    return entity.toJson();
  }

}