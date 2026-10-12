// ignore_for_file: use_build_context_synchronously

import 'dart:collection';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/custom_value.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/module/customfield/model/custom_field.dart';
import 'package:epeoplecare/module/customfield/model/custom_value.dart';
import 'package:epeoplecare/module/customfield/repository/custom_field_repository.dart';
import 'package:epeoplecare/module/customfield/view/custom_value_page.dart';
import 'package:epeoplecare/module/overtime/model/overtime_transaction.dart';
import 'package:epeoplecare/module/overtime/model/overtime_transaction_detail.dart';
import 'package:epeoplecare/module/overtime/view/overtime/overtime_application_detail_page.dart';
import 'package:epeoplecare/module/workflow/model/node.dart';
import 'package:epeoplecare/module/workflow/model/route_type.dart';
import 'package:epeoplecare/module/workflow/model/workflow_detail.dart';
import 'package:epeoplecare/module/workflow/model/workflow_executor.dart';
import 'package:epeoplecare/module/workflow/model/workflow_status.dart';
import 'package:epeoplecare/module/workflow/repository/node_repository.dart';
import 'package:epeoplecare/provider/date_provider.dart';
import 'package:epeoplecare/module/overtime/repository/overtime_transaction_repository.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/validation/validation.dart';
import 'package:epeoplecare/module/workflow/view/approval_history_page.dart';
import 'package:epeoplecare/module/workflow/view/approval_process.dart';
import 'package:epeoplecare/view/shared/detail_page.dart';
import 'package:epeoplecare/view/shared/input_form.dart';
import 'package:epeoplecare/view/shared/message.dart';
import 'package:epeoplecare/view/shared/multiple_attachment_page.dart';
import 'package:epeoplecare/view/shared/subordinate_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class OvertimeApplicationPage extends StatefulWidget {
  final OvertimeTransaction? overtimeTransaction;
  const OvertimeApplicationPage({Key? key, this.overtimeTransaction}): super(key: key);
  
  @override
  State<StatefulWidget> createState() => _OvertimeApplicationPageState();
}

class _OvertimeApplicationPageState extends State<OvertimeApplicationPage> {
  final form = GlobalKey<FormState>();
  final _assignmentController = TextEditingController();
  final _assigneeController = TextEditingController();
  final _remarkController = TextEditingController();
  String? _alternateAttachment;
  List<WorkflowDetail> approvalHistories = [];
  final OvertimeTransactionRepository _overtimeTransactionRepository = Repository().getOvertimeTransactionRepository();
  final CustomFieldRepository _customFieldRepository = Repository().getCustomFieldRepository();
  List<CustomValue> _customValues = [];
  bool _assignment = false;
  Employee? _assignee;
  List<WorkflowExecutor> _workflowExecutors = [];
  final NodeRepository _nodeRepository = Repository().getNodeRepository();
  bool _isExpand = true;
  List<OvertimeTransactionDetail> _overtimeTransactionDetail = [];
  List<Media> _medias = [];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  _initData() {
    if(widget.overtimeTransaction != null) {
      _remarkController.text = widget.overtimeTransaction!.description ?? "";
      _alternateAttachment = widget.overtimeTransaction!.attachment;
      renderHistory(widget.overtimeTransaction!.workflow!.workflowDetails);
      _customValues = widget.overtimeTransaction!.customValues;
      _assignment = widget.overtimeTransaction!.assignment ?? false;
      _assignee = widget.overtimeTransaction!.assignee;
      if(_assignee != null) {
        _assigneeController.text = "${_assignee!.code} ${_assignee!.name}";
      }
      _initWorkflowExecutor(widget.overtimeTransaction!.workflow!.workflowExecutors);
      _overtimeTransactionDetail = widget.overtimeTransaction!.overtimeTransactionDetails;
      _medias = widget.overtimeTransaction!.medias;
    } else {
      _initCustomField();
      _initWorkflowExecutor(null);
    }
  }

  _initCustomField() {
    _customFieldRepository.listByType("OvertimeTransaction").then((items) {
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

    _nodeRepository.getOverrideNode(Config.user!.employee!, RouteType.OVERTIME).then((value) {
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
      String startDate = "";
      String endDate = "";
      double duration = 0.0;
      
      for (OvertimeTransactionDetail overtimeTransactionDetail in _overtimeTransactionDetail) {
        if(startDate == "" || DateProvider.convertStr2Date(startDate, "yyyy-MM-dd HH:mm:ss")!.isAfter(DateProvider.convertStr2Date(overtimeTransactionDetail.startDate, "yyyy-MM-dd HH:mm:ss")!)) {
          startDate = overtimeTransactionDetail.startDate;
        }
        if(endDate == "" || DateProvider.convertStr2Date(endDate, "yyyy-MM-dd HH:mm:ss")!.isBefore(DateProvider.convertStr2Date(overtimeTransactionDetail.endDate, "yyyy-MM-dd HH:mm:ss")!)) {
          endDate = overtimeTransactionDetail.startDate;
        }
        duration += overtimeTransactionDetail.duration;
      }

      OvertimeTransaction overtimeTransaction = OvertimeTransaction(
        widget.overtimeTransaction != null ? widget.overtimeTransaction!.id : null, 
        widget.overtimeTransaction != null ? widget.overtimeTransaction!.creator : null, 
        widget.overtimeTransaction != null ? widget.overtimeTransaction!.creationTime : null, 
        widget.overtimeTransaction != null ? widget.overtimeTransaction!.updater : null, 
        widget.overtimeTransaction != null ? widget.overtimeTransaction!.updateTime : null, 
        widget.overtimeTransaction != null ? widget.overtimeTransaction!.version : null, 
        _customValues, 
        Config.excludeOldAttachment(_medias),
        widget.overtimeTransaction != null ? widget.overtimeTransaction!.workflow : null,
        widget.overtimeTransaction != null ? widget.overtimeTransaction!.requestNo : null,
        workflowStatus,
        Config.user!.employee,
        Config.oldAttachment(_alternateAttachment, _medias),
        _remarkController.text,
        _assignee, 
        _assignment, 
        parameters, 
        _workflowExecutors, 
        startDate,
        endDate,
        duration,
        _overtimeTransactionDetail,
      );
      if(widget.overtimeTransaction != null) {
        _overtimeTransactionRepository.update(id: widget.overtimeTransaction!.id!, entity: overtimeTransaction).then((value) {
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
                subTitle: onError.toString().tr(),
              ),
            ),
          );
        });
      } else {
        _overtimeTransactionRepository.save(entity: overtimeTransaction).then((value) {
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
                      visible: Config.hasPermission("OvertimeTransaction", "RequestForOther") || Config.isManager,
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
                            parameters.putIfAbsent("entity", () => "OvertimeTransaction");
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
                    DetailPage(
                      itemList: _overtimeTransactionDetail,
                      title: "Application Detail".tr(),
                      onDelete: (index) {
                        setState(() {
                          _overtimeTransactionDetail.removeAt(index);
                        });
                      },
                      onEdit: (val, index) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OvertimeApplicationDetailPage(
                              overtimeTransactionDetail: val,
                            ),
                          ),
                        ).then((value) {
                          if(value == null) return;

                          setState(() {
                            _overtimeTransactionDetail[index] = value;
                          });
                        });
                      },
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const OvertimeApplicationDetailPage(),
                          ),
                        ).then((value) {
                          if(value == null) return;

                          setState(() {
                            _overtimeTransactionDetail.add(value);
                          });
                        });
                      },
                      renderTitle: (val, index) {
                        OvertimeTransactionDetail detail = val;
                        return Text(
                          "${DateProvider.convertDateStrFormat(detail.startDate, "yyyy-MM-dd HH:mm:ss", "dd MMMM yyyy")} - ${DateProvider.convertDateStrFormat(detail.endDate, "yyyy-MM-dd HH:mm:ss", "dd MMMM yyyy")}"
                        );
                      },
                      renderBody: (data, index) {
                        OvertimeTransactionDetail detail = data;                  
                        return Container(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "${"Date From".tr()}: ",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(DateProvider.convertDateStrFormat(detail.startDate, "yyyy-MM-dd HH:mm:ss", "dd MMMM yyyy HH:mm")),
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
                                  Text(DateProvider.convertDateStrFormat(detail.endDate, "yyyy-MM-dd HH:mm:ss", "dd MMMM yyyy HH:mm")),
                                ],
                              ),
                              const SizedBox(height: 5.0),
                              Row(
                                children: [
                                  Text(
                                    "${"Duration".tr()}: ",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text("${detail.duration} ${"Hours".tr()}"),
                                ],
                              ),
                              const SizedBox(height: 5.0),
                              Row(
                                children: [
                                  Text(
                                    "${"Break Duration".tr()}: ",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text("${detail.breakDuration} ${"Hours".tr()}"),
                                ],
                              ),
                              const SizedBox(height: 5.0),
                              Row(
                                children: [
                                  Text(
                                    "${"Total Duration".tr()}: ",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text("${detail.duration - detail.breakDuration!} ${"Hours".tr()}"),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
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
                        editMode: widget.overtimeTransaction != null ? true : false,
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
                          workflowStatus: widget.overtimeTransaction != null ? widget.overtimeTransaction!.workflowStatus : null,
                          workflow: widget.overtimeTransaction != null ? widget.overtimeTransaction!.workflow : null,
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
