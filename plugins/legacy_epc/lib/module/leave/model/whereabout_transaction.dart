import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/module/leave/model/whereabout_category.dart';
import 'package:epeoplecare/module/leave/model/whereabout_status.dart';
import 'package:epeoplecare/provider/enum_provider.dart';

class WhereaboutTransaction extends BaseModel {
  
  String date;
  String timeFrom;
  String timeTo;
  String duration;
  String? description;
  String? attachment;
  String? actualDate;
  String? actualTime;
  WhereaboutCategory? whereaboutCategory;
  WhereaboutStatus? whereaboutStatus;
  Employee? employee;
  String? destination;
  String? contactPerson;
  String? reason;

  WhereaboutTransaction(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.date,
    this.timeFrom,
    this.timeTo,
    this.duration,
    this.description,
    this.attachment,
    this.actualDate,
    this.actualTime,
    this.whereaboutCategory,
    this.whereaboutStatus,
    this.employee,
    this.destination,
    this.contactPerson,
    this.reason,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static WhereaboutTransaction? fromJson(dynamic json) {
    if (json == null) return null;
    
    return WhereaboutTransaction(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      json['date'],
      json['time_from'],
      json['time_to'],
      json['duration'],
      json['description'],
      json['attachment'],
      json['actual_date'],
      json['actual_time'],
      EnumProvider.fromString(WhereaboutCategory.values, json['whereabout_category']),
      EnumProvider.fromString(WhereaboutStatus.values, json['whereabout_status']),
      Employee.fromJson(json['employee']),
      json['destination'],
      json['contact_person'],
      json['reason'],
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
      "date": date,
      "time_from": timeFrom,
      "time_to": timeTo,
      "duration": duration,
      "description": description,
      "attachment": attachment,
      "actual_date": actualDate,
      "actual_time": actualTime,
      "whereabout_category": EnumProvider.convertToString(whereaboutCategory),
      "whereabout_status": EnumProvider.convertToString(whereaboutStatus),
      "employee": employee,
      "destination": destination,
      "contact_person": contactPerson,
      "reason": reason,
    };
  }
}
