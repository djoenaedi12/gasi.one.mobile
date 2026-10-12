import 'dart:collection';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/module/cashadvance/model/ca_request.dart';
import 'package:epeoplecare/module/cashadvance/model/ca_request_detail.dart';
import 'package:epeoplecare/module/cashadvance/repository/ca_request_repository.dart';
import 'package:epeoplecare/module/cashadvance/view/settlement/ca_settlement_application_page.dart';
import 'package:epeoplecare/module/customfield/view/custom_value_page.dart';
import 'package:epeoplecare/module/workflow/model/node_type.dart';
import 'package:epeoplecare/module/workflow/model/workflow_detail.dart';
import 'package:epeoplecare/module/workflow/model/workflow_status.dart';
import 'package:epeoplecare/module/workflow/view/revoked_request_page.dart';
import 'package:epeoplecare/provider/date_provider.dart';
import 'package:epeoplecare/provider/enum_provider.dart';
import 'package:epeoplecare/provider/number_provider.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/module/workflow/view/approval_history_page.dart';
import 'package:epeoplecare/module/workflow/view/approval_process.dart';
import 'package:epeoplecare/view/shared/detail_page.dart';
import 'package:epeoplecare/view/shared/input_form.dart';
import 'package:epeoplecare/view/shared/message.dart';
import 'package:epeoplecare/view/shared/multiple_attachment_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class CADetailPage extends StatefulWidget {
  final String title;
  final bool isApplication;
  final CARequest? caRequest;
  final int index;
  const CADetailPage({Key? key, this.title = "", this.isApplication = true, this.caRequest, this.index = 0}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _CADetailPageState();
}

class _CADetailPageState extends State<CADetailPage> {
  String _status = "";
  List<WorkflowDetail> approvalHistories = [];
  final CARequestRepository _caRequestRepository = Repository().getCARequestRepository();
  bool deductionVisibility = false;

  @override
  void initState() {
    super.initState();
    renderHistory(widget.caRequest!.workflow!.workflowDetails);
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
      
      _status = widget.caRequest!.workflowStatus.toString().tr();
    });
  }

  _approvalProcess(WorkflowStatus status, String remark, WorkflowDetail? workflowDetail) {
    EasyLoading.show(status: "Please Wait".tr());
    Map<String, dynamic> parameters = HashMap();
    parameters["workflow"] = widget.caRequest!.workflow;
    parameters["workflow_status"] = EnumProvider.convertToString(status);
    parameters["remark"] = remark;
    parameters["workflow_detail"] = workflowDetail;
    _caRequestRepository.approvalProcess(parameters).then((value) {
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
    parameters["workflow"] = widget.caRequest!.workflow!.id;
    if(employee != null) {
      parameters["employee"] = employee.id;
    }
    parameters["remark"] = remark;

    _caRequestRepository.revokedRequest(parameters).then((value) {
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

  bool _canPullBack(bool isApplicant, CARequest transaction) {
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
                    content: widget.caRequest!.requestNo,
                  ),
                  InputForm().renderDetailField(
                    title: "Status".tr(),
                    content: _status,
                  ),
                  InputForm().renderDetailField(
                    title: "Submitted By".tr(),
                    content: widget.caRequest!.employee!.name,
                  ),
                  InputForm().renderDetailField(
                    title: "Assignment".tr(),
                    content: widget.caRequest!.assignment == true ? "Yes".tr() : "No".tr(),
                  ),
                  InputForm().renderDetailField(
                    title: "Assignee".tr(),
                    content: widget.caRequest!.assignee != null ? widget.caRequest!.assignee!.name : "",
                  ),
                  InputForm().renderDetailField(
                    title: "Policy".tr(),
                    content: widget.caRequest!.caPolicy!.name,
                  ),
                  InputForm().renderDetailField(
                    title: "Purpose".tr(),
                    content: widget.caRequest!.purpose,
                  ),
                  InputForm().renderDetailField(
                    title: "Date Of Use".tr(),
                    content: DateProvider.convertDateStrFormat(widget.caRequest!.dateOfUse, "yyyy-MM-dd", "dd MMMM yyyy"),
                  ),
                  InputForm().renderDetailField(
                    title: "Payment Method".tr(),
                    content: widget.caRequest!.paymentMethod!.name,
                  ),
                  InputForm().renderDetailField(
                    title: "Bank Name".tr(),
                    content: widget.caRequest!.bankName,
                  ),
                  InputForm().renderDetailField(
                    title: "Bank Account No".tr(),
                    content: widget.caRequest!.bankAccountNo,
                  ),
                  InputForm().renderDetailField(
                    title: "Bank Account Name".tr(),
                    content: widget.caRequest!.bankAccountName,
                  ),
                  DetailPage(
                    isEditable: false,
                    itemList: widget.caRequest!.caRequestDetails,
                    title: "Detail".tr(),
                    renderTitle: (val, index) {
                      CARequestDetail detail = val;
                      return Text(
                        "${detail.name} (${detail.caCategory!.name}) - ${NumberProvider.decimalFormatDouble(detail.amount)}"
                      );
                    },
                    renderBody: (data, index) {
                      CARequestDetail detail = data;
                      return Container(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "${"Name".tr()}: ",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(detail.name),
                              ],
                            ),
                            const SizedBox(height: 5.0),
                            Row(
                              children: [
                                Text(
                                  "${"Description".tr()}: ",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(detail.description ?? ""),
                              ],
                            ),
                            const SizedBox(height: 5.0),
                            Row(
                              children: [
                                Text(
                                  "${"Category".tr()}: ",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(detail.caCategory!.name),
                              ],
                            ),
                            const SizedBox(height: 5.0),
                            Row(
                              children: [
                                Text(
                                  "${"Amount".tr()}: ",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(NumberProvider.decimalFormatDouble(detail.amount)),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Total Amount".tr(),
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                        Text(NumberProvider.decimalFormatDouble(widget.caRequest!.totalAmount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  ),
                  InputForm().renderDetailField(
                    title: "Description".tr(),
                    content: widget.caRequest!.description,
                  ),
                  MultipleAttachmentPage(
                    medias: widget.caRequest!.medias,
                    attachment: widget.caRequest!.attachment,
                  ),
                  CustomValuesPage(
                    customValues: widget.caRequest!.customValues,
                    viewMode: true,
                  ),
                  ApprovalHistoryPage(
                    approvalHistory: approvalHistories,
                    workflowExecutors: widget.caRequest!.workflowExecutors,
                  ),
                  
                ],
              ),
            ),
          ),
          Visibility(
            visible: widget.isApplication && widget.caRequest!.workflowStatus == WorkflowStatus.APPROVED && widget.caRequest!.settled == false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: InputForm().renderButton(
                text: "Settlement".tr(),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CASettlementApplicationPage(
                        caRequest: widget.caRequest!,
                      ),
                    ),
                  );
                }
              ),
            ),
          ),
          Visibility(
            visible: _canPullBack(widget.isApplication, widget.caRequest!) || (!widget.isApplication && (((widget.caRequest!.workflowStatus == WorkflowStatus.SUBMITTED || widget.caRequest!.workflowStatus == WorkflowStatus.APPROVAL_PROCESS || widget.caRequest!.workflowStatus == WorkflowStatus.SENDBACKED) && widget.index == 0) || widget.caRequest!.workflowStatus == WorkflowStatus.APPROVED)),
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
                        workflowStatus: widget.caRequest!.workflowStatus,
                        workflow: widget.caRequest!.workflow,
                        isPullBack: _canPullBack(widget.isApplication, widget.caRequest!),
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
            visible: widget.isApplication && widget.caRequest!.workflowStatus == WorkflowStatus.APPROVED,
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
                        workflow: widget.caRequest!.workflow,
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
