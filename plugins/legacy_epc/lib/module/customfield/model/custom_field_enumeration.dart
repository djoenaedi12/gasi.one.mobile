import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/model/custom_value.dart';
import 'package:epeoplecare/module/customfield/model/custom_field.dart';
import 'package:epeoplecare/module/customfield/model/custom_value.dart';

class CustomFieldEnumeration extends BaseModel {
  
  CustomField? customField;
  String name;
  int enumeration;

  CustomFieldEnumeration(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.customField,
    this.name,
    this.enumeration,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static CustomFieldEnumeration? fromJson(dynamic json) {
    if (json == null) return null;

    List<CustomValue> customValues = [];
    List<Media> medias = [];

    return CustomFieldEnumeration(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      customValues,
      medias,
      CustomField.fromJson(json['custom_field']),
      json['name'],
      json['enumeration'],
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
      "custom_field": customField,
      "name": name,
      "enumeration": enumeration,
    };
  }
}
