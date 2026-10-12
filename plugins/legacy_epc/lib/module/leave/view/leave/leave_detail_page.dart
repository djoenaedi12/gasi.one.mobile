import 'dart:collection';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/module/customfield/view/custom_value_page.dart';
import 'package:epeoplecare/module/leave/model/leave_transaction.dart';
import 'package:epeoplecare/module/leave/model/leave_value_type.dart';
import 'package:epeoplecare/module/leave/view/leave/leave_scoupe_page.dart';
import 'package:epeoplecare/module/workflow/model/node_type.dart';
import 'package:epeoplecare/module/workflow/model/workflow_detail.dart';
import 'package:epeoplecare/module/workflow/model/workflow_status.dart';
import 'package:epeoplecare/module/workflow/view/revoked_request_page.dart';
import 'package:epeoplecare/provider/date_provider.dart';
import 'package:epeoplecare/provider/enum_provider.dart';
import 'package:epeoplecare/module/leave/repository/leave_transaction_repository.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/module/workflow/view/approval_history_page.dart';
import 'package:epeoplecare/module/workflow/view/approval_process.dart';
import 'package:epeoplecare/view/shared/input_form.dart';
import 'package:epeoplecare/view/shared/message.dart';
import 'package:epeoplecare/view/shared/multiple_attachment_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class LeaveDetailPage extends StatefulWidget {
  final String title;
  final bool isApplication;
  final LeaveTransaction? leaveTransaction;
  final int index;
  const LeaveDetailPage({Key? key, this.title="", this.isApplication = true, this.leaveTransaction, this.index=0}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _LeaveDetailPageState();
}

class _LeaveDetailPageState extends State<LeaveDetailPage> {

  String _status = "";
  List<WorkflowDetail> approvalHistories = [];
  final LeaveTransactionRepository _leaveTransactionRepository = Repository().getLeaveTransactionRepository();

  @override
  void initState() {
    super.initState();
    renderHistory(widget.leaveTransaction!.workflow!.workflowDetails);
  }

  renderHistory(List<WorkflowDetail> histories) {
    setState(() {
      Duration duration = DateProvider.convertDuration(durationStr: Config.serverTimezone, inverse: true);
      for (WorkflowDetail history in histories) {
        DateTime? executedDate = DateProvider.convertStr2Date(history.executedDate, "yyyy-MM-dd HH:mm:ss");
        history.executedDate = DateProvider.convertDate2Str(DateProvider.convertToLocal(executedDate, duration), "yyyy-MM-dd HH:mm:ss");
      }
      
      histories.sort((a,b) {
        if(a.executedDate == null || b.executedDate == null) return 1;
        return b.executedDate!.compareTo(a.executedDate!);
      });
      approvalHistories.clear();
      for (var item in histories) {
        if(item.executedDate != null && item.workflowStatus != null && item.executor != null) {
          approvalHistories.add(item);
        }
      }
      _status = widget.leaveTransaction!.workflowStatus.toString().tr();
    });
  }

  _approvalProcess(WorkflowStatus status, String remark, WorkflowDetail? workflowDetail) {
    EasyLoading.show(status: "Please Wait".tr());
    Map<String, dynamic> parameters = HashMap();
    parameters["workflow"] = widget.leaveTransaction!.workflow;
    parameters["workflow_status"] = EnumProvider.convertToString(status);
    parameters["remark"] = remark;
    parameters["workflow_detail"] = workflowDetail;
    _leaveTransactionRepository.approvalProcess(parameters).then((value) {
      EasyLoading.dismiss();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MessagePage(
            icon: const Icon(Icons.check_circle, size: 100, color: Colors.green),
            title: "Success".tr(),
            subTitle: "Data has been".tr(namedArgs: {"status": status.toString().tr()}),
          ),
        ),
      ).then((value) {
        Navigator.pop(context, true);
      });
    }).catchError((onError) {
      EasyLoading.dismiss();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MessagePage(
            icon: const Icon(Icons.error, size: 100, color: Colors.red),
            title: "Error".tr(),
            subTitle: onError.toString(),
          ),
        ),
      );
    });
  }

  _revokedRequest(Employee? employee, String remark) {
    EasyLoading.show(status: "Please Wait".tr());
    Map<String, dynamic> parameters = HashMap();
    parameters["workflow"] = widget.leaveTransaction!.workflow!.id;
    if(employee != null) {
      parameters["employee"] = employee.id;
    }
    parameters["remark"] = remark;

    _leaveTransactionRepository.revokedRequest(parameters).then((value) {
      EasyLoading.dismiss();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MessagePage(
            icon: const Icon(Icons.check_circle, size: 100, color: Colors.green),
            title: "Success".tr(),
            subTitle: "Request has been sent".tr(),
          ),
        ),
      ).then((value) {
        Navigator.pop(context, true);
      });
    }).catchError((onError) {
      EasyLoading.dismiss();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MessagePage(
            icon: const Icon(Icons.error, size: 100, color: Colors.red),
            title: "Error".tr(),
            subTitle: onError.toString(),
          ),
        ),
      );
    });
  }

  bool _canPullBack(bool isApplicant, LeaveTransaction transaction) {
    if(isApplicant == true) {
      if(transaction.workflowStatus == WorkflowStatus.SUBMITTED || transaction.workflowStatus == WorkflowStatus.APPROVAL_PROCESS) {
        return true;
      }

      if(transaction.workflowStatus == WorkflowStatus.SENDBACKED && transaction.workflow != null && transaction.workflow!.workflowDetails.isNotEmpty) {
        WorkflowDetail workflowDetail = transaction.workflow!.workflowDetails[transaction.workflow!.workflowDetails.length - 1];
        if(workflowDetail.node != null && workflowDetail.node!.nodeType != NodeType.APPLICANT) {
          return true;
        }
      }
    }
     
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Config.DEFAULT_COLOR,
        iconTheme: IconThemeData(
          color: Config.DEFAULT_ACCENT_COLOR,
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            color: Config.DEFAULT_ACCENT_COLOR,
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  InputForm().renderDetailField(
                    title: "Request No".tr(),
                    content: widget.leaveTransaction!.requestNo,
                  ),
                  InputForm().renderDetailField(
                    title: "Status".tr(),
                    content: _status,
                  ),
                  InputForm().renderDetailField(
                    title: "Submitted By".tr(),
                    content: widget.leaveTransaction!.employee!.name,
                  ),
                  InputForm().renderDetailField(
                    title: "Assignment".tr(),
                    content: (widget.leaveTransaction!.assignment == true ? "Yes" : "No").tr(),
                  ),
                  InputForm().renderDetailField(
                    title: "Assignee".tr(),
                    content: widget.leaveTransaction!.assignee != null ? widget.leaveTransaction!.assignee!.name : "",
                  ),
                  InputForm().renderDetailField(
                    title: "Leave Group".tr(),
                    content: widget.leaveTransaction!.leaveCategory!.leaveGroup!.name,
                  ),
                  InputForm().renderDetailField(
                    title: "Leave Category".tr(),
                    content: widget.leaveTransaction!.leaveCategory!.name,
                  ),
                  InputForm().renderDetailField(
                    title: "Date From".tr(),
                    content: DateProvider.convertDateStrFormat(widget.leaveTransaction!.startDate, "yyyy-MM-dd HH:mm:ss", "EEEE, dd MMMM yyyy"),
                  ),
                  InputForm().renderDetailField(
                    title: "Date To".tr(),
                    content: DateProvider.convertDateStrFormat(widget.leaveTransaction!.endDate, "yyyy-MM-dd HH:mm:ss", "EEEE, dd MMMM yyyy"),
                  ),
                  InputForm().renderDetailField(
                    title: "Duration".tr(),
                    content: "${widget.leaveTransaction!.duration} ${widget.leaveTransaction!.leaveCategory!.leaveValueType == LeaveValueType.MONTH ? "Months".tr() : "Days".tr()}",
                  ),
                  Visibility(
                    visible: (widget.leaveTransaction!.scoupeDuration != null && widget.leaveTransaction!.scoupeDuration! > 0) || (widget.leaveTransaction!.leaveTransactionScoupes.isNotEmpty) || (widget.leaveTransaction!.leaveTransactionScoupePublicHolidays.isNotEmpty),
                    child: Column(
                      children: [
                        InputForm().renderDetailField(
                          title: "Scoupe Duration".tr(),
                          content: "${widget.leaveTransaction!.scoupeDuration} ${"Days".tr()}",
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LeaveScoupePage(
                                  leaveTransactionScoupes: widget.leaveTransaction!.leaveTransactionScoupes,
                                  leaveTransactionScoupePublicHolidays: widget.leaveTransaction!.leaveTransactionScoupePublicHolidays,
                                  editable: false,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(
                              right: 10.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                const Icon(
                                  Icons.help,
                                  color: Colors.grey,
                                  size: 15.0,
                                ),
                                const SizedBox(width: 5.0),
                                Text(
                                  "View Detail".tr(),
                                  style: const TextStyle(
                                    color: Colors.blue
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Visibility(
                    visible: widget.leaveTransaction!.leaveCategory!.leaveGroup!.nonBalance == false,
                    child: InputForm().renderDetailField(
                      title: "Balance".tr(),
                      content: widget.leaveTransaction!.balance != null ? "${widget.leaveTransaction!.balance} ${"Days".tr()}" : "",
                    ),
                  ),
                  InputForm().renderDetailField(
                    title: "Description",
                    content: widget.leaveTransaction!.description,
                  ),
                  MultipleAttachmentPage(
                    medias: widget.leaveTransaction!.medias,
                    attachment: widget.leaveTransaction!.attachment,
                  ),
                  CustomValuesPage(
                    customValues: widget.leaveTransaction!.customValues,
                    viewMode: true,
                  ),
                  ApprovalHistoryPage(
                    approvalHistory: approvalHistories,
                    workflowExecutors: widget.leaveTransaction!.workflowExecutors,
                  ),
                ],
              ),
            ),
          ),
          Visibility(
            visible: _canPullBack(widget.isApplication, widget.leaveTransaction!) || (!widget.isApplication && (((widget.leaveTransaction!.workflowStatus == WorkflowStatus.SUBMITTED || widget.leaveTransaction!.workflowStatus == WorkflowStatus.APPROVAL_PROCESS || widget.leaveTransaction!.workflowStatus == WorkflowStatus.SENDBACKED) && widget.index == 0) || widget.leaveTransaction!.workflowStatus == WorkflowStatus.APPROVED)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: InputForm().renderButton(
                text: "Process".tr(),
                onPressed: () {
                  showModalBottomSheet(
                    isScrollControlled: true,
                    context: context,
                    builder: (BuildContext bc){
                      return ApprovalProcess(
                        isApplicant: false,
                        workflowStatus: widget.leaveTransaction!.workflowStatus,
                        workflow: widget.leaveTransaction!.workflow,
                        isPullBack: _canPullBack(widget.isApplication, widget.leaveTransaction!),
                      );
                    },
                  ).then((value) {
                    if(value == null) return;

                    _approvalProcess(value['workflowStatus'], value['remark'], value['workflowDetail']);
                  });
                }
              ),
            ),
          ),
          Visibility(
            visible: widget.isApplication && widget.leaveTransaction!.workflowStatus == WorkflowStatus.APPROVED,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: InputForm().renderButton(
                text: "Revoked Request".tr(),
                onPressed: () {
                  showModalBottomSheet(
                    isScrollControlled: true,
                    context: context,
                    builder: (BuildContext bc){
                      return RevokedRequestPage(
                        workflow: widget.leaveTransaction!.workflow,
                      );
                    },
                  ).then((value) {
                    if(value == null) return;

                    _revokedRequest(value['employee'], value['remark']);
                  });
                }
              ),
            ),
          ),
          const SizedBox(height: 10.0),
        ],
      ),
    );
  }
}
