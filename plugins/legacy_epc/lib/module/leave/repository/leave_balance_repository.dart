import 'dart:collection';
import 'dart:convert';

import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/module/leave/model/leave_balance.dart';
import 'package:epeoplecare/module/leave/model/leave_group.dart';
import 'package:epeoplecare/provider/date_provider.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class LeaveBalanceRepository extends BaseRepository<LeaveBalance> {
  
  LeaveBalanceRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/leave/balance");
  }

  Future<List<LeaveBalance>> listByEmployeeAndDate(Employee employee, DateTime dateFrom, DateTime dateTo) async {
    List<LeaveBalance> result = [];
    Map<String, dynamic> parameters = HashMap();
    parameters['employee'] = employee.id;
    parameters['effectiveDate'] = DateProvider.convertDate2Str(dateFrom, "yyyy-MM-dd");
    parameters['expiryDate'] = DateProvider.convertDate2Str(dateTo, "yyyy-MM-dd");
    var response = await getApiProvider().get(
      url: "${getBaseUrl()}${getUrl()}/getbyemployeeleavegroupanddate${buildParameter(parameters, true)}",
      headers: generateHeader(),
    );

    if(response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if(data['success'] == true) {
        for (var i = 0; i < data['data'].length; i++) {
          LeaveBalance? item = fromJson(data['data'][i]);
          if(item != null) {
            result.add(item);
          }
        }
      }
    }

    return result;
  }

  Future<List<LeaveBalance>> listByEmployeeAndDateAndLeaveGroup(Employee employee, DateTime dateFrom, DateTime dateTo, LeaveGroup leaveGroup) async {
    List<LeaveBalance> result = [];
    Map<String, dynamic> parameters = HashMap();
    parameters['employee'] = employee.id;
    parameters['leaveGroup'] = leaveGroup.id;
    parameters['effectiveDate'] = DateProvider.convertDate2Str(dateFrom, "yyyy-MM-dd");
    parameters['expiryDate'] = DateProvider.convertDate2Str(dateTo, "yyyy-MM-dd");
    var response = await getApiProvider().get(
      url: "${getBaseUrl()}${getUrl()}/getbyemployeeleavegroupanddate${buildParameter(parameters, true)}",
      headers: generateHeader(),
    );

    if(response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if(data['success'] == true) {
        for (var i = 0; i < data['data'].length; i++) {
          LeaveBalance? item = fromJson(data['data'][i]);
          if(item != null) {
            result.add(item);
          }
        }
      }
    }

    return result;
  }

  @override
  LeaveBalance? fromJson(Map<String, dynamic>? json) {
    return LeaveBalance.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(LeaveBalance entity) {
    return entity.toJson();
  }

}