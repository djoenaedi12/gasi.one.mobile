import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/module/workflow/model/workflow.dart';

class WorkflowParameter extends BaseModel {
  
  Workflow? workflow;
  String name;
  String? value;

  WorkflowParameter(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.workflow,
    this.name,
    this.value,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static WorkflowParameter? fromJson(dynamic json) {
    if (json == null) return null;
    
    return WorkflowParameter(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      Workflow.fromJson(json['workflow']),
      json['name'],
      json['value'],
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
      "name": name,
      "value": value,
    };
  }
}
