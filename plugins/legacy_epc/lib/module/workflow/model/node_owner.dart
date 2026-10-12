import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/module/workflow/model/node.dart';

class NodeOwner extends BaseModel {
  
  Node? node;
  int ownerId;

  NodeOwner(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.node,
    this.ownerId,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static NodeOwner? fromJson(dynamic json) {
    if (json == null) return null;

    return NodeOwner(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      Node.fromJson(json['node']),
      json['owner_id'],
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
      "node": node,
      "owner_id": ownerId,
    };
  }
}
