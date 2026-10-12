import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/model/employee/employee.dart';

class EmployeeActingPerson extends BaseModel {
  
  Employee? employee;
  Employee? actingPerson;

  EmployeeActingPerson(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.employee,
    this.actingPerson,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static EmployeeActingPerson? fromJson(dynamic json) {
    if (json == null) return null;
    
    return EmployeeActingPerson(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      Employee.fromJson(json['employee']),
      Employee.fromJson(json['acting_person']),
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
      "employee": employee,
      "acting_person": actingPerson,
    };
  }
}
