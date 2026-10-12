import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/module/loan/model/loan_request_installment.dart';
import 'package:epeoplecare/module/loan/model/loan_type.dart';
import 'package:epeoplecare/module/workflow/model/app_workflow.dart';
import 'package:epeoplecare/module/workflow/model/workflow.dart';
import 'package:epeoplecare/module/workflow/model/workflow_status.dart';
import 'package:epeoplecare/provider/enum_provider.dart';

class LoanRequest extends AppWorkflow {
  
  LoanType? loanType;
  String? firstInstallmentDate;
  int requestedPeriod;
  double requestedAmount;
  int? approvedPeriod;
  double? approvedAmount;
  double? interest;
  List<LoanRequestInstallment> loanRequestInstallments = [];

  LoanRequest(
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
    this.loanType,
    this.firstInstallmentDate,
    this.requestedPeriod,
    this.requestedAmount,
    this.approvedPeriod,
    this.approvedAmount,
    this.interest,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias, workflow, requestNo, workflowStatus, employee, attachment, description, assignee, assignment, parameters, workflowExecutors);

  static LoanRequest? fromJson(dynamic json) {
    if (json == null) return null;
    
    return LoanRequest(
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
      LoanType.fromJson(json['loan_type']),
      json['first_installment_date'],
      json['requested_period'],
      json['requested_amount'],
      json['approved_period'],
      json['approved_amount'],
      json['interest'],
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
      "loan_type": loanType,
      "first_installment_date": firstInstallmentDate,
      "requested_period": requestedPeriod,
      "requested_amount": requestedAmount,
      "approved_period": approvedPeriod,
      "approved_amount": approvedAmount,
      "interest": interest,
    };
  }
}