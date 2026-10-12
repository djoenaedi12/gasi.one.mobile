import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/module/workflow/model/route.dart';
import 'package:epeoplecare/module/workflow/model/route_type.dart';
import 'package:epeoplecare/module/workflow/model/workflow_detail.dart';
import 'package:epeoplecare/module/workflow/model/workflow_executor.dart';
import 'package:epeoplecare/module/workflow/model/workflow_parameter.dart';
import 'package:epeoplecare/module/workflow/model/workflow_status.dart';
import 'package:epeoplecare/provider/enum_provider.dart';

import '../../../model/employee/employee.dart';

class Workflow extends BaseModel {
  
  String code;
  String applyDate;
  Employee? applicant;
  WorkflowStatus? workflowStatus;
  Route? route;
  RouteType? routeType;
  Employee? assignee;
  bool assignment;
  List<WorkflowDetail> workflowDetails = [];
  List<WorkflowExecutor> workflowExecutors = [];
  List<WorkflowParameter> workflowParameters = [];

  Workflow(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.code,
    this.applyDate,
    this.applicant,
    this.workflowStatus,
    this.route,
    this.routeType,
    this.assignee,
    this.assignment,
    this.workflowDetails,
    this.workflowExecutors,
    this.workflowParameters,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static Workflow? fromJson(dynamic json) {
    if (json == null) return null;

    List<WorkflowDetail> workflowDetails = [];
    if(json['workflow_details'] != null) {
      for (var i = 0; i < json['workflow_details'].length; i++) {
        WorkflowDetail? workflowDetail = WorkflowDetail.fromJson(json['workflow_details'][i]);
        if(workflowDetail != null) {
          workflowDetails.add(workflowDetail);
        }
      }
    }

    List<WorkflowExecutor> workflowExecutors = [];
    if(json['workflow_executors'] != null) {
      for (var i = 0; i < json['workflow_executors'].length; i++) {
        WorkflowExecutor? workflowExecutor = WorkflowExecutor.fromJson(json['workflow_executors'][i]);
        if(workflowExecutor != null) {
          workflowExecutors.add(workflowExecutor);
        }
      }
    }

    List<WorkflowParameter> workflowParameters = [];
    if(json['workflow_parameters'] != null) {
      for (var i = 0; i < json['workflow_parameters'].length; i++) {
        WorkflowParameter? workflowParameter = WorkflowParameter.fromJson(json['workflow_parameters'][i]);
        if(workflowParameter != null) {
          workflowParameters.add(workflowParameter);
        }
      }
    }
    
    return Workflow(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      json['code'],
      json['apply_date'],
      Employee.fromJson(json['applicant']),
      EnumProvider.fromString(WorkflowStatus.values, json['workflow_status']),
      Route.fromJson(json['route']),
      EnumProvider.fromString(RouteType.values, json['route_type']),
      Employee.fromJson(json['assignee']),
      json['assignment'],
      workflowDetails,
      workflowExecutors,
      workflowParameters,
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
      "code": code,
      "apply_date": applyDate,
      "applicant": applicant,
      "workflow_status": EnumProvider.convertToString(workflowStatus),
      "route": route,
      "route_type": EnumProvider.convertToString(routeType),
      "assignee": assignee,
      "assignment": assignment,
      "workflow_details": workflowDetails,
      "workflow_executors": workflowExecutors,
      "workflow_parameters": workflowParameters
    };
  }
}
