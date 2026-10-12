import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/model/employee/employee_dependent.dart';
import 'package:epeoplecare/module/benefit/model/benefit_transaction_detail.dart';

import 'package:epeoplecare/module/workflow/model/app_workflow.dart';

import '../../../model/employee/employee.dart';
import '../../../provider/enum_provider.dart';
import '../../workflow/model/workflow.dart';
import '../../workflow/model/workflow_status.dart';

class BenefitTransaction extends AppWorkflow{
    bool personalRequest;
    String requestedDate;
    double requestedAmount;
    double? approvedAmount;
    EmployeeDependent? employeeDependent;
    List<BenefitTransactionDetail> benefitTransactionDetails = [];

    BenefitTransaction(
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
    this.personalRequest,
    this.requestedDate,
    this.requestedAmount,
    this.approvedAmount,
    this.employeeDependent,
    this.benefitTransactionDetails,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias, workflow, requestNo, workflowStatus, employee, attachment, description, assignee, assignment, parameters, workflowExecutors);

  static BenefitTransaction? fromJson(dynamic json) {
    if (json == null) return null;
    

    List<BenefitTransactionDetail> benefitTransactionDetails = [];
    if(json['benefit_transaction_details'] != null) {
      for (var i = 0; i < json['benefit_transaction_details'].length; i++) {
        BenefitTransactionDetail? item = BenefitTransactionDetail.fromJson(json['benefit_transaction_details'][i]);
        if(item != null) {
          benefitTransactionDetails.add(item);
        }
      }
    }

    return BenefitTransaction(
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
      json['personal_request'],
      json['requested_date'],
      json['requested_amount'],
      json['approved_amount'],
      EmployeeDependent.fromJson(json['employee_dependent']),
      benefitTransactionDetails,
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
      "personal_request": personalRequest,
      "requested_date": requestedDate,
      "requested_amount": requestedAmount,
      "approved_amount": approvedAmount,
      "employee_dependent" : employeeDependent,
      "benefit_transaction_details" : benefitTransactionDetails,
    };
  }
}