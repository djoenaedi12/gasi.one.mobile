import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/model/custom_value.dart';
import 'package:epeoplecare/module/customfield/model/custom_field.dart';

class CustomValue extends BaseModel {
  
  CustomField? customField;
  String customizedType;
  int? customizedId;
  String? value;

  CustomValue(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.customField,
    this.customizedType,
    this.customizedId,
    this.value,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static CustomValue? fromJson(dynamic json) {
    if (json == null) return null;

    List<CustomValue> customValues = [];
    List<Media> medias = [];

    return CustomValue(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      customValues,
      medias,
      CustomField.fromJson(json['custom_field']),
      json['customized_type'],
      json['customized_id'],
      json['value'],
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
      "customized_type": customizedType,
      "customized_id": customizedId,
      "value": value,
    };
  }
}
