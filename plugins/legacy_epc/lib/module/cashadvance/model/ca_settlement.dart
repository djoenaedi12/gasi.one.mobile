import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/module/cashadvance/model/ca_request.dart';
import 'package:epeoplecare/module/cashadvance/model/ca_settlement_detail.dart';
import 'package:epeoplecare/module/workflow/model/app_workflow.dart';
import 'package:epeoplecare/module/workflow/model/workflow.dart';
import 'package:epeoplecare/module/workflow/model/workflow_status.dart';
import 'package:epeoplecare/provider/enum_provider.dart';

class CASettlement extends AppWorkflow {
  
  CARequest? caRequest;
  double? totalAmount;
  List<CASettlementDetail> caSettlementDetails = [];

  CASettlement(
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
    this.caRequest,
    this.totalAmount,
    this.caSettlementDetails,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias, workflow, requestNo, workflowStatus, employee, attachment, description, assignee, assignment, parameters, workflowExecutors);

  static CASettlement? fromJson(dynamic json) {
    if (json == null) return null;

    List<CASettlementDetail> caSettlementDetails = [];
    if(json['ca_settlement_details'] != null) {
      for (var i = 0; i < json['ca_settlement_details'].length; i++) {
        CASettlementDetail? item = CASettlementDetail.fromJson(json['ca_settlement_details'][i]);
        if(item != null) {
          caSettlementDetails.add(item);
        }
      }
    }
    
    return CASettlement(
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
      CARequest.fromJson(json['ca_request']),
      json['total_amount'],
      caSettlementDetails,
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
      "ca_request": caRequest,
      "total_amount": totalAmount,
      "ca_settlement_details": caSettlementDetails,
    };
  }
}