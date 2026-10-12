import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/module/workflow/model/node.dart';
import 'package:epeoplecare/module/workflow/model/workflow.dart';
import 'package:epeoplecare/module/workflow/model/workflow_status.dart';
import 'package:epeoplecare/provider/enum_provider.dart';

import '../../../model/employee/employee.dart';

class WorkflowDetail extends BaseModel {
  
  Workflow? workflow;
  Node? node;
  String? executedDate;
  Employee? executor;
  WorkflowStatus? workflowStatus;
  String? remark;
  int seqNumber;

  WorkflowDetail(
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
    this.executedDate,
    this.executor,
    this.workflowStatus,
    this.remark,
    this.seqNumber
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static WorkflowDetail? fromJson(dynamic json) {
    if (json == null) return null;
    
    return WorkflowDetail(
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
      json['executed_date'],
      Employee.fromJson(json['executor']),
      EnumProvider.fromString(WorkflowStatus.values, json['workflow_status']),
      json['remark'],
      json['seq_number'],
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
      "executed_date": executedDate,
      "executor": executor,
      "workflow_status": EnumProvider.convertToString(workflowStatus),
      "remark": remark,
      "seq_number": seqNumber,
    };
  }
}
