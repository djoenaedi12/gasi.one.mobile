import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/model/company/attribute.dart';
import 'package:epeoplecare/module/loan/model/loan_type.dart';

class LoanValidation extends BaseModel {
  
  LoanType? loanType;
  Attribute? attribute;
  int? servicePeriod;
  int? maxPeriod;
  int? maxRequest;
  double? maxAmount;

  LoanValidation(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.loanType,
    this.attribute,
    this.servicePeriod,
    this.maxPeriod,
    this.maxRequest,
    this.maxAmount,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static LoanValidation? fromJson(dynamic json) {
    if (json == null) return null;

    return LoanValidation(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      LoanType.fromJson(json['loan_type']),
      Attribute.fromJson(json['attribute']),
      json['service_period'],
      json['max_period'],
      json['max_request'],
      json['max_amount'],
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
      "loan_type": loanType,
      "attribute": attribute,
      "service_period": servicePeriod,
      "max_period": maxPeriod,
      "max_request": maxRequest,
      "max_amount": maxAmount,
    };
  }
}
