import 'package:epeoplecare/model/company/attribute_type.dart';
import 'package:epeoplecare/model/base_model.dart';

class Attribute extends BaseModel {
  
  String code;
  String name;
  AttributeType? attributeType;

  Attribute(
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
    this.attributeType,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static Attribute? fromJson(dynamic json) {
    if (json == null) return null;

    return Attribute(
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
      AttributeType.fromJson(json['attribute_type']),
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
      "attribute_type": attributeType,
    };
  }
}
