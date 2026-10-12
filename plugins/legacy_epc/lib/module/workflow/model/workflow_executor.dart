import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/module/workflow/model/node.dart';
import 'package:epeoplecare/module/workflow/model/workflow.dart';

class WorkflowExecutor extends BaseModel {
  
  Workflow? workflow;
  Node? node;
  Employee? executor;

  WorkflowExecutor(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.workflow,
    this.node,
    this.executor,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static WorkflowExecutor? fromJson(dynamic json) {
    if (json == null) return null;

    return WorkflowExecutor(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      Workflow.fromJson(json['workflow']),
      Node.fromJson(json['node']),
      Employee.fromJson(json['executor']),
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
      "workflow": workflow,
      "node": node,
      "executor": executor,
    };
  }
}
