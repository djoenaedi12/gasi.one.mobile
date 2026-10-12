import 'dart:collection';
import 'dart:convert';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/model/employee/employee_schedule.dart';
import 'package:epeoplecare/provider/date_provider.dart';
import 'package:epeoplecare/repository/base_repository.dart';
import 'package:epeoplecare/model/schedule_shift_generated.dart';
import 'package:epeoplecare/model/schedule_generated.dart';
import 'package:epeoplecare/model/company/shift.dart';

class EmployeeScheduleRepository extends BaseRepository<EmployeeSchedule> {
  
  EmployeeScheduleRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/employee/schedule");
  }

  Future<List<EmployeeSchedule>> listByEmployee(Employee employee) async {
    Map<String, dynamic> parameters = HashMap();
    parameters['employee'] = employee.id;
    return await list(parameters: parameters);
  }

  

  Future<List<EmployeeSchedule>> listByEmployeeAndDate(Employee employee, DateTime effectiveDate, DateTime expiryDate) async {
    List<EmployeeSchedule> result = [];
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
          EmployeeSchedule? item = fromJson(data['data'][i]);
          if(item != null) {
            result.add(item);
          }
        }
      }
    }
    return result;
  }

  Future<List<ScheduleShiftGenerated>> generateShiftSchedule(Employee employee, DateTime dateFrom, DateTime dateTo) async {
    List<ScheduleShiftGenerated> result = [];
    Map<String, dynamic> parameters = HashMap();
    parameters.putIfAbsent("employee", () => employee.id);
    parameters.putIfAbsent("dateFrom", () => DateProvider.convertDate2Str(dateFrom, "yyyy-MM-dd"));
    parameters.putIfAbsent("dateTo", () => DateProvider.convertDate2Str(dateTo, "yyyy-MM-dd"));
    var response = await getApiProvider().get(
      url: "${getBaseUrl()}${getUrl()}/generateShiftSchedule${buildParameter(parameters, true)}",
      headers: generateHeader(),
    );

    if(response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if(data['success'] == true) {
        for (var i = 0; i < data['data'].length; i++) {
          ScheduleShiftGenerated? item = ScheduleShiftGenerated.fromJson(data['data'][i]);
          if(item != null) {
            result.add(item);
          }
        }
      }
    }
    return result;
  }

  Future<List<ScheduleGenerated>> generateSchedule(Employee employee, DateTime dateFrom, DateTime dateTo) async {
    List<ScheduleGenerated> result = [];
    Map<String, dynamic> parameters = HashMap();
    parameters.putIfAbsent("employee", () => employee.id);
    parameters.putIfAbsent("dateFrom", () => DateProvider.convertDate2Str(dateFrom, "yyyy-MM-dd"));
    parameters.putIfAbsent("dateTo", () => DateProvider.convertDate2Str(dateTo, "yyyy-MM-dd"));
    var response = await getApiProvider().get(
      url: "${getBaseUrl()}${getUrl()}/generateSchedule${buildParameter(parameters, true)}",
      headers: generateHeader(),
    );

    if(response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if(data['success'] == true) {
        for (var i = 0; i < data['data'].length; i++) {
          ScheduleGenerated? item = ScheduleGenerated.fromJson(data['data'][i]);
          if(item != null) {
            result.add(item);
          }
        }
      }
    }
    return result;
  }

  Future<Shift?> getShift(Employee employee, DateTime date) async {
    Shift? result;
    Map<String, dynamic> parameters = HashMap();
    parameters.putIfAbsent("employee", () => employee.id);
    parameters.putIfAbsent("date", () => DateProvider.convertDate2Str(date, "yyyy-MM-dd"));
    var response = await getApiProvider().get(
      url: "${getBaseUrl()}${getUrl()}/getShift${buildParameter(parameters, true)}",
      headers: generateHeader(),
    );

    if(response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if(data['success'] == true) {
        result = Shift.fromJson(data['data']);
      }
    }
    return result;
  }

  @override
  EmployeeSchedule? fromJson(Map<String, dynamic>? json) {
    return EmployeeSchedule.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(EmployeeSchedule entity) {
    return entity.toJson();
  }

}