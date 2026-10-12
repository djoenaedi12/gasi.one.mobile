import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/module/loan/model/interest_type.dart';
import 'package:epeoplecare/provider/enum_provider.dart';

class LoanType extends BaseModel {
  
  String code;
  String name;
  String? description;
  InterestType? interestType;

  LoanType(
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
    this.description,
    this.interestType,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static LoanType? fromJson(dynamic json) {
    if (json == null) return null;

    return LoanType(
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
      json['description'],
      EnumProvider.fromString(InterestType.values, json['interest_type']),
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
      "description": description,
      "interest_type": EnumProvider.convertToString(interestType),
    };
  }
}
