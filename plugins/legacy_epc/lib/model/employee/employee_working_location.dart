import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/model/company/working_location.dart';

class EmployeeWorkingLocation extends BaseModel {
  
  String effectiveDate;
  String? expiryDate;
  Employee? employee;
  WorkingLocation? workingLocation;

  EmployeeWorkingLocation(
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
    this.workingLocation,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static EmployeeWorkingLocation? fromJson(dynamic json) {
    if (json == null) return null;
    
    return EmployeeWorkingLocation(
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
      WorkingLocation.fromJson(json['working_location']),
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
      "working_location": workingLocation,
    };
  }
}
