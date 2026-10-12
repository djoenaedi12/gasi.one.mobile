// ignore_for_file: use_build_context_synchronously

import 'dart:collection';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/company/public_holiday.dart';
import 'package:epeoplecare/model/custom_value.dart';
import 'package:epeoplecare/model/dropdown.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/module/customfield/model/custom_field.dart';
import 'package:epeoplecare/module/customfield/model/custom_value.dart';
import 'package:epeoplecare/module/customfield/repository/custom_field_repository.dart';
import 'package:epeoplecare/module/customfield/view/custom_value_page.dart';
import 'package:epeoplecare/module/leave/model/leave_balance.dart';
import 'package:epeoplecare/module/leave/model/leave_category.dart';
import 'package:epeoplecare/module/leave/model/leave_group.dart';
import 'package:epeoplecare/module/leave/model/leave_transaction.dart';
import 'package:epeoplecare/module/leave/model/leave_transaction_scoupe.dart';
import 'package:epeoplecare/module/leave/model/leave_transaction_scoupe_public_holiday.dart';
import 'package:epeoplecare/module/leave/model/leave_value_type.dart';
import 'package:epeoplecare/module/leave/repository/leave_balance_repository.dart';
import 'package:epeoplecare/module/leave/view/leave/leave_scoupe_page.dart';
import 'package:epeoplecare/module/workflow/model/node.dart';
import 'package:epeoplecare/module/workflow/model/route_type.dart';
import 'package:epeoplecare/module/workflow/model/workflow_detail.dart';
import 'package:epeoplecare/module/workflow/model/workflow_executor.dart';
import 'package:epeoplecare/module/workflow/model/workflow_status.dart';
import 'package:epeoplecare/module/workflow/repository/node_repository.dart';
import 'package:epeoplecare/provider/date_provider.dart';
import 'package:epeoplecare/provider/number_provider.dart';
import 'package:epeoplecare/repository/company/public_holiday_repository.dart';
import 'package:epeoplecare/module/leave/repository/leave_category_repository.dart';
import 'package:epeoplecare/module/leave/repository/leave_group_repository.dart';
import 'package:epeoplecare/module/leave/repository/leave_transaction_repository.dart';
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

class LeaveApplicationPage extends StatefulWidget {
  final LeaveTransaction? leaveTransaction;
  const LeaveApplicationPage({Key? key, this.leaveTransaction}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _LeaveApplicationPageState();
}

class _LeaveApplicationPageState extends State<LeaveApplicationPage> {
  final form = GlobalKey<FormState>();
  LeaveGroup? _valLeaveGroup;
  List<Dropdown> leaveGroups = [];
  LeaveCategory? _valLeaveCategory;
  List<Dropdown> leaveCategories = [];
  final _assignmentController = TextEditingController();
  final _assigneeController = TextEditingController();
  final _dateFromController = TextEditingController();
  final _dateToController = TextEditingController();
  final _durationController = TextEditingController();
  final _remarkController = TextEditingController();
  String? _alternateAttachment;
  bool _enableEndDated = true;
  List<WorkflowDetail> approvalHistories = [];
  DateTime _initialDateFrom = DateTime.now();
  DateTime _initialDateTo = DateTime.now();

  final LeaveTransactionRepository _leaveTransactionRepository = Repository().getLeaveTransactionRepository();
  final LeaveCategoryRepository _leaveCategoryRepository = Repository().getLeaveCategoryRepository();
  final LeaveGroupRepository _leaveGroupRepository = Repository().getLeaveGroupRepository();
  final CustomFieldRepository _customFieldRepository = Repository().getCustomFieldRepository();
  List<CustomValue> _customValues = [];
  bool _assignment = false;
  Employee? _assignee;
  List<WorkflowExecutor> _workflowExecutors = [];
  final NodeRepository _nodeRepository = Repository().getNodeRepository();
  bool _isExpand = true;
  List<LeaveTransactionScoupe> _leaveTransactionScoupes = [];
  List<LeaveTransactionScoupePublicHoliday> _leaveTransactionScoupePublicHolidays = [];
  final _scoupeDurationController = TextEditingController();
  double _scoupeDuration = 0.0;
  final PublicHolidayRepository _publicHolidayRepository = Repository().getPublicHolidayRepository();
  final LeaveBalanceRepository _leaveBalanceRepository = Repository().getLeaveBalanceRepository();
  final _balanceController = TextEditingController();
  List<Media> _medias = [];

  @override
  void initState() {
    super.initState();
    _getLeaveGroup();
    _initData();
  }

  _initData() {
    if (widget.leaveTransaction != null) {
      _initialDateFrom = DateProvider.convertStr2Date(widget.leaveTransaction!.startDate, "yyyy-MM-dd HH:mm:ss")!;
      _initialDateTo = DateProvider.convertStr2Date(widget.leaveTransaction!.endDate, "yyyy-MM-dd HH:mm:ss")!;
      _dateFromController.text = DateProvider.convertDateStrFormat(widget.leaveTransaction!.startDate, "yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd");
      _dateToController.text = DateProvider.convertDateStrFormat(widget.leaveTransaction!.endDate, "yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd");
      _durationController.text = widget.leaveTransaction!.duration.toString();
      _remarkController.text = widget.leaveTransaction!.description ?? "";
      _alternateAttachment = widget.leaveTransaction!.attachment;
      setState(() {
        if (widget.leaveTransaction!.leaveCategory!.leaveValueType != null &&
            ((widget.leaveTransaction!.leaveCategory!.leaveValue != null) || widget.leaveTransaction!.leaveCategory!.asBalance!)) {
          _enableEndDated = false;
        } else {
          _enableEndDated = true;
        }
      });
      renderHistory(widget.leaveTransaction!.workflow!.workflowDetails);
      _customValues = widget.leaveTransaction!.customValues;
      _assignment = widget.leaveTransaction!.assignment ?? false;
      _assignee = widget.leaveTransaction!.assignee;
      if (_assignee != null) {
        _assigneeController.text = "${_assignee!.code} ${_assignee!.name}";
      }
      _initWorkflowExecutor(widget.leaveTransaction!.workflow!.workflowExecutors);
      _leaveTransactionScoupes = widget.leaveTransaction!.leaveTransactionScoupes;
      _leaveTransactionScoupePublicHolidays = widget.leaveTransaction!.leaveTransactionScoupePublicHolidays;
      _scoupeDuration = widget.leaveTransaction!.scoupeDuration ?? 0;
      _scoupeDurationController.text = widget.leaveTransaction!.scoupeDuration.toString();
      _balanceController.text = widget.leaveTransaction!.balance != null ? widget.leaveTransaction!.balance.toString() : "0";
      _medias = widget.leaveTransaction!.medias;
    } else {
      _initCustomField();
      _initWorkflowExecutor(null);
    }
  }

  _initCustomField() {
    _customFieldRepository.listByType("LeaveTransaction").then((items) {
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

    _nodeRepository.getOverrideNode(Config.user!.employee!, RouteType.LEAVE).then((value) {
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

      histories.sort((a, b) {
        if (a.executedDate == null || b.executedDate == null) return 1;
        return b.executedDate!.compareTo(a.executedDate!);
      });
      approvalHistories.clear();
      for (var item in histories) {
        if (item.executedDate != null && item.workflowStatus != null && item.executor != null) {
          approvalHistories.add(item);
        }
      }
    });
  }

  _getLeaveGroup() {
    _leaveGroupRepository.listHasCategory().then((value) async {
      if (value.isEmpty) return;

      setState(() {
        Dropdown dropdown = Dropdown(value: null, label: "Select Leave Group".tr());
        leaveGroups.add(dropdown);
        for (var i = 0; i < value.length; i++) {
          Dropdown dropdown = Dropdown(value: value[i], label: value[i].name);
          if (widget.leaveTransaction != null && widget.leaveTransaction!.leaveCategory!.leaveGroup!.id == value[i].id) {
            _valLeaveGroup = dropdown.value;
            _getLeaveCategory(_valLeaveGroup!);
          }
          leaveGroups.add(dropdown);
        }
      });
    });
  }

  _getLeaveCategory(LeaveGroup leaveGroup) {
    _leaveCategoryRepository.listByLeaveGroup(leaveGroup).then((value) {
      if (value.isEmpty) return;

      setState(() {
        leaveCategories.clear();
        Dropdown dropdown = Dropdown(value: null, label: "Select Leave Category".tr());
        leaveCategories.add(dropdown);
        Employee employee = Config.user!.employee!;
        if (_assignee != null) {
          employee = _assignee!;
        }
        for (var i = 0; i < value.length; i++) {
          if(value[i].status == false) continue;

          if ((value[i].gender == null || value[i].gender == employee.gender) &&
              (value[i].marital == null || value[i].marital == employee.marital)) {
            Dropdown dropdown = Dropdown(value: value[i], label: value[i].name);
            if (widget.leaveTransaction != null && widget.leaveTransaction!.leaveCategory!.id == value[i].id) {
              _valLeaveCategory = dropdown.value;
            }
            leaveCategories.add(dropdown);
          }
        }
      });
    });
  }

  void _submitForm(WorkflowStatus workflowStatus, String remark) async {
    setState(() {
      _isExpand = true;
    });
    await Future.delayed(const Duration(milliseconds: 100));

    if (form.currentState!.validate()) {
      EasyLoading.show(status: "Please Wait".tr());

      Map<String, dynamic> parameters = HashMap();
      parameters["remark"] = remark;

      LeaveTransaction leaveTransaction = LeaveTransaction(
        widget.leaveTransaction != null ? widget.leaveTransaction!.id : null,
        widget.leaveTransaction != null ? widget.leaveTransaction!.creator : null,
        widget.leaveTransaction != null ? widget.leaveTransaction!.creationTime : null,
        widget.leaveTransaction != null ? widget.leaveTransaction!.updater : null,
        widget.leaveTransaction != null ? widget.leaveTransaction!.updateTime : null,
        widget.leaveTransaction != null ? widget.leaveTransaction!.version : null,
        _customValues,
        Config.excludeOldAttachment(_medias),
        widget.leaveTransaction != null ? widget.leaveTransaction!.workflow : null,
        widget.leaveTransaction != null ? widget.leaveTransaction!.requestNo : null,
        workflowStatus,
        Config.user!.employee,
        Config.oldAttachment(_alternateAttachment, _medias),
        _remarkController.text,
        _assignee,
        _assignment,
        parameters,
        _workflowExecutors,
        DateProvider.convertDateStrFormat(_dateFromController.text, "yyyy-MM-dd", "yyyy-MM-dd HH:mm:ss"),
        DateProvider.convertDateStrFormat(_dateToController.text, "yyyy-MM-dd", "yyyy-MM-dd HH:mm:ss"),
        double.parse(_durationController.text),
        _valLeaveCategory,
        _scoupeDuration,
        _leaveTransactionScoupes,
        _leaveTransactionScoupePublicHolidays,
        double.parse(_balanceController.text != "" ? _balanceController.text.replaceAll(",", "") : "0"),
      );
      if (widget.leaveTransaction != null) {
        _leaveTransactionRepository.update(id: widget.leaveTransaction!.id!, entity: leaveTransaction).then((value) {
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
        _leaveTransactionRepository.save(entity: leaveTransaction).then((value) {
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
      }
    }
  }
  _calculateDuration() {
    List<int> scoupePublicHolidays = [];
    for (LeaveTransactionScoupePublicHoliday leaveTransactionScoupePublicHoliday in _leaveTransactionScoupePublicHolidays) {
      if (!leaveTransactionScoupePublicHoliday.scoupe) {
        scoupePublicHolidays.add(leaveTransactionScoupePublicHoliday.publicHoliday!.id!);
      }
    }

    if (_enableEndDated) {
      if (_dateFromController.text == "" || _dateToController.text == "" || _valLeaveCategory == null) return;
      DateTime dateFrom = DateProvider.convertStr2Date(_dateFromController.text, "yyyy-MM-dd")!;
      DateTime dateTo = DateProvider.convertStr2Date(_dateToController.text, "yyyy-MM-dd")!;

      if (_assignment == true && _assignee != null) {
        _leaveTransactionRepository.getDuration(_assignee!, _valLeaveCategory!, dateFrom, dateTo, scoupePublicHolidays).then((value) async {
          _durationController.text = value.toString();

          if (_valLeaveCategory!.asScoupe != null && _valLeaveCategory!.asScoupe!) {
            double scoupeDuration = await _setScoupePublicHolidays(_assignee!, dateFrom, dateTo);
            scoupeDuration += await _setScoupes(_assignee!, dateFrom, dateTo);
            setState(() {
              _scoupeDurationController.text = scoupeDuration.toString();
              _scoupeDuration = scoupeDuration;
            });
          }
        });
      } else if (Config.user!.employee != null) {
        _leaveTransactionRepository.getDuration(Config.user!.employee!, _valLeaveCategory!, dateFrom, dateTo, scoupePublicHolidays).then((value) async {
          _durationController.text = value.toString();

          if (_valLeaveCategory!.asScoupe != null && _valLeaveCategory!.asScoupe!) {
            double scoupeDuration = await _setScoupePublicHolidays(Config.user!.employee!, dateFrom, dateTo);
            scoupeDuration += await _setScoupes(Config.user!.employee!, dateFrom, dateTo);
            setState(() {
              _scoupeDurationController.text = scoupeDuration.toString();
              _scoupeDuration = scoupeDuration;
            });
          }
        });
      }
    } else {
      if (_dateFromController.text == "" || _valLeaveCategory == null) return;
      var dateFrom = DateProvider.convertStr2Date(_dateFromController.text, "yyyy-MM-dd");
      var dateTo = DateProvider.convertStr2Date(_dateToController.text, "yyyy-MM-dd");

      if (_assignment == true && _assignee != null) {
        _leaveTransactionRepository.getDateTo(_assignee!, _valLeaveCategory!, dateFrom!, scoupePublicHolidays).then((value) async {
          if (_valLeaveCategory!.asBalance != null &&_valLeaveCategory!.asBalance!) {
            _durationController.text = "0.0";
            double balance = 0.0;
            List<LeaveBalance> leaveBalances = await _leaveBalanceRepository.listByEmployeeAndDateAndLeaveGroup(_assignee!, dateFrom, dateTo!, _valLeaveCategory!.leaveGroup!);
            for (var leaveBalance in leaveBalances) {
              balance += leaveBalance.balance;
            }
            _durationController.text = balance.toString();
          } else if (_valLeaveCategory!.asEntitlement != null && _valLeaveCategory!.asEntitlement!) {
            _durationController.text = "0.0";
            double balance = 0.0;
            List<LeaveBalance> leaveBalances = await _leaveBalanceRepository.listByEmployeeAndDateAndLeaveGroup(_assignee!, dateFrom, dateTo!, _valLeaveCategory!.leaveGroup!);
            for (var leaveBalance in leaveBalances) {
              balance += leaveBalance.entitlement;
            }
            _durationController.text = balance.toString();
          } else {
            _durationController.text = _valLeaveCategory!.leaveValue.toString();
          }
          _dateToController.text = DateProvider.convertDateStrFormat(value, "yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd");

          if (_valLeaveCategory!.asScoupe != null && _valLeaveCategory!.asScoupe!) {
            double scoupeDuration = await _setScoupePublicHolidays(_assignee!, dateFrom, DateProvider.convertStr2Date(value, "yyyy-MM-dd HH:mm:ss")!);
            scoupeDuration += await _setScoupes(_assignee!, dateFrom, DateProvider.convertStr2Date(value, "yyyy-MM-dd HH:mm:ss")!);
            setState(() {
              _scoupeDurationController.text = scoupeDuration.toString();
              _scoupeDuration = scoupeDuration;
            });
          }
        });
      } else if (Config.user!.employee != null) {
        _leaveTransactionRepository.getDateTo(Config.user!.employee!, _valLeaveCategory!, dateFrom!, scoupePublicHolidays).then((value) async {
          if (_valLeaveCategory!.asBalance != null && _valLeaveCategory!.asBalance!) {
            _durationController.text = "0.0";
            double balance = 0.0;
            List<LeaveBalance> leaveBalances = await _leaveBalanceRepository.listByEmployeeAndDateAndLeaveGroup(Config.user!.employee!, dateFrom, dateTo!, _valLeaveCategory!.leaveGroup!);
            for (var leaveBalance in leaveBalances) {
              balance += leaveBalance.balance;
            }
            _durationController.text = balance.toString();
          } else if (_valLeaveCategory!.asEntitlement != null && _valLeaveCategory!.asEntitlement!) {
            _durationController.text = "0.0";
            double balance = 0.0;
            List<LeaveBalance> leaveBalances = await _leaveBalanceRepository.listByEmployeeAndDateAndLeaveGroup(Config.user!.employee!, dateFrom, dateTo!, _valLeaveCategory!.leaveGroup!);
            for (var leaveBalance in leaveBalances) {
              balance += leaveBalance.entitlement;
            }
            _durationController.text = balance.toString();
          } else {
            _durationController.text = _valLeaveCategory!.leaveValue.toString();
          }
          _dateToController.text = DateProvider.convertDateStrFormat(value, "yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd");

          if (_valLeaveCategory!.asScoupe != null && _valLeaveCategory!.asScoupe!) {
            double scoupeDuration = await _setScoupePublicHolidays(Config.user!.employee!, dateFrom, DateProvider.convertStr2Date(value, "yyyy-MM-dd HH:mm:ss")!);
            scoupeDuration += await _setScoupes(Config.user!.employee!, dateFrom, DateProvider.convertStr2Date(value, "yyyy-MM-dd HH:mm:ss")!);
            setState(() {
              _scoupeDurationController.text = scoupeDuration.toString();
              _scoupeDuration = scoupeDuration;
            });
          }
        });
      }
    }
  }

  Future<double> _setScoupePublicHolidays(Employee employee, DateTime dateFrom, DateTime dateTo) async {
    List<PublicHoliday> publicHolidays = await _publicHolidayRepository.listScoupe(employee, dateFrom, dateTo);
    List<LeaveTransactionScoupePublicHoliday> scoupePublicHolidays = [];
    double scoupeDuration = 0.0;

    for (PublicHoliday publicHoliday in publicHolidays) {
      LeaveTransactionScoupePublicHoliday scoupePublicHoliday = LeaveTransactionScoupePublicHoliday(
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null, 
        publicHoliday,
        1.0,
        true,
      );

      scoupePublicHolidays.add(scoupePublicHoliday);
    }

    for (LeaveTransactionScoupePublicHoliday scoupe in _leaveTransactionScoupePublicHolidays) {
      for (LeaveTransactionScoupePublicHoliday scoupePublicHoliday in scoupePublicHolidays) {
        if (scoupe.publicHoliday!.id == scoupePublicHoliday.publicHoliday!.id) {
          scoupePublicHoliday.scoupe = scoupe.scoupe;
          scoupePublicHoliday.id = scoupe.id;
          scoupePublicHoliday.version = scoupe.version;
        }
      }
    }

    _leaveTransactionScoupePublicHolidays = scoupePublicHolidays;
    for (LeaveTransactionScoupePublicHoliday scoupePublicHoliday in _leaveTransactionScoupePublicHolidays) {
      if (scoupePublicHoliday.scoupe) {
        scoupeDuration++;
      }
    }

    return scoupeDuration;
  }

  Future<double> _setScoupes(Employee employee, DateTime dateFrom, DateTime dateTo) async {
    List<LeaveTransactionScoupe> scoupes = await _leaveTransactionRepository.listScoupe(employee, dateFrom, dateTo);
    double scoupeDuration = 0.0;

    for (LeaveTransactionScoupe scoupe1 in _leaveTransactionScoupes) {
      for (LeaveTransactionScoupe scoupe2 in scoupes) {
        if (scoupe1.leaveTransactionScoupe!.id == scoupe2.leaveTransactionScoupe!.id) {
          scoupe2.scoupe = scoupe1.scoupe;
          scoupe2.id = scoupe1.id;
          scoupe2.version = scoupe1.version;
        }
      }
    }

    _leaveTransactionScoupes = scoupes;
    for (LeaveTransactionScoupe scoupe in _leaveTransactionScoupes) {
      if (scoupe.scoupe) {
        scoupeDuration += scoupe.duration;
      }
    }

    return scoupeDuration;
  }

  _setInitialDateFrom() {
    if (_dateFromController.text.isNotEmpty && _dateToController.text.isNotEmpty) {
      if (DateProvider.convertStr2Date(_dateFromController.text, "yyyy-MM-dd")!.compareTo(DateProvider.convertStr2Date(_dateToController.text, "yyyy-MM-dd")!) > 0) {
        _initialDateFrom = DateProvider.convertStr2Date(_dateToController.text, "yyyy-MM-dd")!;
      } else {
        _initialDateFrom = DateProvider.convertStr2Date(_dateFromController.text, "yyyy-MM-dd")!;
      }
    } else if (_dateToController.text.isNotEmpty) {
      if (DateProvider.convertStr2Date(_dateToController.text, "yyyy-MM-dd")!.compareTo(DateTime.now()) < 0) {
        _initialDateFrom = DateProvider.convertStr2Date(_dateToController.text, "yyyy-MM-dd")!;
      }
    } else if (_dateFromController.text.isNotEmpty) {
      _initialDateFrom = DateProvider.convertStr2Date(_dateFromController.text, "yyyy-MM-dd")!;
    }
  }

  _setInitialDateTo() {
    if (_dateFromController.text.isNotEmpty && _dateToController.text.isNotEmpty) {
      if (DateProvider.convertStr2Date(_dateFromController.text, "yyyy-MM-dd")!.compareTo(DateProvider.convertStr2Date(_dateToController.text, "yyyy-MM-dd")!) > 0) {
        _initialDateTo = DateProvider.convertStr2Date(_dateFromController.text, "yyyy-MM-dd")!;
      } else {
        _initialDateTo = DateProvider.convertStr2Date(_dateToController.text, "yyyy-MM-dd")!;
      }
    } else if (_dateFromController.text.isNotEmpty) {
      if (DateProvider.convertStr2Date(_dateFromController.text, "yyyy-MM-dd")!.compareTo(DateTime.now()) > 0) {
        _initialDateTo = DateProvider.convertStr2Date(_dateFromController.text, "yyyy-MM-dd")!;
      }
    } else if (_dateToController.text.isNotEmpty) {
      _initialDateTo = DateProvider.convertStr2Date(_dateToController.text, "yyyy-MM-dd")!;
    }
  }

  getBalance() {
    if (_valLeaveGroup != null && _valLeaveGroup!.nonBalance == false) {
      Employee? employee = Config.user!.employee;
      if(_assignment) {
        employee = _assignee;
      }

      if(employee != null) {
        _leaveTransactionRepository.getBalance(_dateFromController.text != "" ? DateProvider.convertStr2Date(_dateFromController.text, "yyyy-MM-dd")! : DateProvider.getCurrentDate(), _dateToController.text != "" ? DateProvider.convertStr2Date(_dateToController.text, "yyyy-MM-dd")! : DateProvider.getCurrentDate(), _valLeaveGroup!, employee, widget.leaveTransaction, _valLeaveCategory).then((value) async {
          _balanceController.text = NumberProvider.decimalFormatDouble(value);
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
          style: TextStyle(color: Config.DEFAULT_ACCENT_COLOR),
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
                    const SizedBox(height: 5.0),
                    Visibility(
                      visible: Config.hasPermission("LeaveTransaction", "RequestForOther") || Config.isManager,
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
                                if (_assignment == false) {
                                  _assignee = null;
                                  _assigneeController.text = "";
                                  _valLeaveCategory = null;
                                }
                              });
                               _getLeaveCategory(_valLeaveGroup!);
                            }),
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
                            parameters.putIfAbsent("entity", () => "LeaveTransaction");
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
                                _valLeaveCategory = null;
                              });
                               _getLeaveCategory(_valLeaveGroup!);
                            });
                          }
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: InputForm().renderDropdownField(
                          fieldName: "Leave Group".tr(),
                          value: _valLeaveGroup,
                          listItem: leaveGroups,
                          onChanged: (val) {
                            setState(() {
                              _valLeaveGroup = val as LeaveGroup?;
                              _dateFromController.text = "";
                              _dateToController.text = "";
                              _durationController.text = "";
                              _valLeaveCategory = null;
                              getBalance();
                            });

                            if (val == null) {
                              setState(() {
                                leaveCategories.clear();
                              });
                            } else {
                              _getLeaveCategory(_valLeaveGroup!);
                            }
                          },
                          validator: (val) {
                            if (val == null) {
                              return "This field is required".tr();
                            }
                            return null;
                          }),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: InputForm().renderDropdownField(
                          fieldName: "Leave Category".tr(),
                          value: _valLeaveCategory,
                          listItem: leaveCategories,
                          onChanged: (value) {
                            setState(() {
                              _dateFromController.text = "";
                              _dateToController.text = "";
                              _durationController.text = "";
                              _valLeaveCategory = value as LeaveCategory?;

                              if (_valLeaveCategory != null &&
                                  _valLeaveCategory!.leaveValueType != null &&
                                  ((_valLeaveCategory!.leaveValue != null) || _valLeaveCategory!.asBalance!)) {
                                _enableEndDated = false;
                              } else {
                                _enableEndDated = true;
                              }
                              getBalance();
                            });
                          },
                          validator: (val) {
                            if (val == null) {
                              return "This field is required".tr();
                            }
                            return null;
                          }),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: InputForm().renderCustomDateField(
                        fieldName: "Date From".tr(),
                        initialDate: _initialDateFrom,
                        firstDate: DateTime(1990),
                        lastDate: _dateToController.text.isNotEmpty && _enableEndDated
                            ? DateProvider.convertStr2Date(_dateToController.text, "yyyy-MM-dd")!
                            : DateTime(2050),
                        controller: _dateFromController,
                        validator: Validation.validateField,
                        employee: _assignment == true && _assignee != null ? _assignee! : Config.user!.employee!,
                        onChanged: (value) {
                          _dateFromController.text = DateProvider.convertDate2Str(value, "yyyy-MM-dd");
                          if (!_enableEndDated && !_valLeaveCategory!.asBalance!) {
                            if (_valLeaveCategory!.leaveValueType == LeaveValueType.MONTH) {
                              _dateToController.text =
                                  DateProvider.convertDate2Str(DateTime(value.year, value.month + _valLeaveCategory!.leaveValue!.toInt(), value.day), "yyyy-MM-dd");
                            } else {
                              _dateToController.text = DateProvider.convertDate2Str(value.add(Duration(days: _valLeaveCategory!.leaveValue!.toInt())), "yyyy-MM-dd");
                            }
                            _durationController.text = _valLeaveCategory!.leaveValue!.toStringAsFixed(2);
                          }
                          _calculateDuration();
                          setState(() {
                            _setInitialDateFrom();
                            _setInitialDateTo();
                            getBalance();
                          });
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: InputForm().renderCustomDateField(
                        fieldName: "Date To".tr(),
                        initialDate: _initialDateTo,
                        firstDate: _dateFromController.text.isNotEmpty ? DateProvider.convertStr2Date(_dateFromController.text, "yyyy-MM-dd")! : DateTime(1990),
                        lastDate: DateTime(2050),
                        controller: _dateToController,
                        validator: Validation.validateField,
                        enabled: _enableEndDated,
                        employee: _assignment == true && _assignee != null ? _assignee! : Config.user!.employee!,
                        onChanged: (value) {
                          _dateToController.text = DateProvider.convertDate2Str(value, "yyyy-MM-dd");
                          _calculateDuration();
                          setState(() {
                            _setInitialDateTo();
                            getBalance();
                          });
                        },
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
                    Visibility(
                      visible: _scoupeDuration > 0 ||
                          (_leaveTransactionScoupes.isNotEmpty) ||
                          (_leaveTransactionScoupePublicHolidays.isNotEmpty),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Column(
                          children: [
                            InputForm().renderTextField(
                              fieldName: "Scoupe Duration".tr(),
                              controller: _scoupeDurationController,
                              enabled: false,
                            ),
                            const SizedBox(height: 5.0),
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LeaveScoupePage(
                                      leaveTransactionScoupes: _leaveTransactionScoupes,
                                      leaveTransactionScoupePublicHolidays: _leaveTransactionScoupePublicHolidays,
                                      editable: true,
                                    ),
                                  ),
                                ).then((value) {
                                  _calculateDuration();
                                });
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  const Icon(
                                    Icons.help,
                                    color: Colors.grey,
                                    size: 15.0,
                                  ),
                                  const SizedBox(width: 5.0),
                                  Text(
                                    "View Detail".tr(),
                                    style: const TextStyle(color: Colors.blue),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Visibility(
                      visible: _valLeaveGroup != null && _valLeaveGroup!.nonBalance == false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: InputForm().renderTextField(
                          fieldName: "Balance".tr(),
                          controller: _balanceController,
                          enabled: false,
                        ),
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
                        editMode: widget.leaveTransaction != null ? true : false,
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
                        builder: (BuildContext bc) {
                          return ApprovalProcess(
                            workflow: widget.leaveTransaction != null ? widget.leaveTransaction!.workflow : null,
                            workflowStatus: widget.leaveTransaction != null ? widget.leaveTransaction!.workflowStatus : null,
                          );
                        },
                      ).then((value) {
                        if (value == null) return;

                        _submitForm(value['workflowStatus'], value['remark']);
                      });
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
