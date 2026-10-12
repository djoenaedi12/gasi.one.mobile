import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/model/notification_type.dart';
import 'package:epeoplecare/provider/enum_provider.dart';

class EmployeeNotificationType extends BaseModel {
  
  Employee? employee;
  NotificationType? notificationType;

  EmployeeNotificationType(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.employee,
    this.notificationType,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static EmployeeNotificationType? fromJson(dynamic json) {
    if (json == null) return null;
    
    return EmployeeNotificationType(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      Employee.fromJson(json['employee']),
      EnumProvider.fromString(NotificationType.values, json['notification_type']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "creator": creator,
      "creation_time": creationTime,
      "updater": updater,
      "update_time": updateTime,
      "version": version,
      "employee": employee,
      "notification_type": notificationType,
    };
  }
}
