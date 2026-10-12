import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/module/workflow/model/node_owner.dart';
import 'package:epeoplecare/module/workflow/model/node_owner_type.dart';
import 'package:epeoplecare/module/workflow/model/node_type.dart';
import 'package:epeoplecare/module/workflow/model/route.dart';

import '../../../provider/enum_provider.dart';

class Node extends BaseModel {
  
  Route? route;
  Node? nextNode1;
  Node? nextNode2;
  NodeType? nodeType;
  NodeOwnerType? nodeOwnerType;
  int positionTop;
  int positionLeft;
  int? connector1;
  int? connector2;
  bool editable;
  bool autoApprove;
  String? name;
  bool override;
  List<NodeOwner> nodeOwners = [];

  Node(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.route,
    this.nextNode1,
    this.nextNode2,
    this.nodeType,
    this.nodeOwnerType,
    this.positionTop,
    this.positionLeft,
    this.connector1,
    this.connector2,
    this.editable,
    this.autoApprove,
    this.name,
    this.override,
    this.nodeOwners,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static Node? fromJson(dynamic json) {
    if (json == null) return null;

    List<NodeOwner> nodeOwners = [];
    if(json['node_owners'] != null) {
      for (var i = 0; i < json['node_owners'].length; i++) {
        NodeOwner? nodeOwner = NodeOwner.fromJson(json['node_owners'][i]);
        if(nodeOwner != null) {
          nodeOwners.add(nodeOwner);
        }
      }
    }
    
    return Node(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      Route.fromJson(json['route']),
      Node.fromJson(json['next_node1']),
      Node.fromJson(json['next_node2']),
      EnumProvider.fromString(NodeType.values, json['node_type']),
      EnumProvider.fromString(NodeOwnerType.values, json['node_owner_type']),
      json['position_top'],
      json['position_left'],
      json['connector1'],
      json['connector2'],
      json['editable'],
      json['auto_approve'],
      json['name'],
      json['override'],
      nodeOwners,
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
      "route": route,
      "next_node1": nextNode1,
      "next_node2": nextNode2,
      "node_type": EnumProvider.convertToString(nodeType),
      "node_owner_type": EnumProvider.convertToString(nodeOwnerType),
      "position_top": positionTop,
      "position_left": positionLeft,
      "connector1": connector1,
      "connector2": connector2,
      "editable": editable,
      "auto_approve": autoApprove,
      "name": name,
      "override": override,
    };
  }
}
