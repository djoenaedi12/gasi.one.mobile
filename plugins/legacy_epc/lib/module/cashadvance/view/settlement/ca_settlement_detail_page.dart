import 'dart:collection';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/module/cashadvance/model/ca_settlement.dart';
import 'package:epeoplecare/module/cashadvance/model/ca_settlement_detail.dart';
import 'package:epeoplecare/module/cashadvance/repository/ca_settlement_repository.dart';
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

class CASettlementDetailPage extends StatefulWidget {
  final String title;
  final bool isApplication;
  final CASettlement? caSettlement;
  final int index;
  const CASettlementDetailPage({Key? key, this.title="", this.isApplication = true, this.caSettlement, this.index=0}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _CASettlementDetailPageState();
}

class _CASettlementDetailPageState extends State<CASettlementDetailPage> {
  String _status = "";
  List<WorkflowDetail> approvalHistories = [];
  final CASettlementRepository _caSettlementRepository = Repository().getCASettlementRepository();
  bool deductionVisibility = false;

  @override
  void initState() {
    super.initState();
    renderHistory(widget.caSettlement!.workflow!.workflowDetails);
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
      
      _status = widget.caSettlement!.workflowStatus.toString().tr();
    });
  }

  _approvalProcess(WorkflowStatus status, String remark, WorkflowDetail? workflowDetail) {
    EasyLoading.show(status: "Please Wait".tr());
    Map<String, dynamic> parameters = HashMap();
    parameters["workflow"] = widget.caSettlement!.workflow;
    parameters["workflow_status"] = EnumProvider.convertToString(status);
    parameters["remark"] = remark;
    parameters["workflow_detail"] = workflowDetail;
    _caSettlementRepository.approvalProcess(parameters).then((value) {
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
    parameters["workflow"] = widget.caSettlement!.workflow!.id;
    if(employee != null) {
      parameters["employee"] = employee.id;
    }
    parameters["remark"] = remark;

    _caSettlementRepository.revokedRequest(parameters).then((value) {
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

  bool _canPullBack(bool isApplicant, CASettlement transaction) {
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
                    content: widget.caSettlement!.requestNo,
                  ),
                  InputForm().renderDetailField(
                    title: "Status".tr(),
                    content: _status,
                  ),
                  InputForm().renderDetailField(
                    title: "Submitted By".tr(),
                    content: widget.caSettlement!.employee!.name,
                  ),
                  InputForm().renderDetailField(
                    title: "Assignment".tr(),
                    content: widget.caSettlement!.assignment == true ? "Yes".tr() : "No".tr(),
                  ),
                  InputForm().renderDetailField(
                    title: "Assignee".tr(),
                    content: widget.caSettlement!.assignee != null ? widget.caSettlement!.assignee!.name : "",
                  ),
                  InputForm().renderDetailField(
                    title: "Policy".tr(),
                    content: widget.caSettlement!.caRequest!.caPolicy!.name,
                  ),
                  InputForm().renderDetailField(
                    title: "Purpose".tr(),
                    content: widget.caSettlement!.caRequest!.purpose,
                  ),
                  InputForm().renderDetailField(
                    title: "Date Of Use".tr(),
                    content: DateProvider.convertDateStrFormat(widget.caSettlement!.caRequest!.dateOfUse, "yyyy-MM-dd", "dd MMMM yyyy"),
                  ),
                  InputForm().renderDetailField(
                    title: "Payment Method".tr(),
                    content: widget.caSettlement!.caRequest!.paymentMethod!.name,
                  ),
                  InputForm().renderDetailField(
                    title: "Bank Name".tr(),
                    content: widget.caSettlement!.caRequest!.bankName,
                  ),
                  InputForm().renderDetailField(
                    title: "Bank Account No".tr(),
                    content: widget.caSettlement!.caRequest!.bankAccountNo,
                  ),
                  InputForm().renderDetailField(
                    title: "Bank Account Name".tr(),
                    content: widget.caSettlement!.caRequest!.bankAccountName,
                  ),
                  DetailPage(
                    isEditable: false,
                    itemList: widget.caSettlement!.caSettlementDetails,
                    title: "Detail".tr(),
                    renderTitle: (val, index) {
                      CASettlementDetail detail = val;
                      return Text(
                        "${detail.caRequestDetail!.name} (${detail.caRequestDetail!.caCategory!.name}) - ${NumberProvider.decimalFormatDouble(detail.caRequestDetail!.amount)} - ${NumberProvider.decimalFormatDouble(detail.amount)}"
                      );
                    },
                    renderBody: (data, index) {
                      CASettlementDetail detail = data;
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
                                Text(detail.caRequestDetail!.name),
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
                                Text(detail.caRequestDetail!.description ?? ""),
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
                                Text(detail.caRequestDetail!.caCategory!.name),
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
                                Text(NumberProvider.decimalFormatDouble(detail.caRequestDetail!.amount)),
                              ],
                            ),
                            const SizedBox(height: 5.0),
                            Row(
                              children: [
                                Text(
                                  "${"Settlement Amount".tr()}: ",
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
                        Text(NumberProvider.decimalFormatDouble(widget.caSettlement!.caRequest!.totalAmount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Total Settlement Amount".tr(),
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                        Text(NumberProvider.decimalFormatDouble(widget.caSettlement!.totalAmount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Variance".tr(),
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                        Text(NumberProvider.decimalFormatDouble(widget.caSettlement!.caRequest!.totalAmount! - widget.caSettlement!.totalAmount!),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  ),
                  InputForm().renderDetailField(
                    title: "Description".tr(),
                    content: widget.caSettlement!.description,
                  ),
                  MultipleAttachmentPage(
                    medias: widget.caSettlement!.medias,
                    attachment: widget.caSettlement!.attachment,
                  ),
                  CustomValuesPage(
                    customValues: widget.caSettlement!.customValues,
                    viewMode: true,
                  ),
                  ApprovalHistoryPage(
                    approvalHistory: approvalHistories,
                    workflowExecutors: widget.caSettlement!.workflowExecutors,
                  ),
                  
                ],
              ),
            ),
          ),
          Visibility(
            visible: _canPullBack(widget.isApplication, widget.caSettlement!) || (!widget.isApplication && (((widget.caSettlement!.workflowStatus == WorkflowStatus.SUBMITTED || widget.caSettlement!.workflowStatus == WorkflowStatus.APPROVAL_PROCESS || widget.caSettlement!.workflowStatus == WorkflowStatus.SENDBACKED) && widget.index == 0) || widget.caSettlement!.workflowStatus == WorkflowStatus.APPROVED)),
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
                        workflowStatus: widget.caSettlement!.workflowStatus,
                        workflow: widget.caSettlement!.workflow,
                        isPullBack: _canPullBack(widget.isApplication, widget.caSettlement!),
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
            visible: widget.isApplication && widget.caSettlement!.workflowStatus == WorkflowStatus.APPROVED,
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
                        workflow: widget.caSettlement!.workflow,
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
