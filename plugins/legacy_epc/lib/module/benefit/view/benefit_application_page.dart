// ignore_for_file: use_build_context_synchronously

import 'dart:collection';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/custom_value.dart';
import 'package:epeoplecare/model/dropdown.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/model/employee/employee_dependent.dart';
import 'package:epeoplecare/module/benefit/model/benefit_transaction_detail.dart';
import 'package:epeoplecare/module/benefit/view/benefit_application_detail_page.dart';
import 'package:epeoplecare/module/customfield/model/custom_field.dart';
import 'package:epeoplecare/module/customfield/model/custom_value.dart';
import 'package:epeoplecare/module/customfield/repository/custom_field_repository.dart';
import 'package:epeoplecare/module/customfield/view/custom_value_page.dart';
import 'package:epeoplecare/module/benefit/model/benefit_transaction.dart';
import 'package:epeoplecare/module/benefit/repository/benefit_transaction_repository.dart';
import 'package:epeoplecare/module/benefit/repository/benefit_repository.dart';
import 'package:epeoplecare/module/workflow/model/node.dart';
import 'package:epeoplecare/module/workflow/model/route_type.dart';
import 'package:epeoplecare/module/workflow/model/workflow_detail.dart';
import 'package:epeoplecare/module/workflow/model/workflow_executor.dart';
import 'package:epeoplecare/module/workflow/model/workflow_status.dart';
import 'package:epeoplecare/module/workflow/repository/node_repository.dart';
import 'package:epeoplecare/provider/alert_provider.dart';
import 'package:epeoplecare/provider/date_provider.dart';
import 'package:epeoplecare/provider/number_provider.dart';
import 'package:epeoplecare/repository/employee/employee_dependent_repository.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/module/workflow/view/approval_history_page.dart';
import 'package:epeoplecare/module/workflow/view/approval_process.dart';
import 'package:epeoplecare/validation/validation.dart';
import 'package:epeoplecare/view/shared/detail_page.dart';
import 'package:epeoplecare/view/shared/input_form.dart';
import 'package:epeoplecare/view/shared/message.dart';
import 'package:epeoplecare/view/shared/multiple_attachment_page.dart';
import 'package:epeoplecare/view/shared/subordinate_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class BenefitApplicationPage extends StatefulWidget {
  final BenefitTransaction? benefitRequest;
  const BenefitApplicationPage({Key? key, this.benefitRequest}) : super(key: key);
  @override
  State<StatefulWidget>  createState() => _BenefitApplicationPageState();
}

class _BenefitApplicationPageState extends State<BenefitApplicationPage> {
  final form = GlobalKey<FormState>();
  List<Dropdown> benefits = [];
  bool? _valPersonalRequest = true;
  List<Dropdown> personalRequests = [];
  EmployeeDependent? _valEmployeeDependent;
  List<Dropdown> employeeDependents = [];
  final _remarkController = TextEditingController();
  String? _alternateAttachment;
  List<WorkflowDetail> approvalHistories = [];
  final BenefitTransactionRepository benefitsRequestRepository = Repository().getBenefitTransactionRepository();
  final BenefitRepository benefitsRepository = Repository().getBenefitRepository();
  final EmployeeDependentRepository employeeDependentsRepository = Repository().getEmployeeDependentRepository();
  final CustomFieldRepository _customFieldRepository = Repository().getCustomFieldRepository();
  List<CustomValue> _customValues = [];
  List<WorkflowExecutor> _workflowExecutors = [];
  final NodeRepository _nodeRepository = Repository().getNodeRepository();
  bool _isExpand = true;
  List<BenefitTransactionDetail> benefitTransactionDetails = [];
  double requestedAmount = 0;
  double approvedAmount = 0;
  List<Media> _medias = [];
  final _assignmentController = TextEditingController();
  final _assigneeController = TextEditingController();
  bool _assignment = false;
  Employee? _assignee;

  @override
  void initState() {
    super.initState();
    _initData();
    _getEmployeeDependent();
  }

  _initData() {
    Dropdown dropdownYes = const Dropdown(value: true, label: "Yes");
    Dropdown dropdownNo = const Dropdown(value: false, label: "No");
    personalRequests.add(dropdownYes);
    personalRequests.add(dropdownNo);
    if (widget.benefitRequest != null) {
      _valPersonalRequest = widget.benefitRequest!.personalRequest;
      _remarkController.text = widget.benefitRequest!.description ?? "";
      _alternateAttachment = widget.benefitRequest!.attachment;
      renderHistory(widget.benefitRequest!.workflow!.workflowDetails);
      _customValues = widget.benefitRequest!.customValues;
      _initWorkflowExecutor(widget.benefitRequest!.workflow!.workflowExecutors);
      benefitTransactionDetails = widget.benefitRequest!.benefitTransactionDetails;
      _valEmployeeDependent = widget.benefitRequest!.employeeDependent;
      _calculateApprovedAmount();
      _medias = widget.benefitRequest!.medias;
      _assignment = widget.benefitRequest!.assignment!;
      _assignee = widget.benefitRequest!.assignee;
      if(_assignee != null) {
        _assigneeController.text = "${_assignee!.code} ${_assignee!.name}";
      }
    } else {
      _initCustomField();
      _initWorkflowExecutor(null);
    }
  }

  _initCustomField() {
    _customFieldRepository.listByType("BenefitTransaction").then((items) {
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
    if (Config.user!.employee == null) return;

    _nodeRepository
        .getOverrideNode(Config.user!.employee!, RouteType.BENEFIT)
        .then((value) {
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
      Duration duration = DateProvider.convertDuration(
          durationStr: Config.serverTimezone, inverse: true);
      for (WorkflowDetail history in histories) {
        DateTime? executedDate = DateProvider.convertStr2Date(history.executedDate, "yyyy-MM-dd HH:mm:ss");
        history.executedDate = DateProvider.convertDate2Str(DateProvider.convertToLocal(executedDate, duration),"yyyy-MM-dd HH:mm:ss");
      }

      histories.sort((a, b) {
        if (a.executedDate == null || b.executedDate == null) return 1;
        return b.executedDate!.compareTo(a.executedDate!);
      });
      approvalHistories.clear();
      for (var item in histories) {
        if (item.executedDate != null &&
            item.workflowStatus != null &&
            item.executor != null) {
          approvalHistories.add(item);
        }
      }
    });
  }

  _getEmployeeDependent() {
    Dropdown dropdown = Dropdown(
        value: null,
        label: "Select Dependent".tr());
    employeeDependents.add(dropdown);

    employeeDependentsRepository
        .listByEmployee(Config.user!.employee!)
        .then((value) async {
      if (value.isEmpty) return;

      setState(() {
        for (var i = 0; i < value.length; i++) {
          Dropdown dropdown =
              Dropdown(value: value[i], label: value[i].name);
          if (widget.benefitRequest != null &&
              widget.benefitRequest!.employeeDependent!.id == value[i].id) {
            _valEmployeeDependent = dropdown.value;
          }

          employeeDependents.add(dropdown);
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
      Map<String, dynamic> parameters = HashMap();
      parameters["remark"] = remark;

      BenefitTransaction benefitRequest = BenefitTransaction(
        widget.benefitRequest != null ? widget.benefitRequest!.id : null,
        widget.benefitRequest != null ? widget.benefitRequest!.creator : null,
        widget.benefitRequest != null ? widget.benefitRequest!.creationTime : null,
        widget.benefitRequest != null ? widget.benefitRequest!.updater : null,
        widget.benefitRequest != null ? widget.benefitRequest!.updateTime : null,
        widget.benefitRequest != null ? widget.benefitRequest!.version : null,
        _customValues,
        Config.excludeOldAttachment(_medias),
        widget.benefitRequest != null ? widget.benefitRequest!.workflow : null,
        widget.benefitRequest != null ? widget.benefitRequest!.requestNo : null,
        workflowStatus,
        Config.user!.employee,
        Config.oldAttachment(_alternateAttachment, _medias),
        _remarkController.text,
        _assignee, 
        _assignment, 
        parameters,
        _workflowExecutors,
        _valPersonalRequest!,
        // Jika benefitRequest == null / create baru set nilai request date dengan tanggal hari ini
        // Jika  benefitRequest != null / edit data set nilai request date dengan nilai sebelumnya
        widget.benefitRequest != null ? widget.benefitRequest!.requestedDate : DateProvider.convertDate2Str(DateProvider.getCurrentDateMidnight(), "yyyy-MM-dd HH:mm:ss"),
        requestedAmount,
        approvedAmount,
        _valEmployeeDependent,
        benefitTransactionDetails,
      );

      if (widget.benefitRequest != null) {
        benefitsRequestRepository.update(id: widget.benefitRequest!.id!, entity: benefitRequest).then((value) {
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
      } else {
        benefitsRequestRepository.save(entity: benefitRequest).then((value) {
          EasyLoading.dismiss();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MessagePage(
                icon: const Icon(Icons.check_circle,
                    size: 100, color: Colors.green),
                title: "Success".tr(),
                subTitle: workflowStatus == WorkflowStatus.DRAFTED 
                  ? "Data has been saved".tr()
                  : "Data has been".tr(namedArgs: {"status": workflowStatus.toString().tr()}),
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
    }
  }

  _calculateApprovedAmount() {
    double requestedAmountTmp = 0;
    double approvedAmountTmp = 0;
    for (var benefitTransactionDetail in benefitTransactionDetails) {
      requestedAmountTmp += benefitTransactionDetail.requestedAmount;
      approvedAmountTmp += benefitTransactionDetail.approvedAmount ?? 0;
    }
    setState(() {
      requestedAmount = requestedAmountTmp;
      approvedAmount = approvedAmountTmp;
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
                      visible: Config.hasPermission("BenefitTransaction", "RequestForOther") || Config.isManager,
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
                            parameters.putIfAbsent("entity", () => "BenefitTransaction");
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
                          fieldName: "Personal Request".tr(),
                          value: _valPersonalRequest,
                          listItem: personalRequests,
                          onChanged: (val1) {
                            setState(() {
                              _valPersonalRequest = val1 as bool?;
                            });
                          },
                          validator: (val1) {
                            if (val1 == null) {
                              return "This field is required".tr();
                            }
                            return null;
                          }),
                    ),
                    Visibility(
                      visible: _valPersonalRequest == false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: InputForm().renderDropdownField(
                            fieldName: "Dependent".tr(),
                            value: _valEmployeeDependent,
                            listItem: employeeDependents,
                            onChanged: (val) {
                              setState(() {
                                _valEmployeeDependent = val as EmployeeDependent?;
                                _calculateApprovedAmount();
                              });
                            },
                            validator: (val) {
                              if (val == null) {
                                return "This field is required".tr();
                              }
                              return null;
                            }),
                      ),
                    ),
                    DetailPage(
                      itemList: benefitTransactionDetails,
                      title: "Application Detail".tr(),
                      onDelete: (index) {
                        setState(() {
                          benefitTransactionDetails.removeAt(index);
                        });
                        _calculateApprovedAmount();
                      },
                      onEdit: (val, index) {
                        List<BenefitTransactionDetail> tmp = [];
                        for (var i = 0; i < benefitTransactionDetails.length; i++) {
                          if(i != index) {
                            tmp.add(benefitTransactionDetails[i]);
                          }
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BenefitApplicationDetailPage(
                              benefitTransactionDetail: val,
                              benefitTransactionDetails: tmp,
                              employee: _assignment ? _assignee : Config.user!.employee,
                              employeeDependent: _valEmployeeDependent,
                            ),
                          ),
                        ).then((value) {
                          if(value == null) return;

                          setState(() {
                            benefitTransactionDetails[index] = value;
                          });
                          _calculateApprovedAmount();
                        });
                      },
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BenefitApplicationDetailPage(
                              benefitTransactionDetails: benefitTransactionDetails,
                              employee: _assignment ? _assignee : Config.user!.employee,
                              employeeDependent: _valEmployeeDependent,
                            ),
                          ),
                        ).then((value) {
                          if(value == null) return;

                          setState(() {
                            benefitTransactionDetails.add(value);
                          });
                          _calculateApprovedAmount();
                        });
                      },
                      renderTitle: (val, index) {
                        BenefitTransactionDetail detail = val;
                        return Text(detail.benefit!.name);
                      },
                      renderBody: (data, index) {
                        BenefitTransactionDetail detail = data;                  
                        return Container(
                          padding: const EdgeInsets.only(
                            left: 15,
                            right: 15,
                            bottom: 15,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 5.0),
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
                          Text(NumberProvider.decimalFormatDouble(requestedAmount),
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
                          Text(NumberProvider.decimalFormatDouble(approvedAmount),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
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
                        editMode: widget.benefitRequest != null ? true : false,
                      ),
                    ),
                    ApprovalHistoryPage(
                      approvalHistory: approvalHistories,
                      workflowExecutors: _workflowExecutors,
                      editable: true,
                      isExpand: _isExpand,
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
                      if(requestedAmount != approvedAmount) {
                        AlertProvider.showConfirmationDialog(
                          message: "${"Approved amount not the same with requested amount".tr()}\n${"Do you want to continue".tr()}?",
                        ).then((value) {
                          if(value == false) return;

                          showModalBottomSheet(
                            isScrollControlled: true,
                            context: context,
                            builder: (BuildContext bc) {
                              return ApprovalProcess(
                                workflowStatus: widget.benefitRequest != null
                                    ? widget.benefitRequest!.workflowStatus
                                    : null,
                                workflow: widget.benefitRequest != null
                                    ? widget.benefitRequest!.workflow
                                    : null,
                              );
                            },
                          ).then((value) {
                            if (value == null) return;

                            _submitForm(value['workflowStatus'], value['remark']);
                          });
                        });
                      } else {
                        showModalBottomSheet(
                          isScrollControlled: true,
                          context: context,
                          builder: (BuildContext bc) {
                            return ApprovalProcess(
                              workflowStatus: widget.benefitRequest != null
                                  ? widget.benefitRequest!.workflowStatus
                                  : null,
                              workflow: widget.benefitRequest != null
                                  ? widget.benefitRequest!.workflow
                                  : null,
                            );
                          },
                        ).then((value) {
                          if (value == null) return;

                          _submitForm(value['workflowStatus'], value['remark']);
                        });
                      }
                    }
                  }),
            ),
            const SizedBox(height: 10.0),
          ],
        ),
      ),
    );
  }
}
