import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/module/task/model/task.dart';
import 'package:epeoplecare/model/employee/employee.dart';

class TaskWatcher extends BaseModel {
  Task? task;
  Employee? employee;

  TaskWatcher(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.task,
    this.employee,
  ) : super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static TaskWatcher? fromJson(dynamic json) {
    if (json == null) return null;

    return TaskWatcher(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      Task.fromJson(json['task']),
      Employee.fromJson(json['employee']),
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
      "employee": employee,
    };
  }
}
