import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/model/company/schedule.dart';

class EmployeeSchedule extends BaseModel {
  
  String effectiveDate;
  String? expiryDate;
  Employee? employee;
  Schedule? schedule;

  EmployeeSchedule(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.effectiveDate,
    this.expiryDate,
    this.employee,
    this.schedule,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static EmployeeSchedule? fromJson(dynamic json) {
    if (json == null) return null;
    
    return EmployeeSchedule(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      json['effective_date'],
      json['expiry_date'],
      Employee.fromJson(json['employee']),
      Schedule.fromJson(json['schedule']),
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
      "custom_values": customValues,
      "medias": medias,
      "effective_date": effectiveDate,
      "expiry_date": expiryDate,
      "employee": employee,
      "schedule": schedule,
    };
  }
}
