import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/module/leave/model/leave_group.dart';

class LeaveBalance extends BaseModel {
  
  String effectiveDate;
  String expiryDate;
  Employee? employee;
  LeaveGroup? leaveGroup;
  double entitlement;
  double balance;

  LeaveBalance(
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
    this.leaveGroup,
    this.entitlement,
    this.balance,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static LeaveBalance? fromJson(dynamic json) {
    if (json == null) return null;
    
    return LeaveBalance(
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
      LeaveGroup.fromJson(json['leave_group']),
      json['entitlement'],
      json['balance'],
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
      "leave_group": leaveGroup,
      "entitlement": entitlement,
      "balance": balance,
    };
  }
}