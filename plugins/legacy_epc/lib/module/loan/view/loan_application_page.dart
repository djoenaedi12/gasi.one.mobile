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
import 'package:epeoplecare/module/loan/model/interest_type.dart';
import 'package:epeoplecare/module/loan/model/loan_request.dart';
import 'package:epeoplecare/module/loan/model/loan_type.dart';
import 'package:epeoplecare/module/loan/repository/loan_request_installment_repository.dart';
import 'package:epeoplecare/module/loan/repository/loan_request_repository.dart';
import 'package:epeoplecare/module/loan/repository/loan_type_repository.dart';
import 'package:epeoplecare/module/loan/repository/loan_validation_interest_repository.dart';
import 'package:epeoplecare/module/loan/repository/loan_validation_repository.dart';
import 'package:epeoplecare/module/loan/view/loan_detail_installment_page.dart';
import 'package:epeoplecare/module/workflow/model/node.dart';
import 'package:epeoplecare/module/workflow/model/route_type.dart';
import 'package:epeoplecare/module/workflow/model/workflow_detail.dart';
import 'package:epeoplecare/module/workflow/model/workflow_executor.dart';
import 'package:epeoplecare/module/workflow/model/workflow_status.dart';
import 'package:epeoplecare/module/workflow/repository/node_repository.dart';
import 'package:epeoplecare/provider/alert_provider.dart';
import 'package:epeoplecare/provider/date_provider.dart';
import 'package:epeoplecare/repository/parameter_repository.dart';
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

class LoanApplicationPage extends StatefulWidget {
  final LoanRequest? loanRequest;
  const LoanApplicationPage({Key? key, this.loanRequest}): super(key: key);

  @override
  State<StatefulWidget> createState() => _LoanApplicationPageState();
}

class _LoanApplicationPageState extends State<LoanApplicationPage> {
  final form = GlobalKey<FormState>();
  LoanType? _valLoanType;
  List<Dropdown> loanTypes = [];
  final _interestController = TextEditingController();
  final _firstInstallmentDateController = TextEditingController();
  final _requestedPeriodController = TextEditingController();
  final _requestedAmountController = TextEditingController();
  final _remarkController = TextEditingController();
  String? _alternateAttachment;
  List<WorkflowDetail> approvalHistories = [];
  final LoanRequestRepository _loanRequestRepository = Repository().getLoanRequestRepository();
  final LoanTypeRepository _loanTypeRepository = Repository().getLoanTypeRepository();
  final LoanValidationInterestRepository _loanValidationInterestRepository = Repository().getLoanValidationInterestRepository();
  final LoanValidationRepository _loanValidationRepository = Repository().getLoanValidationRepository();
  final CustomFieldRepository _customFieldRepository = Repository().getCustomFieldRepository();
  List<CustomValue> _customValues = [];
  List<WorkflowExecutor> _workflowExecutors = [];
  final NodeRepository _nodeRepository = Repository().getNodeRepository();
  bool _isExpand = true;
  bool loanInstallmentVisibility = true;
  bool firstInstallmentVisibility = true;
  final LoanRequestInstallmentRepository _loanRequestInstallmentRepository = Repository().getLoanRequestInstallmentRepository();
  final ParameterRepository _paramaterRepository = Repository().getParameterRepository();
  List<Media> _medias = [];
  final _assignmentController = TextEditingController();
  final _assigneeController = TextEditingController();
  bool _assignment = false;
  Employee? _assignee;

  @override
  void initState() {
    super.initState();
    _initData();
    _getLoanType();
  }

  _initData() {
    if(widget.loanRequest != null) {
      _interestController.text = widget.loanRequest!.interest.toString();
      _firstInstallmentDateController.text = DateProvider.convertDateStrFormat(widget.loanRequest!.firstInstallmentDate, "yyyy-MM-dd", "yyyy-MM-dd");
      _requestedPeriodController.text = widget.loanRequest!.requestedPeriod.toString();
      _requestedAmountController.text = widget.loanRequest!.requestedAmount.toString();
      _remarkController.text = widget.loanRequest!.description ?? "";
      _alternateAttachment = widget.loanRequest!.attachment;
      renderHistory(widget.loanRequest!.workflow!.workflowDetails);
      _customValues = widget.loanRequest!.customValues;
      _initWorkflowExecutor(widget.loanRequest!.workflow!.workflowExecutors);
      _medias = widget.loanRequest!.medias;
      _assignment = widget.loanRequest!.assignment!;
      _assignee = widget.loanRequest!.assignee;
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

    _paramaterRepository.getFirstInstallmentVisibility().then((value) {
      if (value == null) return;

      setState(() {
        if (value.value == "0") {
          firstInstallmentVisibility = false;
        }
      });
    });
  }

  _initCustomField() {
    _customFieldRepository.listByType("LoanRequest").then((items) {
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

    _nodeRepository.getOverrideNode(Config.user!.employee!, RouteType.LOAN).then((value) {
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

  _getLoanType() {
    Dropdown dropdown = Dropdown(value: null, label: "Select Loan Type".tr());
    loanTypes.add(dropdown);
    _loanTypeRepository.list().then((value) async {
      if(value.isEmpty) return;

      setState(() {
        for (var i = 0; i < value.length; i++) {
          Dropdown dropdown = Dropdown(value: value[i], label: value[i].name);
          if(widget.loanRequest != null && widget.loanRequest!.loanType!.id == value[i].id) {
            _valLoanType = dropdown.value;
          }

          loanTypes.add(dropdown);
        }
      });
    });
  }

  _submitForm(WorkflowStatus workflowStatus, String remark) async {
    setState(() {
      _isExpand = true;
    });
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (form.currentState!.validate()) {
      EasyLoading.show(status: "Please Wait".tr());
      Employee? employee = Config.user!.employee;
      if(_assignment) {
        employee = _assignee;
      }
      if(employee != null) {
        List<String> errors = await _loanValidationRepository.isEligible(employee, _valLoanType!, int.parse(_requestedPeriodController.text), double.parse(_requestedAmountController.text), widget.loanRequest?.id, _firstInstallmentDateController.text.isNotEmpty ? DateProvider.convertStr2Date(_firstInstallmentDateController.text, "yyyy-MM-dd") : null);

        if(errors.isNotEmpty) {
          EasyLoading.dismiss();
          String message = "";
          for (var i=0; i<errors.length; i++) {
            message += "${errors[i]}\n";
          }
          
          AlertProvider.showAlertDialog(
            message: message,
          );
          return;
        }
      }

      Map<String, dynamic> parameters = HashMap();
      parameters["remark"] = remark;

      LoanRequest loanRequest = LoanRequest(
        widget.loanRequest != null ? widget.loanRequest!.id : null, 
        widget.loanRequest != null ? widget.loanRequest!.creator : null, 
        widget.loanRequest != null ? widget.loanRequest!.creationTime : null, 
        widget.loanRequest != null ? widget.loanRequest!.updater : null, 
        widget.loanRequest != null ? widget.loanRequest!.updateTime : null, 
        widget.loanRequest != null ? widget.loanRequest!.version : null, 
        _customValues, 
        Config.excludeOldAttachment(_medias),
        widget.loanRequest != null ? widget.loanRequest!.workflow : null,
        widget.loanRequest != null ? widget.loanRequest!.requestNo : null,
        workflowStatus,
        Config.user!.employee,
        Config.oldAttachment(_alternateAttachment, _medias),
        _remarkController.text,
        _assignee, 
        _assignment, 
        parameters,
        _workflowExecutors,
        _valLoanType,
        DateProvider.convertDateStrFormat(_firstInstallmentDateController.text, "yyyy-MM-dd", "yyyy-MM-dd"),
        int.parse(_requestedPeriodController.text),
        double.parse(_requestedAmountController.text),
        widget.loanRequest != null ? widget.loanRequest!.approvedPeriod : null,
        widget.loanRequest != null ? widget.loanRequest!.approvedAmount : null,
        double.parse(_interestController.text),
      );
      if(widget.loanRequest != null) {
        _loanRequestRepository.update(id: widget.loanRequest!.id!, entity: loanRequest).then((value) {
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
        _loanRequestRepository.save(entity: loanRequest).then((value) {
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

  _updateInterest() async {
    double interest = 0.0;
    Employee? employee = Config.user!.employee;
    if(_assignment) {
      employee = _assignee;
    }
    if(employee != null && _valLoanType != null && _valLoanType!.interestType != InterestType.NO_INTEREST && _requestedPeriodController.text != "") {
      interest = await _loanValidationInterestRepository.getInterest(employee, _valLoanType!, int.parse(_requestedPeriodController.text));
    }

    setState(() {
      _interestController.text = interest.toString();  
    });
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
                      visible: Config.hasPermission("LoanRequest", "RequestForOther") || Config.isManager,
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
                            parameters.putIfAbsent("entity", () => "LoanRequest");
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
                      child: InputForm().renderDropdownField(
                        fieldName: "Loan Type".tr(),
                        value: _valLoanType,
                        listItem: loanTypes,
                        onChanged: (val) {
                          setState(() {
                            _valLoanType = val as LoanType?;
                          });

                          _updateInterest();
                        },
                        validator: (val) {
                          if(val == null) {
                            return "This field is required".tr();
                          }
                          return null;
                        }
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: InputForm().renderTextField(
                        fieldName: "Interest".tr(),
                        controller: _interestController,
                        validator: Validation.validateField,
                        enabled: false,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: InputForm().renderDateField(
                        fieldName: "First Installment Date".tr(),
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1990),
                        lastDate: DateTime(2050),
                        controller: _firstInstallmentDateController,
                        validator: firstInstallmentVisibility ? Validation.validateField : null,
                        onChanged: (value) {
                          if (value == null) return;

                          _firstInstallmentDateController.text = DateProvider.convertDate2Str(value, "yyyy-MM-dd");
                        },
                        enabled: firstInstallmentVisibility
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: InputForm().renderTextField(
                        fieldName: "Requested Period".tr(),
                        controller: _requestedPeriodController,
                        validator: Validation.validateField,
                        textInputType: TextInputType.number,
                        onChanged: (val) {
                          _updateInterest();
                        }
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: InputForm().renderTextField(
                        fieldName: "Requested Amount".tr(),
                        controller: _requestedAmountController,
                        validator: Validation.validateField,
                        textInputType: TextInputType.number,
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
                        editMode: widget.loanRequest != null ? true : false,
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
                                builder: (context) => LoanDetailInstallmentPage(
                                  amount: _requestedAmountController.text != "" ? double.parse(_requestedAmountController.text) : null,
                                  period: _requestedPeriodController.text != "" ? int.parse(_requestedPeriodController.text) : null,
                                  interest: _interestController.text != "" ? double.parse(_interestController.text) : null,
                                  interestType: _valLoanType != null ? _valLoanType!.interestType : null,
                                  firstInstallmentDate: _firstInstallmentDateController.text != "" ? DateProvider.convertStr2Date(_firstInstallmentDateController.text, "yyyy-MM-dd") : null,
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
                          workflowStatus: widget.loanRequest != null ? widget.loanRequest!.workflowStatus : null,
                          workflow: widget.loanRequest != null ? widget.loanRequest!.workflow : null,
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
