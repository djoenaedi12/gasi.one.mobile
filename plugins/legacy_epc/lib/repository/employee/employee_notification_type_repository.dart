import 'dart:collection';
import 'dart:convert';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/model/employee/employee_notification_type.dart';
import 'package:epeoplecare/model/response.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class EmployeeNotificationTypeRepository extends BaseRepository<EmployeeNotificationType> {
  
  EmployeeNotificationTypeRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/employee/notification-type");
  }

  Future<List<EmployeeNotificationType>> listByEmployee(Employee employee) async {
    Map<String, dynamic> parameters = HashMap();
    parameters['employee'] = employee.id;
    return await list(parameters: parameters);
  }

  Future<Response> saveAll({
    required Employee employee,
    required List<String> notificationTypes,
  }) async {
    Map<String, dynamic> parameters = HashMap();
    parameters['employee'] = employee;
    parameters['notification_types'] = notificationTypes;
    Response<String> result = Response();
    var response = await getApiProvider().post(
      url: "${getBaseUrl()}${getUrl()}/add-all",
      headers: generateHeader(),
      body: parameters,
    );

    var data = jsonDecode(response.body);
    if(response.statusCode == 200 && data['success'] == true) {
      
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

  @override
  EmployeeNotificationType? fromJson(Map<String, dynamic>? json) {
    return EmployeeNotificationType.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(EmployeeNotificationType entity) {
    return entity.toJson();
  }

}