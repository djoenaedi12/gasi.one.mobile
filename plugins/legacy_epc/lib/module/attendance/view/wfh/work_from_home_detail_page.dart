import 'dart:collection';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/module/attendance/model/work_from_home.dart';
import 'package:epeoplecare/module/attendance/repository/work_from_home_repository.dart';
import 'package:epeoplecare/module/customfield/view/custom_value_page.dart';
import 'package:epeoplecare/module/workflow/model/node_type.dart';
import 'package:epeoplecare/module/workflow/model/workflow_detail.dart';
import 'package:epeoplecare/module/workflow/model/workflow_status.dart';
import 'package:epeoplecare/module/workflow/view/revoked_request_page.dart';
import 'package:epeoplecare/provider/date_provider.dart';
import 'package:epeoplecare/provider/enum_provider.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/module/workflow/view/approval_history_page.dart';
import 'package:epeoplecare/module/workflow/view/approval_process.dart';
import 'package:epeoplecare/view/shared/input_form.dart';
import 'package:epeoplecare/view/shared/message.dart';
import 'package:epeoplecare/view/shared/multiple_attachment_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class WorkFromHomeDetailPage extends StatefulWidget {
  final String title;
  final bool isApplication;
  final WorkFromHome? workFromHome;
  final int index;
  const WorkFromHomeDetailPage({Key? key, this.title="", this.isApplication = true, this.workFromHome, this.index=0}):super(key: key);

  @override
  State<StatefulWidget>  createState() => _WorkFromHomeDetailPageState();
}

class _WorkFromHomeDetailPageState extends State<WorkFromHomeDetailPage> {
  String _status = "";
  List<WorkflowDetail> approvalHistories = [];
  final WorkFromHomeRepository _workFromHomeRepository = Repository().getWorkFromHomeRepository();

  @override
  void initState() {
    super.initState();
    renderHistory(widget.workFromHome!.workflow!.workflowDetails);
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
      
      _status = widget.workFromHome!.workflowStatus.toString().tr();
    });
  }

  _approvalProcess(WorkflowStatus status, String remark, WorkflowDetail? workflowDetail) {
    EasyLoading.show(status: "Please Wait".tr());
    Map<String, dynamic> parameters = HashMap();
    parameters["workflow"] = widget.workFromHome!.workflow;
    parameters["workflow_status"] = EnumProvider.convertToString(status);
    parameters["remark"] = remark;
    parameters["workflow_detail"] = workflowDetail;
    _workFromHomeRepository.approvalProcess(parameters).then((value) {
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
    }).catchError((onError){
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
    parameters["workflow"] = widget.workFromHome!.workflow!.id;
    if(employee != null) {
      parameters["employee"] = employee.id;
    }
    parameters["remark"] = remark;

    _workFromHomeRepository.revokedRequest(parameters).then((value) {
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

  bool _canPullBack(bool isApplicant, WorkFromHome? transaction) {
    if(isApplicant == true) {
      if(transaction!.workflowStatus == WorkflowStatus.SUBMITTED || transaction.workflowStatus == WorkflowStatus.APPROVAL_PROCESS) {
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
                    content: widget.workFromHome!.requestNo,
                  ),
                  InputForm().renderDetailField(
                    title: "Status".tr(),
                    content: _status,
                  ),
                  InputForm().renderDetailField(
                    title: "Submitted By".tr(),
                    content: widget.workFromHome!.employee!.name,
                  ),
                  InputForm().renderDetailField(
                    title: "Assignment".tr(),
                    content: widget.workFromHome!.assignment == true ? "Yes".tr() : "No".tr(),
                  ),
                  InputForm().renderDetailField(
                    title: "Assignee".tr(),
                    content: widget.workFromHome!.assignee != null ? widget.workFromHome!.assignee!.name : "",
                  ),
                  InputForm().renderDetailField(
                    title: "Date From".tr(),
                    content: DateProvider.convertDateStrFormat(widget.workFromHome!.dateFrom, "yyyy-MM-dd", "EEEE, dd MMMM yyyy"),
                  ),
                  InputForm().renderDetailField(
                    title: "Date To".tr(),
                    content: DateProvider.convertDateStrFormat(widget.workFromHome!.dateTo, "yyyy-MM-dd", "EEEE, dd MMMM yyyy"),
                  ),
                  InputForm().renderDetailField(
                    title: "Duration".tr(),
                    content: "${widget.workFromHome!.duration} ${"Days".tr()}",
                  ),
                  InputForm().renderDetailField(
                    title: "Working Location".tr(),
                    content: widget.workFromHome!.workingLocation != null ? widget.workFromHome!.workingLocation!.name : "",
                  ),
                  InputForm().renderDetailField(
                    title: "Location".tr(),
                    content: widget.workFromHome!.locationStr,
                  ),
                  InputForm().renderDetailField(
                    title: "Description".tr(),
                    content: widget.workFromHome!.description,
                  ),
                  MultipleAttachmentPage(
                    medias: widget.workFromHome!.medias,
                    attachment: widget.workFromHome!.attachment,
                  ),
                  CustomValuesPage(
                    customValues: widget.workFromHome!.customValues,
                    viewMode: true,
                  ),
                  ApprovalHistoryPage(
                    approvalHistory: approvalHistories,
                    workflowExecutors: widget.workFromHome!.workflowExecutors,
                  ),
                ],
              ),
            ),
          ),
          Visibility(
            visible: _canPullBack(widget.isApplication, widget.workFromHome) || (!widget.isApplication && (((widget.workFromHome!.workflowStatus == WorkflowStatus.SUBMITTED || widget.workFromHome!.workflowStatus == WorkflowStatus.APPROVAL_PROCESS || widget.workFromHome!.workflowStatus == WorkflowStatus.SENDBACKED) && widget.index == 0) || widget.workFromHome!.workflowStatus == WorkflowStatus.APPROVED)),
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
                        workflowStatus: widget.workFromHome!.workflowStatus,
                        workflow: widget.workFromHome!.workflow,
                        isPullBack: _canPullBack(widget.isApplication, widget.workFromHome),
                      );
                    },
                  ).then((value) {
                    if(value == null) return;

                    _approvalProcess(value['workflowStatus'], value['remark'], value["workflowDetail"]);
                  });
                }
              ),
            ),
          ),
          Visibility(
            visible: widget.isApplication && widget.workFromHome!.workflowStatus == WorkflowStatus.APPROVED,
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
                        workflow: widget.workFromHome!.workflow,
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
