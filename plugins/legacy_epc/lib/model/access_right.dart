
import 'package:epeoplecare/model/action.dart';
import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/model/entity.dart';
import 'package:epeoplecare/model/role.dart';

class AccessRight  extends BaseModel {

  Role? role;
  Entity? entity;
  Action? action;

  AccessRight(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.role,
    this.entity,
    this.action,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static AccessRight? fromJson(dynamic json) {
    if (json == null) return null;
    
    return AccessRight(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      Role.fromJson(json['role']),
      Entity.fromJson(json['entity']),
      Action.fromJson(json['action']),
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
      "role": role,
      "entity": entity,
      "action": action,
    };
  }
}
