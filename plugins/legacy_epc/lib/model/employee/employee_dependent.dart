import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/model/company/dependent.dart';
import 'package:epeoplecare/model/employee/employee.dart';

class EmployeeDependent extends BaseModel {
  
  String effectiveDate;
  String? expiryDate;
  Employee? employee;
  Dependent? dependent;
  String name;

  EmployeeDependent(
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
    this.dependent,
    this.name,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static EmployeeDependent? fromJson(dynamic json) {
    if (json == null) return null;
    
    return EmployeeDependent(
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
      Dependent.fromJson(json['dependent']),
      json['name'],
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
      "dependent": dependent,
      "name": name,
    };
  }
}
