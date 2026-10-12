import 'dart:collection';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/model/pagination.dart';
import 'package:epeoplecare/model/sort.dart';
import 'package:epeoplecare/model/sort_direction.dart';
import 'package:epeoplecare/module/cashadvance/model/ca_request.dart';
import 'package:epeoplecare/module/cashadvance/repository/ca_request_repository.dart';
import 'package:epeoplecare/module/cashadvance/view/ca_detail_page.dart';
import 'package:epeoplecare/module/workflow/model/workflow_status.dart';
import 'package:epeoplecare/provider/enum_provider.dart';
import 'package:epeoplecare/provider/number_provider.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/view/shared/transaction_tab_page.dart';
import 'package:flutter/material.dart';

class CAApprovalPage extends StatefulWidget {
  final IconData? icon;
  const CAApprovalPage({super.key, this.icon});

  @override
  State<StatefulWidget> createState() => _CAApprovalPageState();
}

class _CAApprovalPageState extends State<CAApprovalPage> {

  List<List<dynamic>> data = [
      [],
      [],
      [],
      [],
  ];
  List<List<String>> status = [
    [

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
  List<int> currentPage = [0, 0, 0, 0];
  List<bool> enabledPullUp = [false, false, false, false];
  final CARequestRepository _caRequestRepository = Repository().getCARequestRepository();
  List<Sort> sorts = [Sort("updateTime", SortDirection.DESC)];
  List<bool> isLoading = [true, true, true, true];
  Employee? _employee;
  String? _requestNo;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  _initData() async {
    for (var i = 0; i < currentPage.length; i++) {
      _getData(i).then((value) {
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

  Future<Pagination<CARequest>> _getData(int index) async {
    Pagination<CARequest> result = Pagination();
    Map<String, dynamic> parameters = HashMap();
    parameters["executor"] = Config.user!.employee!.id;
    if(_requestNo != null) {
      parameters['requestNo.like'] = _requestNo;
    }
    if(_employee != null) {
      parameters['employee'] = _employee!.id;
    }
    
    if(index == 0) {
      result = await _caRequestRepository.listPaginationPendingApproval(page: currentPage[index], parameters: parameters, sorts: sorts); 
    } else {
      parameters["executedWorkflowStatus"] = status[index];
      result = await _caRequestRepository.listPaginationHistoryApproval(page: currentPage[index], parameters: parameters, sorts: sorts);
    }
    return result;
  }

  void _onRefresh(int index) async {
    setState(() {
      currentPage[index] = 0;
    });
    await _getData(index).then((value) {
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

  void _onLoading(int index) async {
    setState(() {
      currentPage[index] = currentPage[index] + 1;
    });
    await _getData(index).then((value) {
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
    CARequest caRequest = param;
    return Container(
      padding: const EdgeInsets.all(15.0),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Icon(
              widget.icon ?? Icons.monetization_on,
              size: 40,
              color: Config.DEFAULT_COLOR,
            ),
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  caRequest.requestNo ?? "",
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5.0),
                Text(
                  caRequest.employee != null ? caRequest.employee!.name : "",
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3.0),
                Text(
                  caRequest.caPolicy!.name,
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 3.0),
                Text(
                  NumberProvider.decimalFormatDouble(caRequest.totalAmount),
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 5.0),
                Text(
                  caRequest.workflow != null ? caRequest.workflow!.applyDate : "",
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _onTapItem(dynamic param, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CADetailPage(
          title: "Application Form".tr(),
          isApplication: false,
          caRequest: param,
          index: index,
        ),
      ),
    ).then((value) {
      if(value == null) return;

      _initData();
    });
  }

  _onFilterChange(value) {
    if(value == null) return;

    setState(() {
      if(value['requestNo'] != null) {
        _requestNo = value['requestNo'];
      } else {
        _requestNo = null;
      }
      if(value['employee'] != null) {
        _employee = value['employee'];
      } else {
        _employee = null;
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
      title: "My Approval".tr(),
      onLoading: _onLoading,
      onRefresh: _onRefresh,
      data: data,
      enabledPullUp: enabledPullUp,
      renderItem: _renderItem,
      onTapItem: _onTapItem,
      tabs: tabs,
      isLoading: isLoading,
      isFilter: true,
      isApplicant: false,
      employee: _employee,
      requestNo: _requestNo,
      onFilterChange: _onFilterChange,
      filtered: _employee != null || _requestNo != null,
    );
  }
}
