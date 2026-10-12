import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/module/customfield/model/custom_value.dart';

class Media extends BaseModel {
  
  String? modelType;
  int? modelTypeId;
  String name;
  String contentType;
  String extensions;
  int size;
  String? filePath;
  bool oldAttachment=false;
  String? property;

  Media(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.modelType,
    this.modelTypeId,
    this.name,
    this.contentType,
    this.extensions,
    this.size,
    this.filePath,
    this.oldAttachment,
    this.property,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static Media? fromJson(dynamic json) {
    if (json == null) return null;

    List<CustomValue> customValues = [];
    List<Media> medias = [];

    return Media(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      customValues,
      medias,
      json['model_type'],
      json['model_type_id'],
      json['name'],
      json['content_type'],
      json['extensions'],
      json['size'],
      json['file_path'],
      false,
      json['property'],
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
      "model_type": modelType,
      "model_type_id": modelTypeId,
      "name": name,
      "content_type": contentType,
      "extensions": extensions,
      "size": size,
      "file_path": filePath,
      "property": property,
    };
  }
}
