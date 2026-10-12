import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/module/task/model/task.dart';

class TaskRelated extends BaseModel {
  Task? task;
  Task? related;

  TaskRelated(id, creator, creationTime, updater, updateTime, version, customValues, medias, this.task, this.related)
    : super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static TaskRelated? fromJson(dynamic json) {
    if (json == null) return null;

    return TaskRelated(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      Task.fromJson(json['task']),
      Task.fromJson(json['related']),
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
      "task": task,
      "related": related,
    };
  }
}
