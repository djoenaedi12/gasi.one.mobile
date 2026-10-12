import 'package:epeoplecare/model/base_model.dart';

class CACategory extends BaseModel {
  
  String name;

  CACategory(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.name,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static CACategory? fromJson(dynamic json) {
    if (json == null) return null;

    return CACategory(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
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
      "name": name,
    };
  }
}
