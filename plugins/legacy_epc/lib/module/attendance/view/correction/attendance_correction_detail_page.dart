import 'dart:collection';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/module/attendance/model/attendance_correction.dart';
import 'package:epeoplecare/module/attendance/repository/attendance_correction_repository.dart';
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

class AttendanceCorrectionDetailPage extends StatefulWidget {
  final String title;
  final bool isApplication;
  final AttendanceCorrection? attendanceCorrection;
  final int index;
  const AttendanceCorrectionDetailPage({Key? key, this.title="", this.isApplication = true, this.attendanceCorrection, this.index=0}) : super(key: key);

  @override
  State<StatefulWidget>  createState() => _AttendanceCorrectionDetailPageState();
}

class _AttendanceCorrectionDetailPageState extends State<AttendanceCorrectionDetailPage> {
  String _status = "";
  List<WorkflowDetail> approvalHistories = [];
  final AttendanceCorrectionRepository _attendanceCorrectionRepository = Repository().getAttendanceCorrectionRepository();

  @override
  void initState() {
    super.initState();
    renderHistory(widget.attendanceCorrection!.workflow!.workflowDetails);
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
      
      _status = widget.attendanceCorrection!.workflowStatus.toString().tr();
    });
  }

  _approvalProcess(WorkflowStatus status, String remark, WorkflowDetail? workflowDetail) {
    EasyLoading.show(status: "Please Wait".tr());
    Map<String, dynamic> parameters = HashMap();
    parameters["workflow"] = widget.attendanceCorrection!.workflow;
    parameters["workflow_status"] = EnumProvider.convertToString(status);
    parameters["remark"] = remark;
    parameters["workflow_detail"] = workflowDetail;
    _attendanceCorrectionRepository.approvalProcess(parameters).then((value) {
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
    parameters["workflow"] = widget.attendanceCorrection!.workflow!.id;
    if(employee != null) {
      parameters["employee"] = employee.id;
    }
    parameters["remark"] = remark;

    _attendanceCorrectionRepository.revokedRequest(parameters).then((value) {
      EasyLoading.dismiss();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MessagePage(
            icon: const Icon(Icons.check_circle, size: 100, color: Colors.green),
            title: "Success",
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

  int diffDays(String date) {
    DateTime attendanceDate = DateProvider.convertStr2Date(widget.attendanceCorrection!.attendanceDate, "yyyy-MM-dd")!;
    DateTime attendanceRecord = DateProvider.convertStr2Date(date, "yyyy-MM-dd HH:mm:ss")!;
    attendanceRecord = DateProvider.convertDateFormat(attendanceRecord, "yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd")!;

    return attendanceRecord.difference(attendanceDate).inDays;
  }

  bool _canPullBack(bool isApplicant, AttendanceCorrection transaction) {
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
                    content: widget.attendanceCorrection!.requestNo,
                  ),
                  InputForm().renderDetailField(
                    title: "Status".tr(),
                    content: _status,
                  ),
                  InputForm().renderDetailField(
                    title: "Submitted By".tr(),
                    content: widget.attendanceCorrection!.employee!.name,
                  ),
                  InputForm().renderDetailField(
                    title: "Assignment".tr(),
                    content: widget.attendanceCorrection!.assignment == true ? "Yes".tr() : "No".tr(),
                  ),
                  InputForm().renderDetailField(
                    title: "Assignee".tr(),
                    content: widget.attendanceCorrection!.assignee != null ? widget.attendanceCorrection!.assignee!.name : "",
                  ),
                  InputForm().renderDetailField(
                    title: "Date".tr(),
                    content: DateProvider.convertDateStrFormat(widget.attendanceCorrection!.attendanceDate, "yyyy-MM-dd", "EEEE, dd MMMM yyyy"),
                  ),
                  InputForm().renderDetailField(
                    title: "Check In".tr(),
                    content: "${DateProvider.convertDateStrFormat(widget.attendanceCorrection!.checkIn, "yyyy-MM-dd HH:mm:ss", "HH:mm:ss")} ${diffDays(widget.attendanceCorrection!.checkIn) < 0 ? "(${diffDays(widget.attendanceCorrection!.checkIn)} ${"Days".tr()})" : (diffDays(widget.attendanceCorrection!.checkIn) > 0) ? "(+${diffDays(widget.attendanceCorrection!.checkIn)} ${"Days".tr()})" : ""}",
                  ),
                  InputForm().renderDetailField(
                    title: "Check Out".tr(),
                    content: "${DateProvider.convertDateStrFormat(widget.attendanceCorrection!.checkOut, "yyyy-MM-dd HH:mm:ss", "HH:mm:ss")} ${diffDays(widget.attendanceCorrection!.checkOut) < 0 ? "(${diffDays(widget.attendanceCorrection!.checkOut)} ${"Days".tr()})" : (diffDays(widget.attendanceCorrection!.checkOut) > 0) ? "(+${diffDays(widget.attendanceCorrection!.checkOut)} ${"Days".tr()})" : ""}",
                  ),
                  InputForm().renderDetailField(
                    title: "Description".tr(),
                    content: widget.attendanceCorrection!.description,
                  ),
                  MultipleAttachmentPage(
                    medias: widget.attendanceCorrection!.medias,
                    attachment: widget.attendanceCorrection!.attachment,
                  ),
                  CustomValuesPage(
                    customValues: widget.attendanceCorrection!.customValues,
                    viewMode: true,
                  ),
                  ApprovalHistoryPage(
                    approvalHistory: approvalHistories,
                    workflowExecutors: widget.attendanceCorrection!.workflowExecutors,
                  ),
                ]
              ),
            ),
          ),
          Visibility(
            visible: _canPullBack(widget.isApplication, widget.attendanceCorrection!) || (!widget.isApplication && (((widget.attendanceCorrection!.workflowStatus == WorkflowStatus.SUBMITTED || widget.attendanceCorrection!.workflowStatus == WorkflowStatus.APPROVAL_PROCESS || widget.attendanceCorrection!.workflowStatus == WorkflowStatus.SENDBACKED) && widget.index == 0) || widget.attendanceCorrection!.workflowStatus == WorkflowStatus.APPROVED)),
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
                        workflowStatus: widget.attendanceCorrection!.workflowStatus,
                        workflow: widget.attendanceCorrection!.workflow,
                        isPullBack: _canPullBack(widget.isApplication, widget.attendanceCorrection!),
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
            visible: widget.isApplication && widget.attendanceCorrection!.workflowStatus == WorkflowStatus.APPROVED,
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
                        workflow: widget.attendanceCorrection!.workflow,
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
