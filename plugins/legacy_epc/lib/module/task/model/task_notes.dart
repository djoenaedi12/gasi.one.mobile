import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/module/task/model/task.dart';

class TaskNotes extends BaseModel {
  Task? task;
  String notes;

  TaskNotes(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.task,
    this.notes,
  ) : super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static TaskNotes? fromJson(dynamic json) {
    if (json == null) return null;

    return TaskNotes(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      Task.fromJson(json['task']),
      json['notes'],
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
      "notes": notes,
    };
  }
}
