import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/module/leave/model/calendar_working.dart';
import 'package:epeoplecare/model/company/gender.dart';
import 'package:epeoplecare/module/leave/model/leave_group.dart';
import 'package:epeoplecare/module/leave/model/leave_value_type.dart';
import 'package:epeoplecare/model/company/marital.dart';
import 'package:epeoplecare/provider/enum_provider.dart';

class LeaveCategory extends BaseModel {
  
  String code;
  String name;
  CalendarWorking? calendarWorking;
  LeaveGroup? leaveGroup;
  double? leaveValue;
  LeaveValueType? leaveValueType;
  Gender? gender;
  Marital? marital;
  double? maxPerPeriod;
  double? maxPerPeriodConvertion;
  LeaveGroup? maxPerPeriodCutLeave;
  double? maxConsecutive;
  double? maxConsecutiveConvertion;
  LeaveGroup? maxConsecutiveCutLeave;
  bool? status;
  bool? scoupe;
  bool? attachmentMandatory;
  bool? allowBackDate;
  bool? allowAdvance;
  bool? asScoupe;
  LeaveGroup? scoupeLeave;
  bool? asBalance;
  bool? asEntitlement;
  bool? allowCollisions;
  
  LeaveCategory(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.code,
    this.name,
    this.calendarWorking,
    this.leaveGroup,
    this.leaveValue,
    this.leaveValueType,
    this.gender,
    this.marital,
    this.maxPerPeriod,
    this.maxPerPeriodConvertion,
    this.maxPerPeriodCutLeave,
    this.maxConsecutive,
    this.maxConsecutiveConvertion,
    this.maxConsecutiveCutLeave,
    this.status,
    this.scoupe,
    this.attachmentMandatory,
    this.allowBackDate,
    this.allowAdvance,
    this.asScoupe,
    this.scoupeLeave,
    this.asBalance,
    this.asEntitlement,
    this.allowCollisions,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static LeaveCategory? fromJson(dynamic json) {
    if (json == null) return null;
    
    return LeaveCategory(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      json['code'],
      json['name'],
      EnumProvider.fromString(CalendarWorking.values, json['calendar_working']),
      LeaveGroup.fromJson(json['leave_group']),
      json['leave_value'],
      EnumProvider.fromString(LeaveValueType.values, json['leave_value_type']),
      EnumProvider.fromString(Gender.values, json['gender']),
      EnumProvider.fromString(Marital.values, json['marital']),
      json['max_per_period'],
      json['max_per_period_convertion'],
      LeaveGroup.fromJson(json['max_per_period_cut_leave']),
      json['max_consecutive'],
      json['max_consecutive_convertion'],
      LeaveGroup.fromJson(json['max_consecutive_cut_leave']),
      json['status'],
      json['scoupe'],
      json['attachment_mandatory'],
      json['allow_back_date'],
      json['allow_advance'],
      json['as_scoupe'],
      LeaveGroup.fromJson(json['scoupe_leave']),
      json['as_balance'],
      json['as_entitlement'],
      json['allow_collisions'],
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
      "code": code,
      "name": name,
      "calendar_working": EnumProvider.convertToString(calendarWorking),
      "leave_group": leaveGroup,
      "leave_value": leaveValue,
      "leave_value_type": EnumProvider.convertToString(leaveValueType),
      "gender": EnumProvider.convertToString(gender),
      "marital": EnumProvider.convertToString(marital),
      "max_per_period": maxPerPeriod,
      "max_per_period_convertion": maxPerPeriodConvertion,
      "max_per_period_cut_leave": maxPerPeriodCutLeave,
      "max_consecutive": maxConsecutive,
      "max_consecutive_convertion": maxConsecutiveConvertion,
      "max_consecutive_cut_leave": maxConsecutiveCutLeave,
      "status": status,
      "scoupe": scoupe,
      "attachment_mandatory": attachmentMandatory,
      "allow_back_date": allowBackDate,
      "allow_advance": allowAdvance,
      "as_scoupe": asScoupe,
      "scoupe_leave": scoupeLeave,
      "as_balance": asBalance,
      "as_entitlement": asEntitlement,
      "allow_collisions": allowCollisions,
    };
  }
}