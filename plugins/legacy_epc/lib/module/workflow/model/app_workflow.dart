import 'dart:collection';

import 'package:epeoplecare/module/workflow/model/workflow.dart';
import 'package:epeoplecare/module/workflow/model/workflow_executor.dart';
import 'package:epeoplecare/module/workflow/model/workflow_status.dart';

import '../../../model/base_model.dart';
import '../../../model/employee/employee.dart';

class AppWorkflow extends BaseModel
{
  Workflow? workflow;
  String? requestNo;
  WorkflowStatus? workflowStatus;
  Employee? employee;
  String? attachment;
  String? description;
  Employee? assignee;
  bool? assignment;
  Map<String, dynamic>? parameters = HashMap();
  List<WorkflowExecutor> workflowExecutors = [];

  AppWorkflow(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.workflow,
    this.requestNo,
    this.workflowStatus,
    this.employee,
    this.attachment,
    this.description,
    this.assignee,
    this.assignment,
    this.parameters,
    workflowExecutors,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias) {
    this.workflowExecutors = workflowExecutors ?? getWorkflowExecutor(null);
  }


  static List<WorkflowExecutor> getWorkflowExecutor(dynamic json) {
    List<WorkflowExecutor> workflowExecutors = [];
    if(json != null &&  json['workflow'] != null && json['workflow']['workflow_executors'] != null) {
      for (var i = 0; i < json['workflow']['workflow_executors'].length; i++) {
        WorkflowExecutor? workflowExecutor = WorkflowExecutor.fromJson(json['workflow']['workflow_executors'][i]);
        if(workflowExecutor != null) {
          workflowExecutors.add(workflowExecutor);
        }
      }
    }

    return workflowExecutors;
  }

}