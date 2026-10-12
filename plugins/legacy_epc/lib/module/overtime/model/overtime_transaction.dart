import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/module/overtime/model/overtime_transaction_detail.dart';
import 'package:epeoplecare/module/workflow/model/app_workflow.dart';
import 'package:epeoplecare/module/workflow/model/workflow.dart';
import 'package:epeoplecare/module/workflow/model/workflow_status.dart';
import 'package:epeoplecare/provider/enum_provider.dart';

class OvertimeTransaction extends AppWorkflow {
  
  String startDate;
  String endDate;
  double duration;
  List<OvertimeTransactionDetail> overtimeTransactionDetails = [];

  OvertimeTransaction(
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
    this.startDate,
    this.endDate,
    this.duration,
    this.overtimeTransactionDetails,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias, workflow, requestNo, workflowStatus, employee, attachment, description, assignee, assignment, parameters, workflowExecutors);

  static OvertimeTransaction? fromJson(dynamic json) {
    if (json == null) return null;

    List<OvertimeTransactionDetail> overtimeTransactionDetails = [];
    if(json['overtime_transaction_details'] != null) {
      for (var i = 0; i < json['overtime_transaction_details'].length; i++) {
        OvertimeTransactionDetail? item = OvertimeTransactionDetail.fromJson(json['overtime_transaction_details'][i]);
        if(item != null) {
          overtimeTransactionDetails.add(item);
        }
      }
    }
    
    return OvertimeTransaction(
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
      json['start_date'],
      json['end_date'],
      json['duration'],
      overtimeTransactionDetails,
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
      "start_date": startDate,
      "end_date": endDate,
      "duration": duration,
      "overtime_transaction_details": overtimeTransactionDetails,
    };
  }
}