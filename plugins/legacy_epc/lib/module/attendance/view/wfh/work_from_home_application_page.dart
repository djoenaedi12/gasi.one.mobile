// ignore_for_file: use_build_context_synchronously

import 'dart:collection';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/company/working_location.dart';
import 'package:epeoplecare/model/custom_value.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/module/attendance/model/work_from_home.dart';
import 'package:epeoplecare/module/attendance/repository/work_from_home_repository.dart';
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
import 'package:epeoplecare/provider/date_provider.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/validation/validation.dart';
import 'package:epeoplecare/module/workflow/view/approval_history_page.dart';
import 'package:epeoplecare/module/workflow/view/approval_process.dart';
import 'package:epeoplecare/view/shared/input_form.dart';
import 'package:epeoplecare/view/shared/message.dart';
import 'package:epeoplecare/view/shared/model_picker.dart';
import 'package:epeoplecare/view/shared/multiple_attachment_page.dart';
import 'package:epeoplecare/view/shared/subordinate_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class WorkFromHomeApplicationPage extends StatefulWidget {
  final WorkFromHome? workFromHome;
  const WorkFromHomeApplicationPage({Key? key, this.workFromHome}) : super(key: key);
  @override
  State<StatefulWidget>  createState() => _WorkFromHomeApplicationPageState();
}

class _WorkFromHomeApplicationPageState extends State<WorkFromHomeApplicationPage> {
  final form = GlobalKey<FormState>();
  final _assignmentController = TextEditingController();
  final _assigneeController = TextEditingController();
  final _dateFromController = TextEditingController();
  final _dateToController = TextEditingController();
  final _locationController = TextEditingController();
  final _remarkController = TextEditingController();
  final _durationController = TextEditingController();
  String? _alternateAttachment;
  List<WorkflowDetail> approvalHistories = [];
  final WorkFromHomeRepository _workFromHomeRepository = Repository().getWorkFromHomeRepository();
  DateTime _initialDateFrom= DateTime.now();
  DateTime _initialDateTo = DateTime.now();
  final CustomFieldRepository _customFieldRepository = Repository().getCustomFieldRepository();
  List<CustomValue> _customValues = [];
  bool _assignment = false;
  Employee? _assignee;
  List<WorkflowExecutor> _workflowExecutors = [];
  final NodeRepository _nodeRepository = Repository().getNodeRepository();
  bool _isExpand = true;
  List<Media> _medias = [];
  final _workingLocationController = TextEditingController();
  WorkingLocation? _workingLocation;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  _initData() {
    if(widget.workFromHome != null) {
      _initialDateFrom = DateProvider.convertStr2Date(widget.workFromHome!.dateFrom, "yyyy-MM-dd")!;
      _initialDateTo = DateProvider.convertStr2Date(widget.workFromHome!.dateTo, "yyyy-MM-dd")!;
      _dateFromController.text = DateProvider.convertDateStrFormat(widget.workFromHome!.dateFrom, "yyyy-MM-dd", "yyyy-MM-dd");
      _dateToController.text = DateProvider.convertDateStrFormat(widget.workFromHome!.dateTo, "yyyy-MM-dd", "yyyy-MM-dd");
      _remarkController.text = widget.workFromHome!.description ?? "";
      _alternateAttachment = widget.workFromHome!.attachment;
      _locationController.text = widget.workFromHome!.locationStr ?? "";
      _durationController.text = widget.workFromHome!.duration.toString();
      renderHistory(widget.workFromHome!.workflow!.workflowDetails);
      _customValues = widget.workFromHome!.customValues;
      _assignment = widget.workFromHome!.assignment!;
      _assignee = widget.workFromHome!.assignee;
      if(_assignee != null) {
        _assigneeController.text = "${_assignee!.code} ${_assignee!.name}";
      }
      _initWorkflowExecutor(widget.workFromHome!.workflow!.workflowExecutors);
      _medias = widget.workFromHome!.medias;
      _workingLocation = widget.workFromHome!.workingLocation;
      if(_workingLocation != null) {
        _workingLocationController.text = _workingLocation!.name;
      }
    } else {
      _initCustomField();
      _initWorkflowExecutor(null);
    }
  }

  _initCustomField() {
    _customFieldRepository.listByType("WorkFromHome").then((items) {
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

    _nodeRepository.getOverrideNode(Config.user!.employee!, RouteType.WORK_FROM_HOME).then((value) {
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

  _calculateDuration() {
    if(_dateFromController.text != "" && _dateToController.text != "") {
      Employee? employee = Config.user!.employee;
      if(_assignment == true && _assignee != null) {
        employee = _assignee;
      }

      DateTime dateFrom = DateProvider.convertStr2Date(_dateFromController.text, "yyyy-MM-dd")!;
      DateTime dateTo = DateProvider.convertStr2Date(_dateToController.text, "yyyy-MM-dd")!;
      _workFromHomeRepository.getDuration(employee!, dateFrom, dateTo).then((value) {
        _durationController.text = value.toString();
      });
    }
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

      WorkFromHome workFromHome = WorkFromHome(
        widget.workFromHome != null ? widget.workFromHome!.id : null, 
        widget.workFromHome != null ? widget.workFromHome!.creator : null, 
        widget.workFromHome != null ? widget.workFromHome!.creationTime : null, 
        widget.workFromHome != null ? widget.workFromHome!.updater : null, 
        widget.workFromHome != null ? widget.workFromHome!.updateTime : null, 
        widget.workFromHome != null ? widget.workFromHome!.version : null, 
        _customValues, 
        Config.excludeOldAttachment(_medias),
        widget.workFromHome != null ? widget.workFromHome!.workflow : null,
        widget.workFromHome != null ? widget.workFromHome!.requestNo : null,
        workflowStatus,
        Config.user!.employee,
        Config.oldAttachment(_alternateAttachment, _medias),
        _remarkController.text,
        _assignee, 
        _assignment, 
        parameters,
        _workflowExecutors,          
        DateProvider.convertDateStrFormat(_dateFromController.text, "yyyy-MM-dd", "yyyy-MM-dd"), 
        DateProvider.convertDateStrFormat(_dateToController.text, "yyyy-MM-dd", "yyyy-MM-dd"), 
        "" ,
        _locationController.text,
        double.parse(_durationController.text),
        _workingLocation,
      );
      if(widget.workFromHome != null) {
        _workFromHomeRepository.update(id: widget.workFromHome!.id!, entity: workFromHome).then((value) {
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
        _workFromHomeRepository.save(entity: workFromHome).then((value) {
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

  _setInitialDateFrom() {
    if(_dateFromController.text.isNotEmpty && _dateToController.text.isNotEmpty) {
      DateTime dateFrom = DateProvider.convertDateFormat(DateProvider.convertStr2Date(_dateFromController.text, "yyyy-MM-dd")!, "yyyy-MM-dd", "yyyy-MM-dd")!;
      DateTime dateTo = DateProvider.convertDateFormat(DateProvider.convertStr2Date(_dateToController.text, "yyyy-MM-dd")!, "yyyy-MM-dd", "yyyy-MM-dd")!;
      if(dateFrom.compareTo(dateTo) > 0) {
          _initialDateFrom = dateTo;
      } else {
        _initialDateFrom = dateFrom;
      }
    } else if(_dateToController.text.isNotEmpty) {
      DateTime dateTo = DateProvider.convertDateFormat(DateProvider.convertStr2Date(_dateToController.text, "yyyy-MM-dd")!, "yyyy-MM-dd", "yyyy-MM-dd")!;
      if(dateTo.compareTo(DateTime.now()) < 0) {
          _initialDateFrom = dateTo;
      }
    } else if (_dateFromController.text.isNotEmpty) {
      DateTime dateFrom = DateProvider.convertDateFormat(DateProvider.convertStr2Date(_dateFromController.text, "yyyy-MM-dd")!, "yyyy-MM-dd", "yyyy-MM-dd")!;
      _initialDateFrom = dateFrom;
    }
  }

  _setInitialDateTo() {
    if(_dateFromController.text.isNotEmpty && _dateToController.text.isNotEmpty) {
      DateTime dateFrom = DateProvider.convertDateFormat(DateProvider.convertStr2Date(_dateFromController.text, "yyyy-MM-dd")!, "yyyy-MM-dd", "yyyy-MM-dd")!;
      DateTime dateTo = DateProvider.convertDateFormat(DateProvider.convertStr2Date(_dateToController.text, "yyyy-MM-dd")!, "yyyy-MM-dd", "yyyy-MM-dd")!;
      if(dateFrom.compareTo(dateTo) > 0) {
          _initialDateTo = dateFrom;
      } else {
        _initialDateTo = dateTo;
      }
    } else if(_dateFromController.text.isNotEmpty) {
      DateTime dateFrom = DateProvider.convertDateFormat(DateProvider.convertStr2Date(_dateFromController.text, "yyyy-MM-dd")!, "yyyy-MM-dd", "yyyy-MM-dd")!;
      if(dateFrom.compareTo(DateTime.now()) > 0) {
          _initialDateTo = dateFrom;
      }
    } else if (_dateToController.text.isNotEmpty) {
      DateTime dateTo = DateProvider.convertDateFormat(DateProvider.convertStr2Date(_dateToController.text, "yyyy-MM-dd")!, "yyyy-MM-dd", "yyyy-MM-dd")!;
      _initialDateTo = dateTo;
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
                      visible: Config.hasPermission("WorkFromHome", "RequestForOther") || Config.isManager,
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
                            parameters.putIfAbsent("entity", () => "WorkFromHome");
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
                      child: InputForm().renderDateField(
                        fieldName: "Date From",
                        initialDate: _initialDateFrom,
                        firstDate: DateTime(1990),
                        lastDate: _dateToController.text.isNotEmpty
                                  ? DateProvider.convertStr2Date(_dateToController.text, "yyyy-MM-dd")!
                                  : DateTime(2050),
                        controller: _dateFromController,
                        validator: Validation.validateField,
                        onChanged: (value) {
                          if (value == null) return;

                          _dateFromController.text = DateProvider.convertDate2Str(value, "yyyy-MM-dd");
                          _calculateDuration();
                          setState(() {
                            _setInitialDateFrom();
                          });
                        }
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: InputForm().renderDateField(
                        fieldName: "Date To".tr(),
                        initialDate: _initialDateTo,
                        firstDate: _dateFromController.text.isNotEmpty 
                                  ? DateProvider.convertStr2Date(_dateFromController.text, "yyyy-MM-dd")! 
                                  : DateTime(1990),
                        lastDate: DateTime(2050),
                        controller: _dateToController,
                        validator: (val) {
                          if(val == null || val.isEmpty) {
                            return "This field is required".tr();
                          }
                          if(val.isNotEmpty && _dateFromController.text.isNotEmpty) {
                            var dateFrom = DateProvider.convertStr2Date(_dateFromController.text, "yyyy-MM-dd");
                            var dateTo = DateProvider.convertStr2Date(val, "yyyy-MM-dd");
                            if(dateTo!.isBefore(dateFrom!)) {
                              return "End time must be greater than Start time".tr();
                            }
                          }
                          return null;
                        },
                        onChanged: (value) {
                          if (value == null) return;

                          _dateToController.text = DateProvider.convertDate2Str(value, "yyyy-MM-dd");
                          _calculateDuration();
                          setState(() {
                            _setInitialDateTo();
                          });
                        }
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: InputForm().renderTextField(
                        fieldName: "Duration".tr(),
                        controller: _durationController,
                        validator: Validation.validateField,
                        enabled: false,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: InputForm().renderCustomField(
                        controller: _workingLocationController,
                        fieldName: "Working Location".tr(),
                        validator: Validation.validateField,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ModelPicker(
                                data: _workingLocation,
                                repository: Repository().getWorkingLocationRepository(),
                                title: "Working Location".tr(),
                              )
                            ),
                          ).then((value) {
                            if(value == null) return;

                            setState(() {
                              _workingLocation = value;
                              _workingLocationController.text = _workingLocation!.name;
                            });
                          });
                        }
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: InputForm().renderTextField(
                        fieldName: "Location".tr(),
                        controller: _locationController,
                        maxLines: 5,
                        maxLength: 100,
                        textInputType: TextInputType.multiline,
                        validator: Validation.validateField,
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
                        editMode: widget.workFromHome != null ? true : false,
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
                          workflowStatus: widget.workFromHome != null ? widget.workFromHome!.workflowStatus : null,
                          workflow: widget.workFromHome != null ? widget.workFromHome!.workflow : null,
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
