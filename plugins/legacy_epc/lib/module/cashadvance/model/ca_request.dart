import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/model/company/payment_method.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/module/cashadvance/model/ca_policy.dart';
import 'package:epeoplecare/module/cashadvance/model/ca_request_detail.dart';
import 'package:epeoplecare/module/workflow/model/app_workflow.dart';
import 'package:epeoplecare/module/workflow/model/workflow.dart';
import 'package:epeoplecare/module/workflow/model/workflow_status.dart';
import 'package:epeoplecare/provider/enum_provider.dart';

class CARequest extends AppWorkflow {
  
  CAPolicy? caPolicy;
  String? purpose;
  String dateOfUse;
  double? totalAmount;
  PaymentMethod? paymentMethod;
  String? bankName;
  String? bankAccountNo;
  String? bankAccountName;
  List<CARequestDetail> caRequestDetails = [];
  bool settled;

  CARequest(
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
    this.caPolicy,
    this.purpose,
    this.dateOfUse,
    this.totalAmount,
    this.paymentMethod,
    this.bankName,
    this.bankAccountNo,
    this.bankAccountName,
    this.settled,
    this.caRequestDetails,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias, workflow, requestNo, workflowStatus, employee, attachment, description, assignee, assignment, parameters, workflowExecutors);

  static CARequest? fromJson(dynamic json) {
    if (json == null) return null;

    List<CARequestDetail> caRequestDetails = [];
    if(json['ca_request_details'] != null) {
      for (var i = 0; i < json['ca_request_details'].length; i++) {
        CARequestDetail? item = CARequestDetail.fromJson(json['ca_request_details'][i]);
        if(item != null) {
          caRequestDetails.add(item);
        }
      }
    }
    
    return CARequest(
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
      CAPolicy.fromJson(json['ca_policy']),
      json['purpose'],
      json['date_of_use'],
      json['total_amount'],
      PaymentMethod.fromJson(json['payment_method']),
      json['bank_name'],
      json['bank_account_no'],
      json['bank_account_name'],
      json['settled'],
      caRequestDetails,
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
      "ca_policy": caPolicy,
      "purpose": purpose,
      "date_of_use": dateOfUse,
      "total_amount": totalAmount,
      "payment_method": paymentMethod,
      "bank_name": bankName,
      "bank_account_no": bankAccountNo,
      "bank_account_name": bankAccountName,
      "settled": settled,
      "ca_request_details": caRequestDetails,
    };
  }
}