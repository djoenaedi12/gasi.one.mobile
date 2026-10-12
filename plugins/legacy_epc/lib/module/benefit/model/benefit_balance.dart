import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/module/benefit/model/benefit.dart';

class BenefitBalance extends BaseModel {
  
  String effectiveDate;
  String expiryDate;
  Employee? employee;
  Benefit? benefit;
  double entitlement;
  double used;

  BenefitBalance(
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
    this.benefit,
    this.entitlement,
    this.used,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static BenefitBalance? fromJson(dynamic json) {
    if (json == null) return null;
    
    return BenefitBalance(
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
      Benefit.fromJson(json['benefit']),
      json['entitlement'],
      json['used'],
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
      "benefit": benefit,
      "entitlement": entitlement,
      "used": used,
    };
  }
}