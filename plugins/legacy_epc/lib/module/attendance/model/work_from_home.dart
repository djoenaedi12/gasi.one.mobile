import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/model/company/working_location.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/module/workflow/model/app_workflow.dart';
import 'package:epeoplecare/module/workflow/model/workflow.dart';
import 'package:epeoplecare/module/workflow/model/workflow_status.dart';
import 'package:epeoplecare/provider/enum_provider.dart';

class WorkFromHome extends AppWorkflow {
  
  String dateFrom;
  String dateTo;
  String? location;
  String? locationStr;
  double? duration;
  WorkingLocation? workingLocation;

  WorkFromHome(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    workflow,
    requestNo,
    workflowStatus,
    employee,
    attachment,
    description,
    assignee,
    assignment,
    parameters,
    workflowExecutors,
    this.dateFrom,
    this.dateTo,
    this.location,
    this.locationStr,
    this.duration,
    this.workingLocation,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias, workflow, requestNo, workflowStatus, employee, attachment, description, assignee, assignment, parameters, workflowExecutors);

  static WorkFromHome? fromJson(dynamic json) {
    if (json == null) return null;
    
    return WorkFromHome(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      Workflow.fromJson(json['workflow']),
      json['request_no'],
      EnumProvider.fromString(WorkflowStatus.values, json['workflow_status']),
      Employee.fromJson(json['employee']),
      json['attachment'],
      json['description'],
      Employee.fromJson(json['assignee']),
      json['assignment'],
      json['parameters'],
      AppWorkflow.getWorkflowExecutor(json),
      json['date_from'],
      json['date_to'],
      json['location'],
      json['location_str'],
      json['duration'],
      WorkingLocation.fromJson(json["working_location"]),
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
      "request_no": requestNo,
      "workflow_status": EnumProvider.convertToString(workflowStatus),
      "employee": employee,
      "attachment": attachment,
      "description": description,
      "assignee": assignee,
      "assignment": assignment,
      "parameters": parameters,
      "workflow_executors": workflowExecutors,
      "date_from": dateFrom,
      "date_to": dateTo,
      "location": location,
      "location_str": locationStr,
      "duration": duration,
      "working_location": workingLocation,
    };
  }
}