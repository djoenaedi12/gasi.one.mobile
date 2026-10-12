import 'package:epeoplecare/model/base_model.dart';

class SalaryComponent extends BaseModel {
  String code;
  String name;
  
  SalaryComponent(
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
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static SalaryComponent? fromJson(dynamic json) {
    if (json == null) return null;

    return SalaryComponent(
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
    };
  }
}