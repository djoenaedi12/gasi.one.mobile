
import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/model/menu.dart';

class Entity  extends BaseModel {

  String name;
  String? description;
  Menu? menu;
  bool dataChangeApproval;

  Entity(
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
    this.menu,
    this.dataChangeApproval,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static Entity? fromJson(dynamic json) {
    if (json == null) return null;
    
    return Entity(
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
      Menu.fromJson(json['menu']),
      json['data_change_approval'],
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
      "menu": menu,
      "data_change_approval": dataChangeApproval,
    };
  }
}
