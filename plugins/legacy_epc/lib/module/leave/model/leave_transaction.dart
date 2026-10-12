import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/module/leave/model/leave_category.dart';
import 'package:epeoplecare/module/leave/model/leave_transaction_scoupe.dart';
import 'package:epeoplecare/module/leave/model/leave_transaction_scoupe_public_holiday.dart';
import 'package:epeoplecare/module/workflow/model/app_workflow.dart';
import 'package:epeoplecare/module/workflow/model/workflow.dart';
import 'package:epeoplecare/module/workflow/model/workflow_status.dart';
import 'package:epeoplecare/provider/enum_provider.dart';

class LeaveTransaction extends AppWorkflow {
  
  String startDate;
  String endDate;
  double? duration;
  LeaveCategory? leaveCategory;
  double? scoupeDuration;
  List<LeaveTransactionScoupe> leaveTransactionScoupes = [];
  List<LeaveTransactionScoupePublicHoliday> leaveTransactionScoupePublicHolidays = [];
  double? balance;

  LeaveTransaction(
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
    this.leaveCategory,
    this.scoupeDuration,
    this.leaveTransactionScoupes,
    this.leaveTransactionScoupePublicHolidays,
    this.balance,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias, workflow, requestNo, workflowStatus, employee, attachment, description, assignee, assignment, parameters, workflowExecutors);

  static LeaveTransaction? fromJson(dynamic json) {
    if (json == null) return null;

    List<LeaveTransactionScoupe> leaveTransactionScoupes = [];
    if(json['leave_transaction_scoupes'] != null) {
      for (var i = 0; i < json['leave_transaction_scoupes'].length; i++) {
        LeaveTransactionScoupe? item = LeaveTransactionScoupe.fromJson(json['leave_transaction_scoupes'][i]);
        if(item != null) {
          leaveTransactionScoupes.add(item);
        }
      }
    }

    List<LeaveTransactionScoupePublicHoliday> leaveTransactionScoupePublicHolidays = [];
    if(json['leave_transaction_scoupe_public_holidays'] != null) {
      for (var i = 0; i < json['leave_transaction_scoupe_public_holidays'].length; i++) {
        LeaveTransactionScoupePublicHoliday? item = LeaveTransactionScoupePublicHoliday.fromJson(json['leave_transaction_scoupe_public_holidays'][i]);
        if(item != null) {
          leaveTransactionScoupePublicHolidays.add(item);
        }
      }
    }
    
    return LeaveTransaction(
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
      LeaveCategory.fromJson(json['leave_category']),
      json['scoupe_duration'],
      leaveTransactionScoupes,
      leaveTransactionScoupePublicHolidays,
      json['balance'],
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
      "leave_category": leaveCategory,
      "scoupe_duration": scoupeDuration,
      "leave_transaction_scoupes": leaveTransactionScoupes,
      "leave_transaction_scoupe_public_holidays": leaveTransactionScoupePublicHolidays,
      "balance": balance
    };
  }
}