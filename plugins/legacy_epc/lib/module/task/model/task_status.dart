import 'package:epeoplecare/model/base_model.dart';

class TaskStatus extends BaseModel {
  String name;
  int sequence;
  bool closed;
  bool visibled;

  TaskStatus(id, creator, creationTime, updater, updateTime, version, customValues, medias, this.name, this.sequence, this.closed, this.visibled)
    : super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static TaskStatus? fromJson(dynamic json) {
    if (json == null) return null;

    return TaskStatus(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      json['name'],
      json['sequence'],
      json['closed'],
      json['visibled'],
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
      "sequence": sequence,
      "closed": closed,
      "visibled": visibled,
    };
  }
}
