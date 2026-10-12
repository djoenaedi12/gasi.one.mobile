import 'dart:collection';
import 'dart:convert';

import 'package:epeoplecare/module/leave/model/leave_group.dart';
import 'package:epeoplecare/module/leave/model/leave_transaction.dart';
import 'package:epeoplecare/module/leave/model/leave_transaction_scoupe.dart';
import 'package:epeoplecare/module/workflow/repository/app_workflow_repository.dart';

import '../../../model/employee/employee.dart';
import '../../../provider/date_provider.dart';
import '../model/leave_category.dart';

class LeaveTransactionRepository extends AppWorkflowRepository<LeaveTransaction> {
  
  LeaveTransactionRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/leave");
  }

  Future<double> getDuration(Employee employee, LeaveCategory leaveCategory, DateTime dateFrom, DateTime dateTo, List<int> scoupePublicHolidays) async {
    double duration = 0;
    Map<String, dynamic> parameters = HashMap();
    parameters['employee'] = employee.id;
    parameters['leaveCategory'] = leaveCategory.id;
    parameters['dateFrom'] = DateProvider.convertDate2Str(dateFrom, "yyyy-MM-dd HH:mm:ss");
    parameters['dateTo'] = DateProvider.convertDate2Str(dateTo, "yyyy-MM-dd HH:mm:ss");
    parameters['scoupePublicHoliday'] = scoupePublicHolidays;
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

  Future<String> getDateTo(Employee employee, LeaveCategory leaveCategory, DateTime dateFrom, List<int> scoupePublicHolidays) async {
    String dateTo = DateProvider.convertDate2Str(dateFrom, "yyyy-MM-dd HH:mm:ss");
    Map<String, dynamic> parameters = HashMap();
    parameters['employee'] = employee.id;
    parameters['leaveCategory'] = leaveCategory.id;
    parameters['dateFrom'] = DateProvider.convertDate2Str(dateFrom, "yyyy-MM-dd HH:mm:ss");
    parameters['scoupePublicHoliday'] = scoupePublicHolidays;
    var response = await getApiProvider().get(
      url: "${getBaseUrl()}${getUrl()}/date-to${buildParameter(parameters, true)}",
      headers: generateHeader(),
    );

    var data = jsonDecode(response.body);
    if(response.statusCode == 200 && data['success'] == true) {
      dateTo = data['data'];
    }

    return dateTo;
  }

  Future<List<LeaveTransaction>> listByEmployeeWorkflowStatusAndDate(Employee employee, List<String> workflowStatus, DateTime startDate, DateTime endDate) async {
    List<LeaveTransaction> result = [];
    Map<String, dynamic> parameters = HashMap();
    parameters.putIfAbsent("employee", () => employee.id);
    parameters.putIfAbsent("workflowStatus", () => workflowStatus);
    parameters.putIfAbsent("startDate", () => DateProvider.convertDate2Str(startDate, "yyyy-MM-dd"));
    parameters.putIfAbsent("endDate", () => DateProvider.convertDate2Str(endDate, "yyyy-MM-dd"));
    var response = await getApiProvider().get(
      url: "${getBaseUrl()}${getUrl()}/getbyemployeeworkflowstatusanddate${buildParameter(parameters, true)}",
      headers: generateHeader(),
    );

    if(response.statusCode == 200) {
      var json = jsonDecode(response.body);
      if(json['success'] == true) {
        for (var i = 0; i < json['data'].length; i++) {
          LeaveTransaction? item = fromJson(json['data'][i]);
          if(item != null) {
            result.add(item);
          }
        }
      }
    }

    return result;
  }

  Future<List<LeaveTransaction>> listByWorkflowStatusAndDate(List<String> workflowStatus, DateTime startDate, DateTime endDate) async {
    List<LeaveTransaction> result = [];
    Map<String, dynamic> parameters = HashMap();
    parameters.putIfAbsent("workflowStatus", () => workflowStatus);
    parameters.putIfAbsent("startDate", () => DateProvider.convertDate2Str(startDate, "yyyy-MM-dd"));
    parameters.putIfAbsent("endDate", () => DateProvider.convertDate2Str(endDate, "yyyy-MM-dd"));
    parameters.putIfAbsent("column.neq", () => "workflow");
    
    List<String> columns = [];
    columns.add("id");
    columns.add("code");
    columns.add("name");
    columns.add("start_date");
    columns.add("end_date");
    columns.add("leave_category");
    columns.add("employee");
    parameters.putIfAbsent("column", () => columns);

    var response = await getApiProvider().get(
      url: "${getBaseUrl()}${getUrl()}/getbyworkflowstatusanddate${buildParameter(parameters, true)}",
      headers: generateHeader(),
    );

    if(response.statusCode == 200) {
      var json = jsonDecode(response.body);
      if(json['success'] == true) {
        for (var i = 0; i < json['data'].length; i++) {
          LeaveTransaction? item = fromJson(json['data'][i]);
          if(item != null) {
            result.add(item);
          }
        }
      }
    }

    return result;
  }

  Future<List<LeaveTransactionScoupe>> listScoupe(Employee employee, DateTime startDate, DateTime endDate) async {
    List<LeaveTransactionScoupe> result = [];
    Map<String, dynamic> parameters = HashMap();
    parameters.putIfAbsent("employee", () => employee.id);
    parameters.putIfAbsent("startDate", () => DateProvider.convertDate2Str(startDate, "yyyy-MM-dd"));
    parameters.putIfAbsent("endDate", () => DateProvider.convertDate2Str(endDate, "yyyy-MM-dd"));
    var response = await getApiProvider().get(
      url: "${getBaseUrl()}${getUrl()}/getscoupe${buildParameter(parameters, true)}",
      headers: generateHeader(),
    );

    if(response.statusCode == 200) {
      var json = jsonDecode(response.body);
      if(json['success'] == true) {
        for (var i = 0; i < json['data'].length; i++) {
          LeaveTransactionScoupe? item = LeaveTransactionScoupe.fromJson(json['data'][i]);
          if(item != null) {
            result.add(item);
          }
        }
      }
    }

    return result;
  }

  Future<double> getBalance(DateTime startDate, DateTime endDate, LeaveGroup leaveGroup, Employee employee, LeaveTransaction? leaveTransaction, LeaveCategory? leaveCategory) async {
    double balance = 0;
    Map<String, dynamic> parameters = HashMap();
    parameters['dateFrom'] = DateProvider.convertDate2Str(startDate, "yyyy-MM-dd HH:mm:ss");
    parameters['dateTo'] = DateProvider.convertDate2Str(endDate, "yyyy-MM-dd HH:mm:ss");
    parameters['leaveGroup'] = leaveGroup.id;
    parameters['employee'] = employee.id;

    if (leaveTransaction != null) {
      parameters['leaveTransaction'] = leaveTransaction.id;
    }

    if (leaveCategory != null) {
      parameters['leaveCategory'] = leaveCategory.id;
    }

    var response = await getApiProvider().get(
      url: "${getBaseUrl()}${getUrl()}/effective-balance${buildParameter(parameters, true)}",
      headers: generateHeader(),
    );

    var data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      balance = data['data'];
    }

    return balance;
  }

  @override
  LeaveTransaction? fromJson(Map<String, dynamic>? json) {
    return LeaveTransaction.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(LeaveTransaction entity) {
    return entity.toJson();
  }
  
}