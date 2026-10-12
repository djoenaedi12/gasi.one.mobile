import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/module/loan/model/loan_validation.dart';

class LoanValidationInterest extends BaseModel {
  
  LoanValidation? loanValidation;
  int maxPeriod;
  double interest;

  LoanValidationInterest(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.loanValidation,
    this.maxPeriod,
    this.interest,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static LoanValidationInterest? fromJson(dynamic json) {
    if (json == null) return null;

    return LoanValidationInterest(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      LoanValidation.fromJson(json['loan_validation']),
      json['max_period'],
      json['interest'],
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
      "loan_validation": loanValidation,
      "max_period": maxPeriod,
      "interest": interest,
    };
  }
}
