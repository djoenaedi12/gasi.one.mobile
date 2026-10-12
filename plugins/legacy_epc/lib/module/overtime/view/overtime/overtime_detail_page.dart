import 'dart:collection';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/module/customfield/view/custom_value_page.dart';
import 'package:epeoplecare/module/overtime/model/overtime_transaction.dart';
import 'package:epeoplecare/module/overtime/model/overtime_transaction_detail.dart';
import 'package:epeoplecare/module/overtime/view/overtime/overtime_detail_overtime_page.dart';
import 'package:epeoplecare/module/workflow/model/node_type.dart';
import 'package:epeoplecare/module/workflow/model/workflow_detail.dart';
import 'package:epeoplecare/module/workflow/model/workflow_status.dart';
import 'package:epeoplecare/module/workflow/view/revoked_request_page.dart';
import 'package:epeoplecare/provider/date_provider.dart';
import 'package:epeoplecare/provider/enum_provider.dart';
import 'package:epeoplecare/module/overtime/repository/overtime_transaction_repository.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/module/workflow/view/approval_history_page.dart';
import 'package:epeoplecare/module/workflow/view/approval_process.dart';
import 'package:epeoplecare/view/shared/detail_page.dart';
import 'package:epeoplecare/view/shared/input_form.dart';
import 'package:epeoplecare/view/shared/message.dart';
import 'package:epeoplecare/view/shared/multiple_attachment_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class OvertimeDetailPage extends StatefulWidget {
  final String title;
  final bool isApplication;
  final OvertimeTransaction? overtimeTransaction;
  final int index;
  const OvertimeDetailPage({Key? key, this.title="", this.isApplication = true, this.overtimeTransaction, this.index=0}):super(key: key);

  @override
  State<StatefulWidget> createState() => _OvertimeDetailPageState();
}

class _OvertimeDetailPageState extends State<OvertimeDetailPage> {
  String _status = "";
  List<WorkflowDetail> approvalHistories = [];
  final OvertimeTransactionRepository _overtimeTransactionRepository = Repository().getOvertimeTransactionRepository();

  @override
  void initState() {
    super.initState();
    renderHistory(widget.overtimeTransaction!.workflow!.workflowDetails);
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
      
      _status = widget.overtimeTransaction!.workflowStatus.toString().tr();
    });
  }

  _approvalProcess(WorkflowStatus status, String remark, WorkflowDetail? workflowDetail) {
    EasyLoading.show(status: "Please Wait".tr());
    Map<String, dynamic> parameters = HashMap();
    parameters["workflow"] = widget.overtimeTransaction!.workflow;
    parameters["workflow_status"] = EnumProvider.convertToString(status);
    parameters["remark"] = remark;
    parameters["workflow_detail"] = workflowDetail;
    _overtimeTransactionRepository.approvalProcess(parameters).then((value) {
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
    parameters["workflow"] = widget.overtimeTransaction!.workflow!.id;
    if(employee != null) {
      parameters["employee"] = employee.id;
    }
    parameters["remark"] = remark;

    _overtimeTransactionRepository.revokedRequest(parameters).then((value) {
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

  bool _canPullBack(bool isApplicant, OvertimeTransaction transaction) {
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
                    content: widget.overtimeTransaction!.requestNo,
                  ),
                  InputForm().renderDetailField(
                    title: "Status".tr(),
                    content: _status,
                  ),
                  InputForm().renderDetailField(
                    title: "Submitted By".tr(),
                    content: widget.overtimeTransaction!.employee!.name,
                  ),
                  InputForm().renderDetailField(
                    title: "Assignment".tr(),
                    content: (widget.overtimeTransaction!.assignment == true ? "Yes" : "No").tr(),
                  ),
                  InputForm().renderDetailField(
                    title: "Assignee".tr(),
                    content: widget.overtimeTransaction!.assignee != null ? widget.overtimeTransaction!.assignee!.name : "",
                  ),
                  DetailPage(
                    isEditable: false,
                    itemList: widget.overtimeTransaction!.overtimeTransactionDetails,
                    title: "Application Detail".tr(),
                    renderTitle: (val, index) {
                      OvertimeTransactionDetail detail = val;
                      return Text(
                        "${DateProvider.convertDateStrFormat(detail.startDate, "yyyy-MM-dd", "dd MMMM yyyy")} - ${DateProvider.convertDateStrFormat(detail.endDate, "yyyy-MM-dd", "dd MMMM yyyy")}"
                      );
                    },
                    renderBody: (data, index) {
                      OvertimeTransactionDetail detail = data;
                      return Container(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "${"Date From".tr()}: ",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(DateProvider.convertDateStrFormat(detail.startDate, "yyyy-MM-dd HH:mm:ss", "dd MMMM yyyy HH:mm")),
                              ],
                            ),
                            const SizedBox(height: 5.0),
                            Row(
                              children: [
                                Text(
                                  "${"Date To".tr()}: ",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(DateProvider.convertDateStrFormat(detail.endDate, "yyyy-MM-dd HH:mm:ss", "dd MMMM yyyy HH:mm")),
                              ],
                            ),
                            const SizedBox(height: 5.0),
                            Row(
                              children: [
                                Text(
                                  "${"Duration".tr()}: ",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text("${detail.duration} ${"Hours".tr()}"),
                              ],
                            ),
                            const SizedBox(height: 5.0),
                            Row(
                              children: [
                                Text(
                                  "${"Break Duration".tr()}: ",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text("${detail.breakDuration} ${"Hours".tr()}"),
                              ],
                            ),
                            const SizedBox(height: 5.0),
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OvertimeDetailOvertimePage(
                                      overtimeTransactionDetail: detail,
                                    ),
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  Text(
                                    "${"Total Duration".tr()}: ",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text("${detail.duration - detail.breakDuration!} ${"Hours".tr()}"),
                                  Text(
                                    " (${"View Detail".tr()})",
                                    style: TextStyle(
                                      color: Config.DEFAULT_COLOR,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  InputForm().renderDetailField(
                    title: "Description".tr(),
                    content: widget.overtimeTransaction!.description,
                  ),
                  MultipleAttachmentPage(
                    medias: widget.overtimeTransaction!.medias,
                    attachment: widget.overtimeTransaction!.attachment,
                  ),
                  CustomValuesPage(
                    customValues: widget.overtimeTransaction!.customValues,
                    viewMode: true,
                  ),
                  ApprovalHistoryPage(
                    approvalHistory: approvalHistories,
                    workflowExecutors: widget.overtimeTransaction!.workflowExecutors,
                  ),
                ],
              ),
            ),
          ),
          Visibility(
            visible: _canPullBack(widget.isApplication, widget.overtimeTransaction!) || (!widget.isApplication && (((widget.overtimeTransaction!.workflowStatus == WorkflowStatus.SUBMITTED || widget.overtimeTransaction!.workflowStatus == WorkflowStatus.APPROVAL_PROCESS || widget.overtimeTransaction!.workflowStatus == WorkflowStatus.SENDBACKED) && widget.index == 0) || widget.overtimeTransaction!.workflowStatus == WorkflowStatus.APPROVED)),
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
                        workflowStatus: widget.overtimeTransaction!.workflowStatus,
                        workflow: widget.overtimeTransaction!.workflow,
                        isPullBack: _canPullBack(widget.isApplication, widget.overtimeTransaction!),
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
            visible: widget.isApplication && widget.overtimeTransaction!.workflowStatus == WorkflowStatus.APPROVED,
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
                        workflow: widget.overtimeTransaction!.workflow,
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
