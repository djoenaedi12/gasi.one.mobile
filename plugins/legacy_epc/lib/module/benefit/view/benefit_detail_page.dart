import 'dart:collection';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/module/benefit/model/benefit_transaction_detail.dart';
import 'package:epeoplecare/module/customfield/view/custom_value_page.dart';
import 'package:epeoplecare/module/benefit/model/benefit_transaction.dart';
import 'package:epeoplecare/module/benefit/repository/benefit_transaction_repository.dart';
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

class BenefitDetailPage extends StatefulWidget {
  final String title;
  final bool isApplication;
  final BenefitTransaction? benefitRequest;
  final int index;
  const BenefitDetailPage({Key? key, this.title = "", this.isApplication = true, this.benefitRequest, this.index = 0}) : super(key: key);

  @override
  State<StatefulWidget>  createState() => _BenefitDetailPageState();
}

class _BenefitDetailPageState extends State<BenefitDetailPage> {
  String _status = "";
  List<WorkflowDetail> approvalHistories = [];
  final BenefitTransactionRepository _benefitRequestRepository = Repository().getBenefitTransactionRepository();
  final form = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    renderHistory(widget.benefitRequest!.workflow!.workflowDetails);
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
      
      _status = widget.benefitRequest!.workflowStatus.toString().tr();
    });
  }

  _approvalProcess(WorkflowStatus status, String remark, WorkflowDetail? workflowDetail) {
    if (form.currentState!.validate()) {
      EasyLoading.show(status: "Please Wait".tr());
      Map<String, dynamic> parameters = HashMap();
      parameters["workflow"] = widget.benefitRequest!.workflow;
      parameters["workflow_status"] = EnumProvider.convertToString(status);
      parameters["remark"] = remark;
      parameters["workflow_detail"] = workflowDetail;
      _benefitRequestRepository.approvalProcess(parameters).then((value) {
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
  }

  _revokedRequest(Employee? employee, String remark) {
    EasyLoading.show(status: "Please Wait".tr());
    Map<String, dynamic> parameters = HashMap();
    parameters["workflow"] = widget.benefitRequest!.workflow!.id;
    if(employee != null) {
      parameters["employee"] = employee.id;
    }
    parameters["remark"] = remark;

    _benefitRequestRepository.revokedRequest(parameters).then((value) {
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
            title: "Error",
            subTitle: onError.toString(),
          ),
        ),
      );
    });
  }

  bool _canPullBack(bool isApplicant, BenefitTransaction transaction) {
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
      body: Form(
        key: form,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    InputForm().renderDetailField(
                      title: "Request No".tr(),
                      content: widget.benefitRequest!.requestNo,
                    ),
                    InputForm().renderDetailField(
                      title: "Status".tr(),
                      content: _status,
                    ),
                    InputForm().renderDetailField(
                      title: "Submitted By".tr(),
                      content: widget.benefitRequest!.employee!.name,
                    ),
                    InputForm().renderDetailField(
                      title: "Assignment".tr(),
                      content: widget.benefitRequest!.assignment == true ? "Yes".tr() : "No".tr(),
                    ),
                    InputForm().renderDetailField(
                      title: "Assignee".tr(),
                      content: widget.benefitRequest!.assignee != null ? widget.benefitRequest!.assignee!.name : "",
                    ),
                    InputForm().renderDetailField(
                      title: "Personal Request".tr(),
                      content: (widget.benefitRequest!.personalRequest ? "Yes" : "No").tr(),
                    ),
                    Visibility(
                      visible: widget.benefitRequest!.personalRequest == false,
                      child: InputForm().renderDetailField(
                        title: "Dependent".tr(),
                        content: widget.benefitRequest!.employeeDependent != null ? widget.benefitRequest!.employeeDependent!.name : "",
                      ),
                    ),
                    InputForm().renderDetailField(
                      title: "Requested Date".tr(),
                      content: DateProvider.convertDateStrFormat(widget.benefitRequest!.requestedDate, "yyyy-MM-dd", "EEEE, dd MMMM yyyy"),
                    ),
                    DetailPage(
                      isEditable: false,
                      itemList: widget.benefitRequest!.benefitTransactionDetails,
                      title: "Application Detail".tr(),
                      renderTitle: (val, index) {
                        BenefitTransactionDetail detail = val;
                        return Text(detail.benefit!.name);
                      },
                      renderBody: (data, index) {
                        BenefitTransactionDetail detail = data;
                        return Container(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "${"Incident Date".tr()}: ",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(DateProvider.convertDateStrFormat(detail.incidentDate, "yyyy-MM-dd", "dd MMMM yyyy")),
                                ],
                              ),
                              const SizedBox(height: 5.0),
                              Row(
                                children: [
                                  Text(
                                    "${"Requested Amount".tr()}: ",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(NumberProvider.decimalFormatDouble(detail.requestedAmount)),
                                ],
                              ),
                              const SizedBox(height: 5.0),
                              Row(
                                children: [
                                  Text(
                                    "${"Approved Amount".tr()}: ",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(NumberProvider.decimalFormatDouble(detail.approvedAmount)),
                                ],
                              ),
                              SizedBox(height: detail.benefit!.nonBalance == false ? 5.0 : 0.0),
                              Visibility(
                                visible: detail.benefit!.nonBalance == false,
                                child: Row(
                                  children: [
                                    Text(
                                      "${"Balance".tr()}: ",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(NumberProvider.decimalFormatDouble(detail.balance)),
                                  ],
                                ),
                              )
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
                          Text("Requested Amount".tr(),
                            style: const TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                          Text(NumberProvider.decimalFormatDouble(widget.benefitRequest!.requestedAmount),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Approved Amount".tr(),
                            style: const TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                          Text(NumberProvider.decimalFormatDouble(widget.benefitRequest!.approvedAmount),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    ),
                    InputForm().renderDetailField(
                      title: "Description".tr(),
                      content: widget.benefitRequest!.description,
                    ),
                    MultipleAttachmentPage(
                      medias: widget.benefitRequest!.medias,
                      attachment: widget.benefitRequest!.attachment,
                    ),
                    CustomValuesPage(
                      customValues: widget.benefitRequest!.customValues,
                      viewMode: true,
                    ),
                    ApprovalHistoryPage(
                      approvalHistory: approvalHistories,
                      workflowExecutors: widget.benefitRequest!.workflowExecutors,
                    ),
                  ],
                ),
              ),
            ),
            Visibility(
              visible: _canPullBack(widget.isApplication, widget.benefitRequest!) || (!widget.isApplication && (((widget.benefitRequest!.workflowStatus == WorkflowStatus.SUBMITTED || widget.benefitRequest!.workflowStatus == WorkflowStatus.APPROVAL_PROCESS || widget.benefitRequest!.workflowStatus == WorkflowStatus.SENDBACKED) && widget.index == 0) || widget.benefitRequest!.workflowStatus == WorkflowStatus.APPROVED)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: InputForm().renderButton(
                  text: "Process".tr(),
                  onPressed: () {
                    if (form.currentState!.validate()) {
                      showModalBottomSheet(
                        isScrollControlled: true,
                        context: context,
                        builder: (BuildContext bc){
                          return ApprovalProcess(
                            isApplicant: false,
                            workflowStatus: widget.benefitRequest!.workflowStatus,
                            workflow: widget.benefitRequest!.workflow,
                            isPullBack: _canPullBack(widget.isApplication, widget.benefitRequest!),
                          );
                        },
                      ).then((value) {
                        if(value == null) return;

                        _approvalProcess(value['workflowStatus'], value['remark'], value["workflowDetail"]);
                      });
                    }
                  }
                ),
              ),
            ),
            Visibility(
              visible: widget.isApplication && widget.benefitRequest!.workflowStatus == WorkflowStatus.APPROVED,
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
                          workflow: widget.benefitRequest!.workflow,
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
      ),
    );
  }
}
