import 'dart:convert';
import 'dart:collection';

import 'package:epeoplecare/module/attendance/model/attendance_transaction.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/model/response.dart';
import 'package:epeoplecare/model/sort.dart';
import 'package:epeoplecare/model/sort_direction.dart';
import 'package:epeoplecare/provider/date_provider.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class AttendanceTransactionRepository extends BaseRepository<AttendanceTransaction> {
  
  AttendanceTransactionRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/attendance");
  }

  Future<List<AttendanceTransaction>> listByEmployeeAndDate(Employee employee, DateTime dateFrom, DateTime dateTo) async {
    Map<String, dynamic> parameters = HashMap();
    parameters.putIfAbsent("employee", () => employee.id);
    parameters.putIfAbsent("attendanceDate.gte", () => DateProvider.convertDate2Str(dateFrom, "yyyy-MM-dd HH:mm:ss"));
    parameters.putIfAbsent("attendanceDate.lte", () => DateProvider.convertDate2Str(dateTo, "yyyy-MM-dd HH:mm:ss"));
    return list(parameters: parameters);
  }

  Future<AttendanceTransaction?> getLastByEmployee(Employee employee, DateTime date) async {
    AttendanceTransaction? result;
    Map<String, dynamic> parameters = HashMap();
    parameters.putIfAbsent("employee", () => employee.id);
    parameters.putIfAbsent("attendanceDate", () => DateProvider.convertDate2Str(date, "yyyy-MM-dd"));
    List<Sort> sorts = [];
    sorts.add(Sort("attendanceDate", SortDirection.DESC));
    sorts.add(Sort("attendanceRecord", SortDirection.DESC));
    List<AttendanceTransaction> list = await this.list(parameters: parameters, sorts: sorts, size: 1, page: 0);
    if(list.isNotEmpty) {
      result = list[0];
    }

    return result;
  }

  Future<AttendanceTransaction?> getPrevByEmployee(Employee employee, DateTime date) async {
    AttendanceTransaction? result;
    Map<String, dynamic> parameters = HashMap();
    parameters.putIfAbsent("employee", () => employee.id);
    parameters.putIfAbsent("attendanceDate.lt", () => DateProvider.convertDate2Str(date, "yyyy-MM-dd"));
    List<Sort> sorts = [];
    sorts.add(Sort("attendanceDate", SortDirection.DESC));
    sorts.add(Sort("attendanceRecord", SortDirection.DESC));
    List<AttendanceTransaction> list = await this.list(parameters: parameters, sorts: sorts, size: 1, page: 0);
    if(list.isNotEmpty) {
      result = list[0];
    }

    return result;
  }

  Future<Response> checkInOut(Map<String, dynamic> parameters) async {
    Response<AttendanceTransaction?> result = Response();
    var response = await getApiProvider().post(
      url: "${getBaseUrl()}${getUrl()}/check-inout",
      headers: generateHeader(),
      body: parameters,
    );
    var data = jsonDecode(response.body);
    if(response.statusCode == 200 && data['success'] == true) {
      result.fromJson(data, fromJson(data['data']));
    } else {
      var message = (response.statusCode == 200) ? "${response.statusCode}${data['message']}" : data['message'].toString();
      throw Exception(message);
    }

    return result;
  }

  @override
  AttendanceTransaction? fromJson(Map<String, dynamic>? json) {
    return AttendanceTransaction.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(AttendanceTransaction entity) {
    throw entity.toJson();
  }

}