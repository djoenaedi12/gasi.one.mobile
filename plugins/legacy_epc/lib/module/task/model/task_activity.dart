import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/module/task/model/task.dart';

class TaskActivity extends BaseModel {
  Task? task;
  String? activity;

  TaskActivity(id, creator, creationTime, updater, updateTime, version, customValues, medias, this.task, this.activity)
    : super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static TaskActivity? fromJson(dynamic json) {
    if (json == null) return null;

    return TaskActivity(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      Task.fromJson(json['task']),
      json['activity'],
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
      "activity": activity,
    };
  }
}

class Activity {
  String? project;
  String? subject;
  String? description;
  String? dueDate;
  String? status;
  String? priority;
  String? assignee;
  String? progress;
  String? parent;

  Activity(this.project, this.subject, this.description, this.dueDate, this.status, this.priority, this.assignee, this.progress, this.parent);

  static Activity? fromJson(dynamic json) {
    if (json == null) return null;

    return Activity(
      json['project'],
      json['subject'],
      json['description'],
      json['due_date'],
      json['status'],
      json['priority'],
      json['assignee'],
      json['progress'],
      json['parent'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "project": project,
      "subject": subject,
      "description": description,
      "due_date": dueDate,
      "status": status,
      "priority": priority,
      "assignee": assignee,
      "progress": progress,
      "parent": parent,
    };
  }
}
