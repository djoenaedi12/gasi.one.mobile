// ignore_for_file: use_build_context_synchronously

import 'dart:collection';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/custom_value.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/module/attendance/model/attendance_correction.dart';
import 'package:epeoplecare/module/attendance/repository/attendance_correction_repository.dart';
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
import 'package:epeoplecare/view/shared/multiple_attachment_page.dart';
import 'package:epeoplecare/view/shared/subordinate_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class AttendanceCorrectionApplicationPage extends StatefulWidget {
  final AttendanceCorrection? attendanceCorrection;
  const AttendanceCorrectionApplicationPage({Key? key, this.attendanceCorrection}) : super(key: key);
  
  @override
  State<StatefulWidget>  createState() => _AttendanceCorrectionApplicationPageState();
}

class _AttendanceCorrectionApplicationPageState extends State<AttendanceCorrectionApplicationPage> {
  final form = GlobalKey<FormState>();
  final _attendanceDateController = TextEditingController();
  final _checkInController = TextEditingController();
  final _checkOutController = TextEditingController();
  final _remarkController = TextEditingController();
  String? _alternateAttachment;
  List<WorkflowDetail> approvalHistories = [];
  final AttendanceCorrectionRepository _attendanceCorrectionRepository = Repository().getAttendanceCorrectionRepository();
  DateTime _initialCheckIn= DateTime.now();
  DateTime _initialCheckOut = DateTime.now();
  final CustomFieldRepository _customFieldRepository = Repository().getCustomFieldRepository();
  List<CustomValue> _customValues = [];
  List<WorkflowExecutor> _workflowExecutors = [];
  final NodeRepository _nodeRepository = Repository().getNodeRepository();
  bool _isExpand = true;
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
    if(widget.attendanceCorrection != null) {
      _initialCheckIn = DateProvider.convertStr2Date(widget.attendanceCorrection!.checkIn, "yyyy-MM-dd HH:mm:ss")!;
      _initialCheckOut = DateProvider.convertStr2Date(widget.attendanceCorrection!.checkOut, "yyyy-MM-dd HH:mm:ss")!;
      _attendanceDateController.text = DateProvider.convertDateStrFormat(widget.attendanceCorrection!.attendanceDate, "yyyy-MM-dd", "yyyy-MM-dd");
      _checkInController.text = DateProvider.convertDateStrFormat(widget.attendanceCorrection!.checkIn, "yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd HH:mm");
      _checkOutController.text = DateProvider.convertDateStrFormat(widget.attendanceCorrection!.checkOut, "yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd HH:mm");
      _remarkController.text = widget.attendanceCorrection!.description ?? "";
      _alternateAttachment = widget.attendanceCorrection!.attachment ?? "";
      renderHistory(widget.attendanceCorrection!.workflow!.workflowDetails);
      _customValues = widget.attendanceCorrection!.customValues;
      _initWorkflowExecutor(widget.attendanceCorrection!.workflow!.workflowExecutors);
      _medias = widget.attendanceCorrection!.medias;
      _assignment = widget.attendanceCorrection!.assignment!;
      _assignee = widget.attendanceCorrection!.assignee;
      if(_assignee != null) {
        _assigneeController.text = "${_assignee!.code} ${_assignee!.name}";
      }
    } else {
      _initCustomField();
      _initWorkflowExecutor(null);
    }
  }

  _initCustomField() {
    _customFieldRepository.listByType("AttendanceCorrection").then((items) {
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

    _nodeRepository.getOverrideNode(Config.user!.employee!, RouteType.ATTENDANCE_CORRECTION).then((value) {
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

      AttendanceCorrection attendanceCorrection = AttendanceCorrection(
        widget.attendanceCorrection != null ? widget.attendanceCorrection!.id : null, 
        widget.attendanceCorrection != null ? widget.attendanceCorrection!.creator : null, 
        widget.attendanceCorrection != null ? widget.attendanceCorrection!.creationTime : null, 
        widget.attendanceCorrection != null ? widget.attendanceCorrection!.updater : null, 
        widget.attendanceCorrection != null ? widget.attendanceCorrection!.updateTime : null, 
        widget.attendanceCorrection != null ? widget.attendanceCorrection!.version : null, 
        _customValues, 
        Config.excludeOldAttachment(_medias),
        widget.attendanceCorrection != null ? widget.attendanceCorrection!.workflow : null,
        widget.attendanceCorrection != null ? widget.attendanceCorrection!.requestNo : null,
        workflowStatus,
        Config.user!.employee,
        Config.oldAttachment(_alternateAttachment, _medias),
        _remarkController.text,
        _assignee, 
        _assignment, 
        parameters,
        _workflowExecutors,
        DateProvider.convertDateStrFormat(_attendanceDateController.text, "yyyy-MM-dd", "yyyy-MM-dd"), 
        DateProvider.convertDateStrFormat(_checkInController.text, "yyyy-MM-dd HH:mm", "yyyy-MM-dd HH:mm:ss"), 
        DateProvider.convertDateStrFormat(_checkOutController.text, "yyyy-MM-dd HH:mm", "yyyy-MM-dd HH:mm:ss"), 
      );
      if(widget.attendanceCorrection != null) {
        _attendanceCorrectionRepository.update(id: widget.attendanceCorrection!.id ?? 0, entity: attendanceCorrection).then((value) {
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
        _attendanceCorrectionRepository.save(entity: attendanceCorrection).then((value) {
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

  _setInitialCheckIn() {
    if(_checkInController.text.isNotEmpty && _checkOutController.text.isNotEmpty) {
      DateTime checkIn = DateProvider.convertDateFormat(DateProvider.convertStr2Date(_checkInController.text, "yyyy-MM-dd HH:mm")!, "yyyy-MM-dd HH:mm", "yyyy-MM-dd")!;
      DateTime checkOut = DateProvider.convertDateFormat(DateProvider.convertStr2Date(_checkOutController.text, "yyyy-MM-dd HH:mm")!, "yyyy-MM-dd HH:mm", "yyyy-MM-dd")!;
      if(checkIn.compareTo(checkOut) > 0) {
          _initialCheckIn = checkOut;
      } else {
        _initialCheckIn = checkIn;
      }
    } else if(_checkOutController.text.isNotEmpty) {
      DateTime checkOut = DateProvider.convertDateFormat(DateProvider.convertStr2Date(_checkOutController.text, "yyyy-MM-dd HH:mm")!, "yyyy-MM-dd HH:mm", "yyyy-MM-dd")!;
      if(checkOut.compareTo(DateTime.now()) < 0) {
          _initialCheckIn = checkOut;
      }
    } else if (_checkInController.text.isNotEmpty) {
      DateTime checkIn = DateProvider.convertDateFormat(DateProvider.convertStr2Date(_checkInController.text, "yyyy-MM-dd HH:mm")!, "yyyy-MM-dd HH:mm", "yyyy-MM-dd")!;
      _initialCheckIn = checkIn;
    }
  }

  _setInitialCheckOut() {
    if(_checkInController.text.isNotEmpty && _checkOutController.text.isNotEmpty) {
      DateTime checkIn = DateProvider.convertDateFormat(DateProvider.convertStr2Date(_checkInController.text, "yyyy-MM-dd HH:mm")!, "yyyy-MM-dd HH:mm", "yyyy-MM-dd")!;
      DateTime checkOut = DateProvider.convertDateFormat(DateProvider.convertStr2Date(_checkOutController.text, "yyyy-MM-dd HH:mm")!, "yyyy-MM-dd HH:mm", "yyyy-MM-dd")!;
      if(checkIn.compareTo(checkOut) > 0) {
          _initialCheckOut = checkIn;
      } else {
        _initialCheckOut = checkOut;
      }
    } else if(_checkInController.text.isNotEmpty) {
      DateTime checkIn = DateProvider.convertDateFormat(DateProvider.convertStr2Date(_checkInController.text, "yyyy-MM-dd HH:mm")!, "yyyy-MM-dd HH:mm", "yyyy-MM-dd")!;
      if(checkIn.compareTo(DateTime.now()) > 0) {
          _initialCheckOut = checkIn;
      }
    } else if (_checkOutController.text.isNotEmpty) {
      DateTime checkOut = DateProvider.convertDateFormat(DateProvider.convertStr2Date(_checkOutController.text, "yyyy-MM-dd HH:mm")!, "yyyy-MM-dd HH:mm", "yyyy-MM-dd")!;
      _initialCheckOut = checkOut;
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
                      visible: Config.hasPermission("AttendanceCorrection", "RequestForOther") || Config.isManager,
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
                            parameters.putIfAbsent("entity", () => "AttendanceCorrection");
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
                        fieldName: "Date".tr(),
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1990),
                        lastDate: DateTime(2050),
                        controller: _attendanceDateController,
                        validator: Validation.validateField,
                        onChanged: (value) {
                          if (value == null) return;

                          _attendanceDateController.text = DateProvider.convertDate2Str(value, "yyyy-MM-dd");
                        }
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: InputForm().renderDateTimeField(
                        fieldName: "Check In".tr(),
                        initialDate: _initialCheckIn,
                        firstDate: DateTime(1990),
                        lastDate: _checkOutController.text.isNotEmpty
                                  ? DateProvider.convertStr2Date(_checkOutController.text, "yyyy-MM-dd HH:mm")!
                                  : DateTime(2050),
                        controller: _checkInController,
                        validator: Validation.validateField,
                        onChanged: (value) {
                          if (value == null) return;

                          _checkInController.text = DateProvider.convertDate2Str(value, "yyyy-MM-dd HH:mm");
                          setState(() {
                            _setInitialCheckIn();
                          });
                        }
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: InputForm().renderDateTimeField(
                        fieldName: "Check Out".tr(),
                        initialDate: _initialCheckOut,
                        firstDate: _checkInController.text.isNotEmpty 
                                  ? DateProvider.convertStr2Date(_checkInController.text, "yyyy-MM-dd HH:mm")!
                                  : DateTime(1990),
                        lastDate: DateTime(2050),
                        controller: _checkOutController,
                        validator: (val) {
                          if(val == null || val.isEmpty) {
                            return "This field is required".tr();
                          }
                          if(val.isNotEmpty && _checkInController.text.isNotEmpty) {
                            var checkIn = DateProvider.convertStr2Date(_checkInController.text, "yyyy-MM-dd HH:mm");
                            var checkOut = DateProvider.convertStr2Date(val, "yyyy-MM-dd HH:mm");
                            if(!checkIn!.isBefore(checkOut!)) {
                              return "End time must be greater than Start time".tr();
                            }
                          }
                          return null;
                        },
                        onChanged: (value) {
                          if (value == null) return;

                          _checkOutController.text = DateProvider.convertDate2Str(value, "yyyy-MM-dd HH:mm");
                          setState(() {
                            _setInitialCheckOut();
                          });
                        }
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
                        editMode: widget.attendanceCorrection != null ? true : false,
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
                          workflowStatus: widget.attendanceCorrection != null ? widget.attendanceCorrection!.workflowStatus : null,
                          workflow: widget.attendanceCorrection != null ? widget.attendanceCorrection!.workflow : null,
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
