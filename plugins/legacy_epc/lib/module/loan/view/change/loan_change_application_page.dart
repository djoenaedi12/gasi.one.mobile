// ignore_for_file: use_build_context_synchronously

import 'dart:collection';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/custom_value.dart';
import 'package:epeoplecare/model/dropdown.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/module/customfield/model/custom_field.dart';
import 'package:epeoplecare/module/customfield/model/custom_value.dart';
import 'package:epeoplecare/module/customfield/repository/custom_field_repository.dart';
import 'package:epeoplecare/module/customfield/view/custom_value_page.dart';
import 'package:epeoplecare/module/loan/model/loan_change_reason.dart';
import 'package:epeoplecare/module/loan/model/loan_change_request.dart';
import 'package:epeoplecare/module/loan/model/loan_request.dart';
import 'package:epeoplecare/module/loan/repository/loan_change_request_repository.dart';
import 'package:epeoplecare/module/loan/repository/loan_request_installment_repository.dart';
import 'package:epeoplecare/module/loan/view/change/loan_change_detail_installment_page.dart';
import 'package:epeoplecare/module/loan/view/loan_request_picker.dart';
import 'package:epeoplecare/module/workflow/model/node.dart';
import 'package:epeoplecare/module/workflow/model/route_type.dart';
import 'package:epeoplecare/module/workflow/model/workflow_detail.dart';
import 'package:epeoplecare/module/workflow/model/workflow_executor.dart';
import 'package:epeoplecare/module/workflow/model/workflow_status.dart';
import 'package:epeoplecare/module/workflow/repository/node_repository.dart';
import 'package:epeoplecare/provider/date_provider.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/validation/validation.dart';
import 'package:epeoplecare/module/workflow/view/approval_history_page.dart';
import 'package:epeoplecare/module/workflow/view/approval_process.dart';
import 'package:epeoplecare/view/shared/input_form.dart';
import 'package:epeoplecare/view/shared/message.dart';
import 'package:epeoplecare/view/shared/multiple_attachment_page.dart';
import 'package:epeoplecare/view/shared/subordinate_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class LoanChangeApplicationPage extends StatefulWidget {
  final LoanChangeRequest? loanChangeRequest;
  const LoanChangeApplicationPage({Key? key, this.loanChangeRequest}): super(key: key);

  @override
  State<StatefulWidget> createState() => _LoanChangeApplicationPageState();
}

class _LoanChangeApplicationPageState extends State<LoanChangeApplicationPage> {
  final form = GlobalKey<FormState>();
  final _loanRequestController = TextEditingController();
  LoanRequest? _loanRequest;
  final _periodController = TextEditingController();
  final _extraAmountController = TextEditingController();
  final _effectiveDateController = TextEditingController();
  final _remarkController = TextEditingController();
  String? _alternateAttachment;
  List<WorkflowDetail> approvalHistories = [];
  final LoanChangeRequestRepository _loanChangeRequestRepository = Repository().getLoanChangeRequestRepository();
  final CustomFieldRepository _customFieldRepository = Repository().getCustomFieldRepository();
  List<CustomValue> _customValues = [];
  List<WorkflowExecutor> _workflowExecutors = [];
  final NodeRepository _nodeRepository = Repository().getNodeRepository();
  bool _isExpand = true;
  bool loanInstallmentVisibility = true;
  final LoanRequestInstallmentRepository _loanRequestInstallmentRepository = Repository().getLoanRequestInstallmentRepository();
  List<Dropdown> loanChangeReason = [
    Dropdown(value: LoanChangeReason.AMOUNTORPERIOD_CHANGE, label: LoanChangeReason.AMOUNTORPERIOD_CHANGE.toString().tr()),
    Dropdown(value: LoanChangeReason.EARLY_CLOSURE, label: LoanChangeReason.EARLY_CLOSURE.toString().tr()),
  ];
  LoanChangeReason _valLoanChangeReason = LoanChangeReason.AMOUNTORPERIOD_CHANGE;
  List<Media> _medias = [];
  final _assignmentController = TextEditingController();
  final _assigneeController = TextEditingController();
  bool _assignment = false;
  Employee? _assignee;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  _initData() {
    if(widget.loanChangeRequest != null) {
      _loanRequest = widget.loanChangeRequest!.loanRequest;
      _loanRequestController.text = _loanRequest!.requestNo ?? "";
      _periodController.text = widget.loanChangeRequest!.period.toString();
      _extraAmountController.text = widget.loanChangeRequest!.extraAmount.toString();
      _effectiveDateController.text = DateProvider.convertDateStrFormat(widget.loanChangeRequest!.effectiveDate, "yyyy-MM-dd", "yyyy-MM-dd");
      _remarkController.text = widget.loanChangeRequest!.description ?? "";
      _alternateAttachment = widget.loanChangeRequest!.attachment;
      renderHistory(widget.loanChangeRequest!.workflow!.workflowDetails);
      _customValues = widget.loanChangeRequest!.customValues;
      _initWorkflowExecutor(widget.loanChangeRequest!.workflow!.workflowExecutors);
      _medias = widget.loanChangeRequest!.medias;
      _assignment = widget.loanChangeRequest!.assignment!;
      _assignee = widget.loanChangeRequest!.assignee;
      if(_assignee != null) {
        _assigneeController.text = "${_assignee!.code} ${_assignee!.name}";
      }
    } else {
      _initCustomField();
      _initWorkflowExecutor(null);
    }

    _loanRequestInstallmentRepository.isVisible().then((value) {
      setState(() {
        loanInstallmentVisibility = value;
      });
    });
  }

  _initCustomField() {
    _customFieldRepository.listByType("LoanChangeRequest").then((items) {
      for (CustomField item in items) {
        setState(() {
          CustomValue customValue = CustomValue(
            null, 
            null, 
            null, 
            null, 
            null, 
            null, 
            null, 
            null,
            item, 
            item.type, 
            null, 
            null,
          );

          _customValues.add(customValue);
        });
      }
    });
  }

  // set data workflow executors jika terdapat node override
  _initWorkflowExecutor(List<WorkflowExecutor>? workflowExecutors) {
    if(Config.user!.employee == null) return;

    _nodeRepository.getOverrideNode(Config.user!.employee!, RouteType.LOAN_CHANGE).then((value) {
      setState(() {
        for (Node node in value) {
          WorkflowExecutor? workflowExecutorTmp;
          if(workflowExecutors != null) {
            for(WorkflowExecutor workflowExecutor in workflowExecutors) {
              if(workflowExecutor.node!.id == node.id) {
                workflowExecutorTmp = workflowExecutor;
                break;
              }
            }
          }

          workflowExecutorTmp ??= WorkflowExecutor(
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              node,
              null,
            );

          _workflowExecutors.add(workflowExecutorTmp);
        }
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
    });
  }

  _submitForm(WorkflowStatus workflowStatus, String remark) async {
    setState(() {
      _isExpand = true;
    });
    await Future.delayed(const Duration(milliseconds: 100));

    if (form.currentState!.validate()) {
      EasyLoading.show(status: "Please Wait".tr());

      Map<String, dynamic> parameters = HashMap();
      parameters["remark"] = remark;

      LoanChangeRequest loanChangeRequest = LoanChangeRequest(
        widget.loanChangeRequest != null ? widget.loanChangeRequest!.id : null, 
        widget.loanChangeRequest != null ? widget.loanChangeRequest!.creator : null, 
        widget.loanChangeRequest != null ? widget.loanChangeRequest!.creationTime : null, 
        widget.loanChangeRequest != null ? widget.loanChangeRequest!.updater : null, 
        widget.loanChangeRequest != null ? widget.loanChangeRequest!.updateTime : null, 
        widget.loanChangeRequest != null ? widget.loanChangeRequest!.version : null, 
        _customValues, 
        Config.excludeOldAttachment(_medias),
        widget.loanChangeRequest != null ? widget.loanChangeRequest!.workflow : null,
        widget.loanChangeRequest != null ? widget.loanChangeRequest!.requestNo : null,
        workflowStatus,
        Config.user!.employee,
        Config.oldAttachment(_alternateAttachment, _medias),
        _remarkController.text,
        _assignee, 
        _assignment, 
        parameters,
        _workflowExecutors,
        _loanRequest,
        _periodController.text == "" ? null : int.parse(_periodController.text),
        _extraAmountController.text == "" ? null : double.parse(_extraAmountController.text),
        DateProvider.convertDateStrFormat(_effectiveDateController.text, "yyyy-MM-dd", "yyyy-MM-dd"),
        _valLoanChangeReason,
      );
      if(widget.loanChangeRequest != null) {
        _loanChangeRequestRepository.update(id: widget.loanChangeRequest!.id!, entity: loanChangeRequest).then((value) {
          EasyLoading.dismiss();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MessagePage(
                icon: const Icon(Icons.check_circle, size: 100, color: Colors.green),
                title: "Success".tr(),
                subTitle: workflowStatus == WorkflowStatus.DRAFTED 
                        ? "Data has been saved".tr()
                        : "Data has been".tr(namedArgs: {"status": workflowStatus.toString().tr()}),
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
      } else {
        _loanChangeRequestRepository.save(entity: loanChangeRequest).then((value) {
          EasyLoading.dismiss();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MessagePage(
                icon: const Icon(Icons.check_circle, size: 100, color: Colors.green),
                title: "Success".tr(),
                subTitle: workflowStatus == WorkflowStatus.DRAFTED 
                        ? "Data has been saved".tr()
                        : "Data has been".tr(namedArgs: {"status": workflowStatus.toString().tr()}),
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
          "Application Form".tr(),
          style: TextStyle(
            color: Config.DEFAULT_ACCENT_COLOR,
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Visibility(
                      visible: Config.hasPermission("LoanChangeRequest", "RequestForOther") || Config.isManager,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: InputForm().renderBooleanField(
                          value: _assignment,
                          controller: _assignmentController,
                          fieldName: "Assignment".tr(),
                          validator: Validation.validateField,
                          onChanged: (val) {
                            setState(() {
                              _assignment = val;
                              if(_assignment == false) {
                                _assignee = null;
                                _assigneeController.text = "";
                              }
                            });
                          }
                        ),
                      ),
                    ),
                    Visibility(
                      visible: _assignment == true,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: InputForm().renderCustomField(
                          controller: _assigneeController,
                          fieldName: "Assignee".tr(),
                          validator: Validation.validateField,
                          onTap: () {
                            Map<String, dynamic> parameters = HashMap();
                            if(Config.user!.employee != null) {
                              parameters.putIfAbsent("subordinate", () => Config.user!.employee!.id);
                            }
                            parameters.putIfAbsent("entity", () => "LoanChangeRequest");
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SubordinatePicker(
                                  paramaters: parameters,
                                  employee: _assignee,
                                )
                              ),
                            ).then((value) {
                              if(value == null) return;

                              setState(() {
                                _assignee = value;
                                _assigneeController.text = "${_assignee!.code} ${_assignee!.name}";
                              });
                            });
                          }
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: InputForm().renderCustomField(
                        fieldName: "Loan Request".tr(),
                        controller: _loanRequestController,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LoanRequestPicker(
                                loanRequest: _loanRequest,
                                employee: _assignment ? _assignee : Config.user!.employee,
                              )
                            ),
                          ).then((value) {
                            if(value == null) return;

                            setState(() {
                              _loanRequest = value;
                              _loanRequestController.text = "${_loanRequest!.requestNo}";
                            });
                          });
                        }
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: InputForm().renderDropdownField(
                        fieldName: "Reason".tr(),
                        listItem: loanChangeReason,
                        value: _valLoanChangeReason,
                        onChanged: (value) {
                          setState(() {
                            _valLoanChangeReason = value as LoanChangeReason;
                          });
                          if(_valLoanChangeReason == LoanChangeReason.EARLY_CLOSURE) {
                            _periodController.text = "";
                            _extraAmountController.text = "";
                          }
                        },
                        validator: (value) {
                          if(value == null) {
                            return "This field is required".tr();
                          }
                          return null;
                        }
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: InputForm().renderTextField(
                        fieldName: "Period".tr(),
                        enabled: _valLoanChangeReason == LoanChangeReason.AMOUNTORPERIOD_CHANGE,
                        controller: _periodController,
                        validator: (value) {
                          if (_valLoanChangeReason == LoanChangeReason.AMOUNTORPERIOD_CHANGE && (value == null || value.isEmpty)) {
                            return "This field is required".tr();
                          }
                          return null;
                        },
                        textInputType: TextInputType.number,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: InputForm().renderTextField(
                        fieldName: "Extra Amount".tr(),
                        enabled: _valLoanChangeReason == LoanChangeReason.AMOUNTORPERIOD_CHANGE,
                        controller: _extraAmountController,
                        validator: (value) {
                          if (_valLoanChangeReason == LoanChangeReason.AMOUNTORPERIOD_CHANGE && (value == null || value.isEmpty)) {
                            return "This field is required".tr();
                          }
                          return null;
                        },
                        textInputType: TextInputType.number,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: InputForm().renderDateField(
                        fieldName: "Effective Date".tr(),
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1990),
                        lastDate: DateTime(2050),
                        controller: _effectiveDateController,
                        validator: Validation.validateField,
                        onChanged: (value) {
                          if (value == null) return;

                          _effectiveDateController.text = DateProvider.convertDate2Str(value, "yyyy-MM-dd");
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: InputForm().renderTextField(
                        fieldName: "Description".tr(),
                        controller: _remarkController,
                        maxLines: 5,
                        maxLength: 100,
                        textInputType: TextInputType.multiline,
                      ),
                    ),
                    MultipleAttachmentPage(
                      medias: _medias,
                      attachment: _alternateAttachment,
                      editable: true,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: CustomValuesPage(
                        customValues: _customValues,
                        editMode: widget.loanChangeRequest != null ? true : false,
                      ),
                    ),
                    ApprovalHistoryPage(
                      approvalHistory: approvalHistories,
                      workflowExecutors: _workflowExecutors,
                      editable: true,
                      isExpand: _isExpand,
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
                                builder: (context) => LoanChangeDetailInstallmentPage(
                                  loanRequest: _loanRequest,
                                  extraAmount: _extraAmountController.text != "" ? double.parse(_extraAmountController.text) : null,
                                  period: _periodController.text != "" ? int.parse(_periodController.text) : null,
                                  effectiveDate: _effectiveDateController.text != "" ? DateProvider.convertStr2Date(_effectiveDateController.text, "yyyy-MM-dd") : null,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: InputForm().renderButton(
                text: "Process".tr(),
                onPressed: () async {
                  setState(() {
                    _isExpand = true;
                  });
                  await Future.delayed(const Duration(milliseconds: 100));

                  if (form.currentState!.validate()) {
                    showModalBottomSheet(
                      isScrollControlled: true,
                      context: context,
                      builder: (BuildContext bc){
                        return ApprovalProcess(
                          workflowStatus: widget.loanChangeRequest != null ? widget.loanChangeRequest!.workflowStatus : null,
                          workflow: widget.loanChangeRequest != null ? widget.loanChangeRequest!.workflow : null,
                        );
                      },
                    ).then((value) {
                      if(value == null) return;

                      _submitForm(value['workflowStatus'], value['remark']);
                    });
                  }
                }
              ),
            ),
            const SizedBox(height: 10.0),
          ],
        ),
      ),
    );
  }
}
