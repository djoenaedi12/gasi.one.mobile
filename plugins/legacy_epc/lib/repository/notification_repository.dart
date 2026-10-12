import 'dart:collection';
import 'dart:convert';

import 'package:epeoplecare/model/notification_model.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class NotificationRepository extends BaseRepository<NotificationModel> {
  
  NotificationRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/notification");
  }

  Future<void> markAsRead(int id) async {
    var response = await getApiProvider().put(
      url: "${getBaseUrl()}${getUrl()}/read/$id",
      headers: generateHeader(),
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
  }

  Future<void> markAllAsReadByReceiver(String receiver) async {
    var response = await getApiProvider().put(
      url: "${getBaseUrl()}${getUrl()}/read-all/$receiver",
      headers: generateHeader(),
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
  }

  Future<void> deleteAllByReceiver(String receiver) async {
    var response = await getApiProvider().delete(
      url: "${getBaseUrl()}${getUrl()}/delete-all/$receiver",
      headers: generateHeader(),
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
  }

  Future<List<NotificationModel>> listByReceiverAndUnread(String receiver) async {
    Map<String, dynamic> parameters = HashMap();
    parameters['receiver'] = receiver;
    parameters['readAt'] = "null";
    return list(parameters: parameters);
  }

  @override
  NotificationModel? fromJson(Map<String, dynamic>? json) {
    return NotificationModel.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(NotificationModel entity) {
    return entity.toJson();  
  }

}