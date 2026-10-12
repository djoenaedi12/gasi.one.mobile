import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/module/task/model/project.dart';
import 'package:epeoplecare/module/task/model/task_status.dart';
import 'package:epeoplecare/module/task/model/task_priority.dart';
import 'package:epeoplecare/module/task/model/task_related.dart';
import 'package:epeoplecare/module/task/model/task_watcher.dart';
import 'package:epeoplecare/module/task/model/task_notes.dart';
import 'package:epeoplecare/module/task/model/task_activity.dart';
import 'package:epeoplecare/model/employee/employee.dart';

import 'package:epeoplecare/provider/enum_provider.dart';

class Task extends BaseModel {
  Project? project;
  String subject;
  String? description;
  String? dueDate;
  TaskStatus? status;
  Employee? assignee;
  TaskPriority? priority;
  double? progress;
  Task? parent;
  int? parentId;
  List<TaskRelated> relateds = [];
  List<TaskWatcher> watchers = [];
  List<TaskNotes> notes = [];
  List<TaskActivity> activities = [];

  Task(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.project,
    this.subject,
    this.description,
    this.dueDate,
    this.status,
    this.assignee,
    this.priority,
    this.progress,
    this.parent,
    this.parentId,
    this.relateds,
    this.watchers,
    this.notes,
    this.activities,
  ) : super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static Task? fromJson(dynamic json) {
    if (json == null) return null;

    List<TaskRelated>? relateds = [];
    if (json['relateds'] != null) {
      var objJson = json['relateds'] as List;
      relateds = objJson.map((item) => TaskRelated.fromJson(item)).cast<TaskRelated>().toList();
    }

    List<TaskWatcher> watchers = [];
    if (json['watchers'] != null) {
      for (var i = 0; i < json['watchers'].length; i++) {
        TaskWatcher? item = TaskWatcher.fromJson(json['watchers'][i]);
        if (item != null) {
          watchers.add(item);
        }
      }
    }

    List<TaskNotes> notes = [];
    if (json['notes'] != null) {
      for (var i = 0; i < json['notes'].length; i++) {
        TaskNotes? item = TaskNotes.fromJson(json['notes'][i]);
        if (item != null) {
          notes.add(item);
        }
      }
    }

    List<TaskActivity> activities = [];
    if (json['activities'] != null) {
      for (var i = 0; i < json['activities'].length; i++) {
        TaskActivity? item = TaskActivity.fromJson(json['activities'][i]);
        if (item != null) {
          activities.add(item);
        }
      }
    }

    return Task(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      Project.fromJson(json['project']),
      json['subject'],
      json['description'],
      json['due_date'],
      TaskStatus.fromJson(json['status']),
      Employee.fromJson(json['assignee']),
      EnumProvider.fromString(TaskPriority.values, json['priority']),
      json['progress'],
      Task.fromJson(json['parent']),
      json['parent_id'],
      relateds,
      watchers,
      notes,
      activities,
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
      "project": project,
      "subject": subject,
      "description": description,
      "due_date": dueDate,
      "status": status,
      "assignee": assignee,
      "priority": EnumProvider.convertToString(priority),
      "progress": progress,
      "parent": parent,
      "relateds": relateds,
      "watchers": watchers,
      "notes": notes,
      "activities": activities,
    };
  }
}
