// ignore_for_file: use_build_context_synchronously

import 'dart:collection';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/custom_value.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/module/cashadvance/model/ca_request.dart';
import 'package:epeoplecare/module/cashadvance/model/ca_request_detail.dart';
import 'package:epeoplecare/module/cashadvance/model/ca_settlement.dart';
import 'package:epeoplecare/module/cashadvance/model/ca_settlement_detail.dart';
import 'package:epeoplecare/module/cashadvance/repository/ca_request_repository.dart';
import 'package:epeoplecare/module/cashadvance/repository/ca_settlement_repository.dart';
import 'package:epeoplecare/module/cashadvance/view/settlement/ca_settlement_application_detail_page.dart';
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
import 'package:epeoplecare/provider/enum_provider.dart';
import 'package:epeoplecare/provider/number_provider.dart';
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

class CASettlementApplicationPage extends StatefulWidget {
  final CASettlement? caSettlement;
  final CARequest? caRequest;
  const CASettlementApplicationPage({Key? key, this.caSettlement, this.caRequest}) : super(key: key);
  @override
  State<StatefulWidget> createState() => _CASettlementApplicationPageState();
}

class _CASettlementApplicationPageState extends State<CASettlementApplicationPage> {
  final form = GlobalKey<FormState>();
  final _remarkController = TextEditingController();
  String? _alternateAttachment;
  List<WorkflowDetail> approvalHistories = [];
  final CASettlementRepository _caSettlementRepository = Repository().getCASettlementRepository();
  List<CASettlementDetail> caSettlementDetail = [];
  final CustomFieldRepository _customFieldRepository = Repository().getCustomFieldRepository();
  List<CustomValue> _customValues = [];
  List<WorkflowExecutor> _workflowExecutors = [];
  final NodeRepository _nodeRepository = Repository().getNodeRepository();
  bool _isExpand = true;

  final CARequestRepository _caRequestRepository = Repository().getCARequestRepository();
  final _caRequestController = TextEditingController();
  CARequest? _caRequest;
  double _totalAmount = 0.0;
  double _totalSettlementAmount = 0.0;
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
    if(widget.caSettlement != null) {
      _caRequest = widget.caSettlement!.caRequest;
      _caRequestController.text = _caRequest!.requestNo ?? "";
      _remarkController.text = widget.caSettlement!.description ?? "";
      _alternateAttachment = widget.caSettlement!.attachment;
      for (CASettlementDetail detail in widget.caSettlement!.caSettlementDetails) {
       caSettlementDetail.add(detail) ;
      }
      renderHistory(widget.caSettlement!.workflow!.workflowDetails);
      _customValues = widget.caSettlement!.customValues;
      _initWorkflowExecutor(widget.caSettlement!.workflow!.workflowExecutors);
      _medias = widget.caSettlement!.medias;
      _assignment = widget.caSettlement!.assignment!;
      _assignee = widget.caSettlement!.assignee;
      if(_assignee != null) {
        _assigneeController.text = "${_assignee!.code} ${_assignee!.name}";
      }
    } else {
      if(widget.caRequest != null) {
        _caRequest = widget.caRequest;
        _caRequestController.text = _caRequest!.requestNo ?? "";
        for (CARequestDetail detail in _caRequest!.caRequestDetails) {
          CASettlementDetail detailSettlement = CASettlementDetail(
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            detail,
            "",
            detail.amount,
          );
          caSettlementDetail.add(detailSettlement);
        }
      }
      _initCustomField();
      _initWorkflowExecutor(null);
    }
    _calculateTotalAmount();
  }

  _initCustomField() {
    _customFieldRepository.listByType("CASettlement").then((items) {
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

    _nodeRepository.getOverrideNode(Config.user!.employee!, RouteType.CASH_ADVANCE_SETTLEMENT).then((value) {
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
    double totalSettlementAmount = 0.0;
    for (var item in caSettlementDetail) {
      totalAmount += item.caRequestDetail!.amount;
      totalSettlementAmount += item.amount;
    }

    setState(() {
      _totalAmount = totalAmount;
      _totalSettlementAmount = totalSettlementAmount;
    });
  }

  _submitForm(WorkflowStatus workflowStatus, String remark) async {
    setState(() {
      _isExpand = true;
    });
    await Future.delayed(const Duration(milliseconds: 100));

    if (form.currentState!.validate()) {
      if(caSettlementDetail.isEmpty) {
        AlertProvider.showAlertDialog(
          message: "Detail is required".tr(),
        );
        return;
      }
      EasyLoading.show(status: "Please Wait".tr());

      Map<String, dynamic> parameters = HashMap();
      parameters["remark"] = remark;
      CASettlement caSettlement = CASettlement(
        widget.caSettlement != null ? widget.caSettlement!.id : null, 
        widget.caSettlement != null ? widget.caSettlement!.creator : null, 
        widget.caSettlement != null ? widget.caSettlement!.creationTime : null, 
        widget.caSettlement != null ? widget.caSettlement!.updater : null, 
        widget.caSettlement != null ? widget.caSettlement!.updateTime : null, 
        widget.caSettlement != null ? widget.caSettlement!.version : null, 
        _customValues, 
        Config.excludeOldAttachment(_medias),
        widget.caSettlement != null ? widget.caSettlement!.workflow : null,
        widget.caSettlement != null ? widget.caSettlement!.requestNo : null,
        workflowStatus,
        Config.user!.employee,
        Config.oldAttachment(_alternateAttachment, _medias),
        _remarkController.text,
        _assignee, 
        _assignment, 
        parameters,
        _workflowExecutors,
        _caRequest,
        0,
        caSettlementDetail,
      );

      if(widget.caSettlement != null) {
        _caSettlementRepository.update(id: widget.caSettlement!.id!, entity: caSettlement).then((value) {
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
        _caSettlementRepository.save(entity: caSettlement).then((value) {
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
          "Settlement Application".tr(),
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
                      visible: Config.hasPermission("CASettlement", "RequestForOther") || Config.isManager,
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
                            parameters.putIfAbsent("entity", () => "CASettlement");
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
                        fieldName: "Cash Advance Request".tr(),
                        controller: _caRequestController,
                        onTap: () {
                          Map<String, dynamic> parameters = HashMap();
                          parameters["settled"] = false;
                          parameters["workflowStatus"] = EnumProvider.convertToString(WorkflowStatus.APPROVED);
                          parameters["employee"] = _assignment && _assignee != null ? _assignee!.id : Config.user!.employee!.id;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ModelPicker(
                                paramaters: parameters,
                                data: _caRequest,
                                repository: _caRequestRepository,
                                title: "Cash Advance Request".tr(),
                                onFieldSubmitted: (paramaters, val) {
                                  paramaters["requestNo.like"] = val;
                                },
                                itemBuilder: (wData, data) {
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "${data.requestNo}",
                                          style: const TextStyle(
                                            fontSize: 16.0,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.check,
                                        color: wData != null && wData.id == data.id ? Config.DEFAULT_COLOR : Colors.white,
                                      )
                                    ],
                                  );
                                },
                              )
                            ),
                          ).then((value) {
                            if(value == null) return;

                            setState(() {
                              _caRequest = value;
                              _caRequestController.text = _caRequest!.requestNo ?? "";
                              caSettlementDetail.clear();

                              for (CARequestDetail detail in _caRequest!.caRequestDetails) {
                                CASettlementDetail detailSettlement = CASettlementDetail(
                                  null,
                                  null,
                                  null,
                                  null,
                                  null,
                                  null,
                                  null,
                                  null,
                                  null,
                                  detail,
                                  "",
                                  detail.amount,
                                );
                                setState(() {
                                  caSettlementDetail.add(detailSettlement);                                  
                                });
                              }
                            });
                            _calculateTotalAmount();
                          });
                        },
                        validator: Validation.validateField,
                      )
                    ),
                    DetailPage(
                      canAdd: false,
                      canDelete: false,
                      itemList: caSettlementDetail,
                      title: "Detail".tr(),
                      onEdit: (val, index) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CASettlementApplicationDetailPage(
                              caSettlementDetail: val,
                            ),
                          ),
                        ).then((value) {
                          if(value == null) return;

                          setState(() {
                            caSettlementDetail[index] = value;
                          });
                          _calculateTotalAmount();
                        });
                      },
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
                          Text(NumberProvider.decimalFormatDouble(_totalAmount),
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
                          Text("Total Settlement Amount".tr(),
                            style: const TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                          Text(NumberProvider.decimalFormatDouble(_totalSettlementAmount),
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
                          Text("Variance".tr(),
                            style: const TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                          Text(NumberProvider.decimalFormatDouble(_totalAmount - _totalSettlementAmount),
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
                        editMode: widget.caSettlement != null ? true : false,
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
                          workflowStatus: widget.caSettlement != null ? widget.caSettlement!.workflowStatus : null,
                          workflow: widget.caSettlement != null ? widget.caSettlement!.workflow : null,
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
