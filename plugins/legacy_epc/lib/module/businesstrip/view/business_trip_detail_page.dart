import 'dart:collection';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/company/currency.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/module/businesstrip/model/business_trip_request.dart';
import 'package:epeoplecare/module/businesstrip/model/business_trip_request_allowance.dart';
import 'package:epeoplecare/module/businesstrip/model/business_trip_request_detail.dart';
import 'package:epeoplecare/module/businesstrip/repository/business_trip_request_repository.dart';
import 'package:epeoplecare/module/businesstrip/view/business_trip_detail_allowance_page.dart';
import 'package:epeoplecare/module/businesstrip/view/business_trip_settlement_page.dart';
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

class BusinessTripDetailPage extends StatefulWidget {
  final String title;
  final bool isApplication;
  final BusinessTripRequest? businessTripRequest;
  final int index;
  const BusinessTripDetailPage({Key? key, this.title = "", this.isApplication = true, this.businessTripRequest, this.index = 0}): super(key: key);

  @override
  State<StatefulWidget>  createState() => _BusinessTripDetailPageState();
}

class _BusinessTripDetailPageState extends State<BusinessTripDetailPage> {
  String _status = "";
  List<WorkflowDetail> approvalHistories = [];
  final BusinessTripRequestRepository _businessTripRequestRepository = Repository().getBusinessTripRequestRepository();
  bool deductionVisibility = false;

  @override
  void initState() {
    super.initState();
    renderHistory(widget.businessTripRequest!.workflow!.workflowDetails);
    _businessTripRequestRepository.isDeductionVisible().then((value) {
      setState(() {
        deductionVisibility = value;
      });
    });
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
      
      _status = widget.businessTripRequest!.workflowStatus.toString().tr();
    });
  }

  _approvalProcess(WorkflowStatus status, String remark, WorkflowDetail? workflowDetail) {
    EasyLoading.show(status: "Please Wait".tr());
    Map<String, dynamic> parameters = HashMap();
    parameters["workflow"] = widget.businessTripRequest!.workflow;
    parameters["workflow_status"] = EnumProvider.convertToString(status);
    parameters["remark"] = remark;
    parameters["workflow_detail"] = workflowDetail;
    _businessTripRequestRepository.approvalProcess(parameters).then((value) {
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
    parameters["workflow"] = widget.businessTripRequest!.workflow!.id;
    if(employee != null) {
      parameters["employee"] = employee.id;
    }
    parameters["remark"] = remark;

    _businessTripRequestRepository.revokedRequest(parameters).then((value) {
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

  bool _canPullBack(bool isApplicant, BusinessTripRequest transaction) {
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
                    content: widget.businessTripRequest!.requestNo,
                  ),
                  InputForm().renderDetailField(
                    title: "Status".tr(),
                    content: _status,
                  ),
                  InputForm().renderDetailField(
                    title: "Submitted By".tr(),
                    content: widget.businessTripRequest!.employee!.name,
                  ),
                  InputForm().renderDetailField(
                    title: "Assignment".tr(),
                    content: widget.businessTripRequest!.assignment == true ? "Yes".tr() : "No".tr(),
                  ),
                  InputForm().renderDetailField(
                    title: "Assignee".tr(),
                    content: widget.businessTripRequest!.assignee != null ? widget.businessTripRequest!.assignee!.name : "",
                  ),
                  DetailPage(
                    isEditable: false,
                    itemList: widget.businessTripRequest!.businessTripRequestDetails,
                    title: "Application Detail".tr(),
                    renderTitle: (val, index) {
                      BusinessTripRequestDetail detail = val;
                      return Text(
                        "${DateProvider.convertDateStrFormat(detail.dateFrom, "yyyy-MM-dd", "dd MMMM yyyy")} - ${DateProvider.convertDateStrFormat(detail.dateTo, "yyyy-MM-dd", "dd MMMM yyyy")}"
                      );
                    },
                    renderBody: (data, index) {
                      BusinessTripRequestDetail detail = data;
                      Currency? currency;
                      double totalAllowanceAmount = 0.0;
                      for (BusinessTripRequestAllowance allowance in detail.businessTripRequestAllowances) {
                        currency = allowance.currency;
                        totalAllowanceAmount += allowance.allowanceAmount - (allowance.dedcutionAmount ?? 0.0);
                      }
                      return Container(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "${"Purpose".tr()}: ",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(detail.purpose!.name),
                              ],
                            ),
                            const SizedBox(height: 5.0),
                            Row(
                              children: [
                                Text(
                                  "${"Destination".tr()}: ",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(detail.destination!.name),
                              ],
                            ),
                            const SizedBox(height: 5.0),
                            Row(
                              children: [
                                Text(
                                  "${"Date From".tr()}: ",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(DateProvider.convertDateStrFormat(detail.dateFrom, "yyyy-MM-dd HH:mm:ss", "dd MMMM yyyy HH:mm")),
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
                                Text(DateProvider.convertDateStrFormat(detail.dateTo, "yyyy-MM-dd HH:mm:ss", "dd MMMM yyyy HH:mm")),
                              ],
                            ),
                            const SizedBox(height: 5.0),
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BusinessTripDetailAllowancePage(
                                      businessTripRequestAllowances: detail.businessTripRequestAllowances,
                                      deductionVisibility: deductionVisibility,
                                    ),
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  Text(
                                    "${"Total Allowance".tr()}: ",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "${currency != null ? currency.symbol : ""} ${NumberProvider.decimalFormatDouble(totalAllowanceAmount)}",
                                  ),
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
                    content: widget.businessTripRequest!.description,
                  ),
                  MultipleAttachmentPage(
                    medias: widget.businessTripRequest!.medias,
                    attachment: widget.businessTripRequest!.attachment,
                  ),
                  CustomValuesPage(
                    customValues: widget.businessTripRequest!.customValues,
                    viewMode: true,
                  ),
                  ApprovalHistoryPage(
                    approvalHistory: approvalHistories,
                    workflowExecutors: widget.businessTripRequest!.workflowExecutors,
                  ),
                  Visibility(
                    visible: widget.isApplication && widget.businessTripRequest!.workflowStatus == WorkflowStatus.APPROVED,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: InputForm().renderButton(
                        text: "Settlement".tr(),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BusinessTripSettlementPage(
                                businessTripRequest: widget.businessTripRequest!,
                                deductionVisibility: deductionVisibility,
                              ),
                            ),
                          );
                        }
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Visibility(
            visible: _canPullBack(widget.isApplication, widget.businessTripRequest!) || (!widget.isApplication && (((widget.businessTripRequest!.workflowStatus == WorkflowStatus.SUBMITTED || widget.businessTripRequest!.workflowStatus == WorkflowStatus.APPROVAL_PROCESS || widget.businessTripRequest!.workflowStatus == WorkflowStatus.SENDBACKED) && widget.index == 0) || widget.businessTripRequest!.workflowStatus == WorkflowStatus.APPROVED)),
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
                        workflowStatus: widget.businessTripRequest!.workflowStatus,
                        workflow: widget.businessTripRequest!.workflow,
                        isPullBack: _canPullBack(widget.isApplication, widget.businessTripRequest!),
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
            visible: widget.isApplication && widget.businessTripRequest!.workflowStatus == WorkflowStatus.APPROVED,
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
                        workflow: widget.businessTripRequest!.workflow,
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
