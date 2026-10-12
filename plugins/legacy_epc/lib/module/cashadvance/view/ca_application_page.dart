// ignore_for_file: use_build_context_synchronously

import 'dart:collection';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/company/payment_method.dart';
import 'package:epeoplecare/model/custom_value.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/module/cashadvance/model/ca_policy.dart';
import 'package:epeoplecare/module/cashadvance/model/ca_request.dart';
import 'package:epeoplecare/module/cashadvance/model/ca_request_detail.dart';
import 'package:epeoplecare/module/cashadvance/repository/ca_policy_repository.dart';
import 'package:epeoplecare/module/cashadvance/repository/ca_request_repository.dart';
import 'package:epeoplecare/module/cashadvance/view/ca_application_detail_page.dart';
import 'package:epeoplecare/module/customfield/model/custom_field.dart';
import 'package:epeoplecare/module/customfield/model/custom_value.dart';
import 'package:epeoplecare/module/customfield/repository/custom_field_repository.dart';
import 'package:epeoplecare/module/customfield/view/custom_value_page.dart';
import 'package:epeoplecare/module/workflow/model/node.dart';
import 'package:epeoplecare/module/workflow/model/route_type.dart';
import 'package:epeoplecare/module/workflow/model/workflow_detail.dart';
import 'package:epeoplecare/module/workflow/model/workflow_executor.dart';
import 'package:epeoplecare/module/workflow/model/workflow_status.dart';
import 'package:epeoplecare/module/workflow/repository/node_repository.dart';
import 'package:epeoplecare/provider/alert_provider.dart';
import 'package:epeoplecare/provider/date_provider.dart';
import 'package:epeoplecare/provider/number_provider.dart';
import 'package:epeoplecare/repository/company/payment_method_repository.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/validation/validation.dart';
import 'package:epeoplecare/module/workflow/view/approval_history_page.dart';
import 'package:epeoplecare/module/workflow/view/approval_process.dart';
import 'package:epeoplecare/view/shared/detail_page.dart';
import 'package:epeoplecare/view/shared/input_form.dart';
import 'package:epeoplecare/view/shared/message.dart';
import 'package:epeoplecare/view/shared/model_picker.dart';
import 'package:epeoplecare/view/shared/multiple_attachment_page.dart';
import 'package:epeoplecare/view/shared/subordinate_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class CAApplicationPage extends StatefulWidget {
  final CARequest? caRequest;
  const CAApplicationPage({Key? key, this.caRequest}) : super(key: key);
  @override
  State<StatefulWidget> createState() => _CAApplicationPageState();
}

class _CAApplicationPageState extends State<CAApplicationPage> {
  final form = GlobalKey<FormState>();
  final _remarkController = TextEditingController();
  String? _alternateAttachment;
  List<WorkflowDetail> approvalHistories = [];
  final CARequestRepository _caRequestRepository = Repository().getCARequestRepository();
  List<CARequestDetail> caRequestDetail = [];
  final CustomFieldRepository _customFieldRepository = Repository().getCustomFieldRepository();
  List<CustomValue> _customValues = [];
  List<WorkflowExecutor> _workflowExecutors = [];
  final NodeRepository _nodeRepository = Repository().getNodeRepository();
  bool _isExpand = true;

  final CAPolicyRepository _caPolicyRepository = Repository().getCAPolicyRepository();
  final PaymentMethodRepository _paymentMethodRepository = Repository().getPaymentMethodRepository();
  final _policyController = TextEditingController();
  final _purposeController = TextEditingController();
  final _dateOfUseController = TextEditingController();
  final _paymentMethodController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankAccountNoController = TextEditingController();
  final _bankAccountNameController = TextEditingController();
  CAPolicy? _caPolicy;
  PaymentMethod? _paymentMethod;
  double _totalAmount = 0.0;
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
    if(widget.caRequest != null) {
      _caPolicy = widget.caRequest!.caPolicy;
      _policyController.text = _caPolicy!.name;
      _purposeController.text = widget.caRequest!.purpose ?? "";
      _dateOfUseController.text = DateProvider.convertDateStrFormat(widget.caRequest!.dateOfUse, "yyyy-MM-dd", "yyyy-MM-dd");
      _paymentMethod = widget.caRequest!.paymentMethod;
      _paymentMethodController.text = _paymentMethod!.name;
      _bankNameController.text = widget.caRequest!.bankName ?? "";
      _bankAccountNoController.text = widget.caRequest!.bankAccountNo ?? "";
      _bankAccountNameController.text = widget.caRequest!.bankAccountName ?? "";
      _remarkController.text = widget.caRequest!.description ?? "";
      _alternateAttachment = widget.caRequest!.attachment;
      for (CARequestDetail detail in widget.caRequest!.caRequestDetails) {
       caRequestDetail.add(detail) ;
      }
      _calculateTotalAmount();
      renderHistory(widget.caRequest!.workflow!.workflowDetails);
      _customValues = widget.caRequest!.customValues;
      _initWorkflowExecutor(widget.caRequest!.workflow!.workflowExecutors);
      _medias = widget.caRequest!.medias;
      _assignment = widget.caRequest!.assignment!;
      _assignee = widget.caRequest!.assignee;
      if(_assignee != null) {
        _assigneeController.text = "${_assignee!.code} ${_assignee!.name}";
      }
    } else {
      _initCustomField();
      _initWorkflowExecutor(null);
    }
  }

  _initCustomField() {
    _customFieldRepository.listByType("CARequest").then((items) {
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

    _nodeRepository.getOverrideNode(Config.user!.employee!, RouteType.CASH_ADVANCE).then((value) {
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

  _calculateTotalAmount() {
    double totalAmount = 0.0;
    for (var item in caRequestDetail) {
      totalAmount += item.amount;
    }

    setState(() {
      _totalAmount = totalAmount;
    });
  }

  _submitForm(WorkflowStatus workflowStatus, String remark) async {
    setState(() {
      _isExpand = true;
    });
    await Future.delayed(const Duration(milliseconds: 100));

    if (form.currentState!.validate()) {
      if(caRequestDetail.isEmpty) {
        AlertProvider.showAlertDialog(
          message: "Detail is required".tr(),
        );
        return;
      }
      EasyLoading.show(status: "Please Wait".tr());

      Map<String, dynamic> parameters = HashMap();
      parameters["remark"] = remark;
      CARequest caRequest = CARequest(
        widget.caRequest != null ? widget.caRequest!.id : null, 
        widget.caRequest != null ? widget.caRequest!.creator : null, 
        widget.caRequest != null ? widget.caRequest!.creationTime : null, 
        widget.caRequest != null ? widget.caRequest!.updater : null, 
        widget.caRequest != null ? widget.caRequest!.updateTime : null, 
        widget.caRequest != null ? widget.caRequest!.version : null, 
        _customValues, 
        Config.excludeOldAttachment(_medias),
        widget.caRequest != null ? widget.caRequest!.workflow : null,
        widget.caRequest != null ? widget.caRequest!.requestNo : null,
        workflowStatus,
        Config.user!.employee,
        Config.oldAttachment(_alternateAttachment, _medias),
        _remarkController.text,
        _assignee, 
        _assignment, 
        parameters,
        _workflowExecutors,
        _caPolicy,
        _purposeController.text,
        _dateOfUseController.text,
        0,
        _paymentMethod,
        _bankNameController.text,
        _bankAccountNoController.text,
        _bankAccountNameController.text,
        widget.caRequest != null ? widget.caRequest!.settled : false,
        caRequestDetail,
      );

      if(widget.caRequest != null) {
        _caRequestRepository.update(id: widget.caRequest!.id!, entity: caRequest).then((value) {
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
        _caRequestRepository.save(entity: caRequest).then((value) {
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
                      visible: Config.hasPermission("CARequest", "RequestForOther") || Config.isManager,
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
                            parameters.putIfAbsent("entity", () => "CARequest");
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
                        fieldName: "Policy".tr(),
                        controller: _policyController,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ModelPicker(
                                data: _caPolicy,
                                repository: _caPolicyRepository,
                                title: "Policy".tr(),
                              )
                            ),
                          ).then((value) {
                            if(value == null) return;

                            setState(() {
                              _caPolicy = value;
                              _policyController.text = _caPolicy!.name;
                              caRequestDetail.clear();
                            });
                          });
                        },
                        validator: Validation.validateField,
                      )
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: InputForm().renderTextField(
                        fieldName: "Purpose".tr(),
                        controller: _purposeController,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: InputForm().renderDateField(
                        fieldName: "Date Of Use".tr(),
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1990),
                        lastDate: DateTime(2101),
                        controller: _dateOfUseController,
                        validator: Validation.validateField,
                        onChanged: (value) {
                          if (value == null) return;

                          _dateOfUseController.text = DateProvider.convertDate2Str(value, "yyyy-MM-dd");
                        }
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: InputForm().renderCustomField(
                        fieldName: "Payment Method".tr(),
                        controller: _paymentMethodController,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ModelPicker(
                                data: _paymentMethod,
                                repository: _paymentMethodRepository,
                                title: "Payment Method".tr(),
                              )
                            ),
                          ).then((value) {
                            if(value == null) return;

                            setState(() {
                              _paymentMethod = value;
                              _paymentMethodController.text = _paymentMethod!.name;
                            });
                          });
                        },
                        validator: Validation.validateField,
                      )
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: InputForm().renderTextField(
                        fieldName: "Bank Name".tr(),
                        controller: _bankNameController,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: InputForm().renderTextField(
                        fieldName: "Bank Account No".tr(),
                        controller: _bankAccountNoController,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: InputForm().renderTextField(
                        fieldName: "Bank Account Name".tr(),
                        controller: _bankAccountNameController,
                      ),
                    ),
                    DetailPage(
                      itemList: caRequestDetail,
                      title: "Detail".tr(),
                      onDelete: (index) {
                        setState(() {
                          caRequestDetail.removeAt(index);
                        });
                        _calculateTotalAmount();
                      },
                      onEdit: (val, index) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CAApplicationDetailPage(
                              caRequestDetail: val,
                              caPolicy: _caPolicy,
                            ),
                          ),
                        ).then((value) {
                          if(value == null) return;

                          setState(() {
                            caRequestDetail[index] = value;
                          });
                          _calculateTotalAmount();
                        });
                      },
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CAApplicationDetailPage(
                              caPolicy: _caPolicy,
                            ),
                          ),
                        ).then((value) {
                          if(value == null) return;

                          setState(() {
                            caRequestDetail.add(value);
                          });
                          _calculateTotalAmount();
                        });
                      },
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
                          Text(NumberProvider.decimalFormatDouble(_totalAmount),
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
                        editMode: widget.caRequest != null ? true : false,
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
                    showModalBottomSheet(
                      isScrollControlled: true,
                      context: context,
                      builder: (BuildContext bc){
                        return ApprovalProcess(
                          workflowStatus: widget.caRequest != null ? widget.caRequest!.workflowStatus : null,
                          workflow: widget.caRequest != null ? widget.caRequest!.workflow : null,
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
