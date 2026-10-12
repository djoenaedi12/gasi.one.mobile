import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/model/custom_value.dart';
import 'package:epeoplecare/module/customfield/model/custom_field_enumeration.dart';
import 'package:epeoplecare/module/customfield/model/custom_field_type.dart';
import 'package:epeoplecare/module/customfield/model/custom_value.dart';
import 'package:epeoplecare/provider/enum_provider.dart';

class CustomField extends BaseModel {
  
  String type;
  String name;
  CustomFieldType? customFieldType;
  int? minLength;
  int? maxLength;
  bool required;
  String? defaultValue;
  String? description;
  List<CustomFieldEnumeration> customFieldEnumerations = [];
  String? possibleValues;
  int position;
  bool editable;

  CustomField(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.type,
    this.name,
    this.customFieldType,
    this.minLength,
    this.maxLength,
    this.required,
    this.defaultValue,
    this.description,
    this.customFieldEnumerations,
    this.possibleValues,
    this.position,
    this.editable,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static CustomField? fromJson(dynamic json) {
    if (json == null) return null;

    List<CustomValue> customValues = [];
    List<Media> medias = [];

    List<CustomFieldEnumeration> customFieldEnumerations = [];
    if(json['custom_field_enumerations'] != null) {
      for (var i = 0; i < json['custom_field_enumerations'].length; i++) {
        CustomFieldEnumeration? cfe = CustomFieldEnumeration.fromJson(json['custom_field_enumerations'][i]);
        if(cfe != null) {
          customFieldEnumerations.add(cfe);
        }
      }
    }

    return CustomField(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      customValues,
      medias,
      json['type'],
      json['name'],
      EnumProvider.fromString(CustomFieldType.values, json['custom_field_type']),
      json['min_length'],
      json['max_length'],
      json['required'],
      json['default_value'],
      json['description'],
      customFieldEnumerations,
      json['possible_values'],
      json['position'],
      json['editable'],
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
      "type": type,
      "name": name,
      "custom_field_type": EnumProvider.convertToString(customFieldType),
      "min_length": minLength,
      "max_length": maxLength,
      "required": required,
      "default_value": defaultValue,
      "description": description,
      "custom_field_enumerations": customFieldEnumerations,
      "possible_values": possibleValues,
      "position": position,
      "editable": editable,
    };
  }
}
