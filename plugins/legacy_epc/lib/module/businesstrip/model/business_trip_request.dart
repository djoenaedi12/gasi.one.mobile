import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/module/businesstrip/model/business_trip_request_detail.dart';
import 'package:epeoplecare/module/workflow/model/app_workflow.dart';
import 'package:epeoplecare/module/workflow/model/workflow.dart';
import 'package:epeoplecare/module/workflow/model/workflow_status.dart';
import 'package:epeoplecare/provider/enum_provider.dart';

class BusinessTripRequest extends AppWorkflow {
  
  String dateFrom;
  String dateTo;
  String? settlementDate;
  List<BusinessTripRequestDetail> businessTripRequestDetails = [];

  BusinessTripRequest(
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
    this.settlementDate,
    this.businessTripRequestDetails,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias, workflow, requestNo, workflowStatus, employee, attachment, description, assignee, assignment, parameters, workflowExecutors);

  static BusinessTripRequest? fromJson(dynamic json) {
    if (json == null) return null;

    List<BusinessTripRequestDetail> businessTripRequestDetails = [];
    if(json['business_trip_request_details'] != null) {
      for (var i = 0; i < json['business_trip_request_details'].length; i++) {
        BusinessTripRequestDetail? item = BusinessTripRequestDetail.fromJson(json['business_trip_request_details'][i]);
        if(item != null) {
          businessTripRequestDetails.add(item);
        }
      }
    }
    
    return BusinessTripRequest(
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
      json['settlement_date'],
      businessTripRequestDetails,
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
      "settlement_date": settlementDate,
      "business_trip_request_details": businessTripRequestDetails,
    };
  }
}