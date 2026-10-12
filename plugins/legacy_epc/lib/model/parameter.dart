import 'package:epeoplecare/model/base_model.dart';

class Parameter extends BaseModel {
  
  String name;
  String? description;
  String value;

  Parameter(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.name,
    this.description,
    this.value,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static Parameter? fromJson(dynamic json) {
    if (json == null) return null;
    
    return Parameter(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      json['name'],
      json['description'],
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
      "name": name,
      "description": description,
      "value": value,
    };
  }
  
}