import 'package:epeoplecare/model/base_model.dart';

class LeaveGroup extends BaseModel {
  
  String code;
  String name;
  bool nonBalance;
  LeaveGroup? parent;
  int? seqPriority;

  LeaveGroup(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.code,
    this.name,
    this.nonBalance,
    this.parent,
    this.seqPriority,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static LeaveGroup? fromJson(dynamic json) {
    if (json == null) return null;
    
    return LeaveGroup(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      json['code'],
      json['name'],
      json['non_balance'],
      LeaveGroup.fromJson(json['parent']),
      json['seq_priority'],
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
      "code": code,
      "name": name,
      "non_balance": nonBalance,
      "parent": parent,
      "seq_priority": seqPriority,
    };
  }
}