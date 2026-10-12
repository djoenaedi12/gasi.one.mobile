import 'dart:collection';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/module/customfield/model/custom_value.dart';
import 'package:epeoplecare/module/customfield/view/custom_value_page.dart';
import 'package:epeoplecare/module/loan/model/loan_request.dart';
import 'package:epeoplecare/module/loan/repository/loan_request_installment_repository.dart';
import 'package:epeoplecare/module/loan/repository/loan_request_repository.dart';
import 'package:epeoplecare/module/loan/view/loan_detail_installment_page.dart';
import 'package:epeoplecare/module/workflow/model/node_type.dart';
import 'package:epeoplecare/module/workflow/model/workflow_detail.dart';
import 'package:epeoplecare/module/workflow/model/workflow_status.dart';
import 'package:epeoplecare/module/workflow/view/revoked_request_page.dart';
import 'package:epeoplecare/provider/date_provider.dart';
import 'package:epeoplecare/provider/enum_provider.dart';
import 'package:epeoplecare/provider/number_provider.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/validation/validation.dart';
import 'package:epeoplecare/module/workflow/view/approval_history_page.dart';
import 'package:epeoplecare/module/workflow/view/approval_process.dart';
import 'package:epeoplecare/view/shared/input_form.dart';
import 'package:epeoplecare/view/shared/message.dart';
import 'package:epeoplecare/view/shared/multiple_attachment_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class LoanDetailPage extends StatefulWidget {
  final String title;
  final bool isApplication;
  final LoanRequest? loanRequest;
  final int index;
  const LoanDetailPage({Key? key, this.title="", this.isApplication = true, this.loanRequest, this.index=0}): super(key: key);

  @override
  State<StatefulWidget> createState() => _LoanDetailPageState();
}

class _LoanDetailPageState extends State<LoanDetailPage> {
  String _status = "";
  List<WorkflowDetail> approvalHistories = [];
  final LoanRequestRepository _loanRequestRepository = Repository().getLoanRequestRepository();
  final form = GlobalKey<FormState>();
  final _approvedPeriodController = TextEditingController();
  final _approvedAmountController = TextEditingController();
  final _interestController = TextEditingController();
  final _firstInstallmentDateController = TextEditingController();
    bool loanInstallmentVisibility = true;
  final LoanRequestInstallmentRepository _loanRequestInstallmentRepository = Repository().getLoanRequestInstallmentRepository();
  List<CustomValue> _customValues = [];


  @override
  void initState() {
    super.initState();
    renderHistory(widget.loanRequest!.workflow!.workflowDetails);
    _interestController.text = widget.loanRequest!.interest.toString();
    _firstInstallmentDateController.text = DateProvider.convertDateStrFormat(widget.loanRequest!.firstInstallmentDate, "yyyy-MM-dd", "yyyy-MM-dd");
    _approvedPeriodController.text = widget.loanRequest!.approvedPeriod != null ? widget.loanRequest!.approvedPeriod.toString() : "";
    _approvedAmountController.text = widget.loanRequest!.approvedAmount != null ? widget.loanRequest!.approvedAmount.toString() : "";
    _customValues = widget.loanRequest!.customValues;

    _loanRequestInstallmentRepository.isVisible().then((value) {
      setState(() {
        loanInstallmentVisibility = value;
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
      
      _status = widget.loanRequest!.workflowStatus.toString().tr();
    });
  }

  _approvalProcess(WorkflowStatus status, String remark, WorkflowDetail? workflowDetail) {
    if (form.currentState!.validate()) {
      EasyLoading.show(status: "Please Wait".tr());
      Map<String, dynamic> parameters = HashMap();
      parameters["workflow"] = widget.loanRequest!.workflow;
      parameters["workflow_status"] = EnumProvider.convertToString(status);
      parameters["remark"] = remark;
      parameters["workflow_detail"] = workflowDetail;
      if(_isEditableForm()) {
        LoanRequest loanRequest = widget.loanRequest!;
        loanRequest.approvedPeriod = int.parse(_approvedPeriodController.text);
        loanRequest.approvedAmount = double.parse(_approvedAmountController.text);
        loanRequest.interest = double.parse(_interestController.text);
        loanRequest.firstInstallmentDate = DateProvider.convertDateStrFormat(_firstInstallmentDateController.text, "yyyy-MM-dd", "yyyy-MM-dd");
        loanRequest.customValues = _customValues;
        parameters["data"] = loanRequest;
      }

      _loanRequestRepository.approvalProcess(parameters).then((value) {
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
    parameters["workflow"] = widget.loanRequest!.workflow!.id;
    if(employee != null) {
      parameters["employee"] = employee.id;
    }
    parameters["remark"] = remark;

    _loanRequestRepository.revokedRequest(parameters).then((value) {
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

  bool _isEditableForm() {
    if(widget.loanRequest!.workflow!.workflowDetails.isNotEmpty) {
      WorkflowDetail workflowDetail = widget.loanRequest!.workflow!.workflowDetails[widget.loanRequest!.workflow!.workflowDetails.length - 1];
      if(workflowDetail.node != null && workflowDetail.node!.editable == true) {
        return true;
      }
    }

    return false;
  }

  bool _canPullBack(bool isApplicant, LoanRequest transaction) {
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
                      content: widget.loanRequest!.requestNo,
                    ),
                    InputForm().renderDetailField(
                      title: "Status".tr(),
                      content: _status,
                    ),
                    InputForm().renderDetailField(
                      title: "Submitted By".tr(),
                      content: widget.loanRequest!.employee!.name,
                    ),
                    InputForm().renderDetailField(
                      title: "Assignment".tr(),
                      content: widget.loanRequest!.assignment == true ? "Yes".tr() : "No".tr(),
                    ),
                    InputForm().renderDetailField(
                      title: "Assignee".tr(),
                      content: widget.loanRequest!.assignee != null ? widget.loanRequest!.assignee!.name : "",
                    ),
                    InputForm().renderDetailField(
                      title: "Loan Type".tr(),
                      content: widget.loanRequest!.loanType!.name,
                    ),
                    _isEditableForm()
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: InputForm().renderTextField(
                          fieldName: "Interest".tr(),
                          controller: _interestController,
                          validator: Validation.validateField,
                        ),
                      )
                    : InputForm().renderDetailField(
                        title: "Interest".tr(),
                        content: "${NumberProvider.decimalFormatDouble(widget.loanRequest!.interest)} %",
                      ),
                    _isEditableForm()
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: InputForm().renderDateField(
                          fieldName: "First Installment Date".tr(),
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1990),
                          lastDate: DateTime(2050),
                          controller: _firstInstallmentDateController,
                          validator: Validation.validateField,
                          onChanged: (value) {
                            if (value == null) return;

                            _firstInstallmentDateController.text = DateProvider.convertDate2Str(value, "yyyy-MM-dd");
                          },
                        ),
                      )
                    : InputForm().renderDetailField(
                        title: "First Installment Date".tr(),
                        content: DateProvider.convertDateStrFormat(widget.loanRequest!.firstInstallmentDate, "yyyy-MM-dd", "dd MMMM yyyy"),
                      ),
                    InputForm().renderDetailField(
                      title: "Requested Period".tr(),
                      content: "${widget.loanRequest!.requestedPeriod}",
                    ),
                    InputForm().renderDetailField(
                      title: "Requested Amount".tr(),
                      content: NumberProvider.decimalFormatDouble(widget.loanRequest!.requestedAmount),
                    ),
                    _isEditableForm()
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: InputForm().renderTextField(
                          fieldName: "Approved Period".tr(),
                          controller: _approvedPeriodController,
                          validator: Validation.validateField,
                          textInputType: TextInputType.number,
                        ),
                      )
                    : InputForm().renderDetailField(
                        title: "Approved Period".tr(),
                        content: "${widget.loanRequest!.approvedPeriod ?? ""}",
                      ),
                    _isEditableForm()
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: InputForm().renderTextField(
                          fieldName: "Approved Amount".tr(),
                          controller: _approvedAmountController,
                          validator: Validation.validateField,
                          textInputType: TextInputType.number,
                        ),
                      )
                    : InputForm().renderDetailField(
                        title: "Approved Amount".tr(),
                        content: NumberProvider.decimalFormatDouble(widget.loanRequest!.approvedAmount),
                      ),
                    InputForm().renderDetailField(
                      title: "Description".tr(),
                      content: widget.loanRequest!.description,
                    ),
                    MultipleAttachmentPage(
                      medias: widget.loanRequest!.medias,
                      attachment: widget.loanRequest!.attachment,
                    ),
                    _isEditableForm() 
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: CustomValuesPage(
                          customValues: _customValues,
                          editMode: true,
                        ),
                      )
                    : CustomValuesPage(
                        customValues: _customValues,
                        viewMode: true,
                      ),
                    ApprovalHistoryPage(
                      approvalHistory: approvalHistories,
                      workflowExecutors: widget.loanRequest!.workflowExecutors,
                    ),
                    Visibility(
                      visible: loanInstallmentVisibility,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: InputForm().renderButton(
                          text: "Installment".tr(),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoanDetailInstallmentPage(
                                  loanRequest: widget.loanRequest,
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
              visible: _canPullBack(widget.isApplication, widget.loanRequest!) || (!widget.isApplication && (((widget.loanRequest!.workflowStatus == WorkflowStatus.SUBMITTED || widget.loanRequest!.workflowStatus == WorkflowStatus.APPROVAL_PROCESS || widget.loanRequest!.workflowStatus == WorkflowStatus.SENDBACKED) && widget.index == 0) || widget.loanRequest!.workflowStatus == WorkflowStatus.APPROVED)),
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
                            workflowStatus: widget.loanRequest!.workflowStatus,
                            workflow: widget.loanRequest!.workflow,
                            isPullBack: _canPullBack(widget.isApplication, widget.loanRequest!),
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
              visible: widget.isApplication && widget.loanRequest!.workflowStatus == WorkflowStatus.APPROVED,
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
                          workflow: widget.loanRequest!.workflow,
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
