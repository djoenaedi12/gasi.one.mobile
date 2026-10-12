// ignore_for_file: use_build_context_synchronously

import 'dart:collection';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/sort.dart';
import 'package:epeoplecare/model/sort_direction.dart';
import 'package:epeoplecare/module/attendance/model/work_from_home.dart';
import 'package:epeoplecare/module/attendance/repository/work_from_home_repository.dart';
import 'package:epeoplecare/module/attendance/view/wfh/work_from_home_application_page.dart';
import 'package:epeoplecare/module/attendance/view/wfh/work_from_home_detail_page.dart';
import 'package:epeoplecare/module/workflow/model/node_type.dart';
import 'package:epeoplecare/module/workflow/model/workflow_detail.dart';
import 'package:epeoplecare/module/workflow/model/workflow_status.dart';
import 'package:epeoplecare/provider/enum_provider.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/view/shared/transaction_tab_page.dart';
import 'package:flutter/material.dart';

class WorkFromHomeSubmissionPage extends StatefulWidget {
  final IconData? icon;
  const WorkFromHomeSubmissionPage({super.key, this.icon});

  @override
  State<StatefulWidget>  createState() => _WorkFromHomeSubmissionPageState();
}

class _WorkFromHomeSubmissionPageState extends State<WorkFromHomeSubmissionPage> {

  List<List<dynamic>> data = [
      [],
      [],
      [],
      [],
  ];
  List<int> currentPage = [0, 0, 0, 0];
  List<bool> enabledPullUp = [false, false, false, false];
  List<List<String>> status = [
    [
      EnumProvider.convertToString(WorkflowStatus.DRAFTED)!,
      EnumProvider.convertToString(WorkflowStatus.SUBMITTED)!,
      EnumProvider.convertToString(WorkflowStatus.APPROVAL_PROCESS)!,
      EnumProvider.convertToString(WorkflowStatus.SENDBACKED)!,
      EnumProvider.convertToString(WorkflowStatus.PULLBACKED)!,
    ], 
    [
      EnumProvider.convertToString(WorkflowStatus.APPROVED)!,
    ], 
    [
      EnumProvider.convertToString(WorkflowStatus.REJECTED)!,
    ], 
    [
      EnumProvider.convertToString(WorkflowStatus.CANCELLED)!,
      EnumProvider.convertToString(WorkflowStatus.REVOKED)!,
    ], 
  ];
  List<String> tabs = [
    "Pending".tr(),
    "Approved".tr(),
    "Rejected".tr(),
    "Cancelled".tr(),
  ];
  final WorkFromHomeRepository _workFromHomeRepository = Repository().getWorkFromHomeRepository();
  List<Sort> sorts = [Sort("updateTime", SortDirection.DESC)];
  List<bool> isLoading = [true, true, true, true];
  String? _requestNo;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  _initData() {
    for (var i = 0; i < currentPage.length; i++) {
      Map<String, dynamic> parameters = HashMap();
      parameters['employee'] = Config.user!.employee!.id;
      parameters['workflowStatus.in'] = status[i];
      if(_requestNo != null) {
        parameters['requestNo.like'] = _requestNo;
      }

      _workFromHomeRepository.listPagination(page: currentPage[i], parameters: parameters, sorts: sorts).then((value) {
        setState(() {
          if(value.totalPages - currentPage[i] > 1) {
            enabledPullUp[i] = true;
          } else {
            enabledPullUp[i] = false;
          }
          data[i] = value.content;
          isLoading[i] = false;
        });
      }).catchError((onError) {
          setState(() {
            isLoading[i] = false;
          });
      });
    }
  }

  _onRefresh(int index) async {
    setState(() {
      currentPage[index] = 0;
    });
    Map<String, dynamic> parameters = HashMap();
    parameters['employee'] = Config.user!.employee!.id;
    parameters['workflowStatus.in'] = status[index];
    if(_requestNo != null) {
      parameters['requestNo.like'] = _requestNo;
    }

    await _workFromHomeRepository.listPagination(page: currentPage[index], parameters: parameters, sorts: sorts).then((value) {
      setState(() {
        if(value.totalPages - currentPage[index] > 1) {
          enabledPullUp[index] = true;
        } else {
          enabledPullUp[index] = false;
        }
        data[index] = value.content;
      });
    }).catchError((onError) {
        setState(() {
          isLoading[index] = false;
        });
    });
  }

  _onLoading(int index) async {
    setState(() {
      currentPage[index] = currentPage[index] + 1;
    });
    Map<String, dynamic> parameters = HashMap();
    parameters['employee'] = Config.user!.employee!.id;
    parameters['workflowStatus.in'] = status[index];
    if(_requestNo != null) {
      parameters['requestNo.like'] = _requestNo;
    }

    await _workFromHomeRepository.listPagination(page: currentPage[index], parameters: parameters, sorts: sorts).then((value) {
      setState(() {
        if(value.totalPages - currentPage[index] > 1) {
          enabledPullUp[index] = true;
        } else {
          enabledPullUp[index] = false;
        }
        for (var item in value.content) {
          data[index].add(item);
        }
      });
    }).catchError((onError) {
        setState(() {
          isLoading[index] = false;
        });
    });
  }

  Widget _renderItem(dynamic param, int index) {
    WorkFromHome workFromHome = param;

    return Container(
      padding: const EdgeInsets.all(15.0),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Icon(
              widget.icon ?? Icons.home_work_outlined,
              size: 40,
              color: Config.DEFAULT_COLOR,
            ),
          ),
          const SizedBox(width: 10.0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                workFromHome.requestNo ?? "",
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3.0),
              const SizedBox(height: 5.0),
              Text(
                workFromHome.workflow != null  ? workFromHome.workflow!.applyDate : "",
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  _onTapItem(dynamic param, int index) async {
    WorkFromHome workFromHome = param;
    if(await _isEditAble(workFromHome)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WorkFromHomeApplicationPage(
            workFromHome: param,
          ),
        ),
      ).then((value) {
        if(value == null) return;

        _initData();
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WorkFromHomeDetailPage(
            title: "Application Form".tr(),
            workFromHome: param,
          ),
        ),
      ).then((value) {
        if(value == null) return;

        _initData();
      });
    }
  }

  Future<bool> _isEditAble(WorkFromHome workFromHome) async {
    if(workFromHome.workflowStatus == WorkflowStatus.DRAFTED || workFromHome.workflowStatus == WorkflowStatus.PULLBACKED) {
      return true;
    }

    if(workFromHome.workflowStatus == WorkflowStatus.SENDBACKED) {
      WorkflowDetail? workflowDetail = await _workFromHomeRepository.findLastWorkflowDetail(workFromHome.workflow!);
      if(workflowDetail != null && workflowDetail.node != null && workflowDetail.node!.nodeType == NodeType.APPLICANT) {
        return true;
      }
    }

    return false;
  }

  _onFilterChange(value) {
    if(value == null) return;

    setState(() {
      if(value['requestNo'] != null) {
        _requestNo = value['requestNo'];
      } else {
        _requestNo = null;
      }
    });

    for (var i = 0; i < isLoading.length; i++) {
      isLoading[i] = true;
      currentPage[i] = 0;
    }
    _initData();
  }

  @override
  Widget build(BuildContext context) {
    return TransactionTabPage(
      title: "My Submission".tr(),
      onLoading: _onLoading,
      onRefresh: _onRefresh,
      data: data,
      enabledPullUp: enabledPullUp,
      renderItem: _renderItem,
      onTapItem: _onTapItem,
      tabs: tabs,
      isScrollable: false,
      isLoading: isLoading,
      isFilter: true,
      isApplicant: true,
      requestNo: _requestNo,
      onFilterChange: _onFilterChange,
      filtered: _requestNo != null,
    );
  }
}
