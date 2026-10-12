import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/model/company/salary_component.dart';
import 'package:epeoplecare/module/benefit/model/entitled_amount_type.dart';
import 'package:epeoplecare/module/benefit/model/entitled_end_time.dart';
import 'package:epeoplecare/module/benefit/model/entitled_for_new_hired.dart';
import 'package:epeoplecare/module/benefit/model/entitled_start_time.dart';

import 'package:epeoplecare/provider/enum_provider.dart';

class Benefit extends BaseModel {
  
  String code;
  String name;
  EntitledStartTime? entitledStartTime;
  EntitledEndTime? entitledEndTime;
  int? entitledFollowingPeriod;
  int? maximumClaim;
  double paidPercentage;
  bool diffPercentageForDependent;
  Benefit? plafon;
  EntitledAmountType? entitledAmountType;
  EntitledForNewHired? entitledForNewHired;
  EntitledStartTime? entitledStartTimeForNewHired;
  bool requiredAttachment;
  int? maxClaimedDays;
  bool exceedLimit;
  bool nonBalance;
  SalaryComponent? salaryComponent;

  Benefit(
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
    this.entitledStartTime,
    this.entitledEndTime,
    this.entitledFollowingPeriod,
    this.maximumClaim,
    this.paidPercentage,
    this.diffPercentageForDependent,
    this.plafon,
    this.entitledAmountType,
    this.entitledForNewHired,
    this.entitledStartTimeForNewHired,
    this.requiredAttachment,
    this.maxClaimedDays,
    this.exceedLimit,
    this.nonBalance,
    this.salaryComponent,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static Benefit? fromJson(dynamic json) {
    if (json == null) return null;

    return Benefit(
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
      EnumProvider.fromString(EntitledStartTime.values, json['entitled_start_time']),
      EnumProvider.fromString(EntitledEndTime.values, json['entitled_end_time']),
      json['entitled_following_period'],
      json['maximum_claim'],
      json['paid_percentage'],
      json['diff_percentage_for_dependent'],
      Benefit.fromJson(json['plafon']),
      EnumProvider.fromString(EntitledAmountType.values, json['entitled_amount_type']),
      EnumProvider.fromString(EntitledForNewHired.values, json['entitled_for_new_hired']),
      EnumProvider.fromString(EntitledStartTime.values, json['entitled_start_time_for_new_hired']),
      json['required_attachment'],
      json['max_claimed_days'],
      json['exceed_limit'],
      json['non_balance'],
      SalaryComponent.fromJson(json['salary_component']),
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
      "code" : code,
      "name" : name,
      "entitled_start_time" : EnumProvider.convertToString(entitledStartTime),
      "entitled_end_time" : EnumProvider.convertToString(entitledEndTime),
      "entitled_following_period" : entitledFollowingPeriod,
      "maximum_claim" : maximumClaim,
      "paid_percentage" : paidPercentage,
      "diff_percentage_for_dependent" : diffPercentageForDependent,
      "plafon" : plafon,
      "entitled_amount_type" : EnumProvider.convertToString(entitledAmountType),
      "entitled_for_new_hired" : EnumProvider.convertToString(entitledForNewHired),
      "entitled_start_time_for_new_hired" : EnumProvider.convertToString(entitledStartTimeForNewHired),
      "required_attachment" : requiredAttachment,
      "max_claimed_days" : maxClaimedDays,
      "exceed_limit" : exceedLimit,
      "non_balance" : nonBalance,
      "salary_component" : salaryComponent,
    };
  }
}
