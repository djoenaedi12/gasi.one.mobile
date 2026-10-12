import 'dart:collection';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/module/leave/model/leave_balance.dart';
import 'package:epeoplecare/module/leave/view/leave/leave_balance_history_page.dart';
import 'package:epeoplecare/view/shared/menu.dart';
import 'package:epeoplecare/model/sort.dart';
import 'package:epeoplecare/model/sort_direction.dart';
import 'package:epeoplecare/module/leave/view/leave/leave_application_page.dart';
import 'package:epeoplecare/module/leave/view/leave/leave_approval_page.dart';
import 'package:epeoplecare/module/leave/view/leave/leave_submission_page.dart';
import 'package:epeoplecare/module/workflow/model/workflow_status.dart';
import 'package:epeoplecare/provider/date_provider.dart';
import 'package:epeoplecare/provider/enum_provider.dart';
import 'package:epeoplecare/module/leave/repository/leave_balance_repository.dart';
import 'package:epeoplecare/module/leave/repository/leave_transaction_repository.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/view/shared/transaction_page.dart';
import 'package:flutter/material.dart';

class LeavePage extends StatefulWidget {
  final String title;
  final IconData? icon;
  const LeavePage({super.key, this.title="", this.icon});

  @override
  State<StatefulWidget> createState() => _LeavePageState();
}

class _LeavePageState extends State<LeavePage> {
  List<Menu> menuHeader = [
    Menu("My Submission".tr(), Icons.format_indent_increase),
    Menu("My Approval".tr(), Icons.format_indent_increase),
  ];
  List<Menu> menuCreateNew = [];

  final LeaveBalanceRepository _leaveBalanceRepository = Repository().getLeaveBalanceRepository();
  final LeaveTransactionRepository _leaveTransactionRepository = Repository().getLeaveTransactionRepository();
  int current = 0;
  List<LeaveBalance> _leaveBalances = [];
  List<Sort> sorts = [Sort("name", SortDirection.ASC)];

  @override
  void initState() {
    super.initState();
    _getLeaveBalance();
    _getCount();
    menuCreateNew.add(Menu(widget.title, widget.icon ?? Icons.accessibility));
  }

  _getLeaveBalance() {
    _leaveBalanceRepository.listByEmployeeAndDate(Config.user!.employee!, DateProvider.getCurrentDateMidnight(), DateProvider.getCurrentDateMidnight()).then((value) {
      _leaveBalances.clear();
      setState(() {
        _leaveBalances = value;
      });
    }).catchError((e) {
      setState(() {
        _leaveBalances.clear();
      });
    });
  }

  _getCount() {
    Map<String, dynamic> parameters = HashMap();
    List<String> status = [
      EnumProvider.convertToString(WorkflowStatus.DRAFTED)!,
      EnumProvider.convertToString(WorkflowStatus.SUBMITTED)!,
      EnumProvider.convertToString(WorkflowStatus.APPROVAL_PROCESS)!,
      EnumProvider.convertToString(WorkflowStatus.SENDBACKED)!,
      EnumProvider.convertToString(WorkflowStatus.PULLBACKED)!,
    ];
    parameters['workflowStatus.in'] = status;
    parameters['employee'] = Config.user!.employee!.id;
    _leaveTransactionRepository.listPagination(parameters: parameters).then((value) {
      setState(() {
        if(value.totalElements > 0 && value.totalElements < 100) {
          menuHeader[0].title = "${"My Submission".tr()} (${value.totalElements})";
        } else if(value.totalElements >= 100) {
            menuHeader[0].title = "${"My Submission".tr()} (99+)";
        } else {
          menuHeader[0].title = "My Submission".tr();
        }
      });
    });

    
    parameters.clear();
    parameters["executor"] = Config.user!.employee!.id;
    _leaveTransactionRepository.listPaginationPendingApproval(parameters: parameters).then((value) {
      setState(() {
        if(value.totalElements > 0 && value.totalElements < 100) {
          menuHeader[1].title = "${"My Approval".tr()} (${value.totalElements})";
        } else if(value.totalElements >= 100) {
          menuHeader[1].title = "${"My Approval".tr()} (99+)";
        } else {
          menuHeader[1].title = "My Approval".tr();
        }
      });
    });
  }

  _onHeaderMenuPress(val) {
    if (val == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LeaveSubmissionPage(icon: widget.icon),
        ),
      ).then((value) {
        _getCount();
        _getLeaveBalance();
      });
    } else if (val == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LeaveApprovalPage(icon: widget.icon),
        ),
      ).then((value) {
        _getCount();
        _getLeaveBalance();
      });
    }
  }

  _onCreateNewMenuPress(val) {
    if (val == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const LeaveApplicationPage(),
        ),
      ).then((value) {
        _getCount();
        _getLeaveBalance();
      });
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
          widget.title,
          style: TextStyle(
            color: Config.DEFAULT_ACCENT_COLOR,
          ),
        ),
        elevation: 0.0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TransactionPage(
              headerMenu: menuHeader,
              createNewMenu: menuCreateNew,
              onHeaderMenuPress: _onHeaderMenuPress,
              onCreateNewMenuPress: _onCreateNewMenuPress,
              menuModules: Config.getMenuOthers("/module/leave", context),
            ),
            Padding(
              padding: const EdgeInsets.only(
                top: 20.0,
                left: 15.0,
                right: 15.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Balance".tr(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16.0,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                top: 15.0,
                left: 15.0,
                right: 15.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                        },
                        child: Text(
                          "My Balance".tr(),
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16.0,
                            color: Config.DEFAULT_COLOR,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10.0),
                    ],
                  ),
                  Divider(
                    color: Config.DEFAULT_COLOR.withValues(alpha: 0.3),
                  ),
                ],
              ),
            ),
            buildBalances(),
          ],
        ),
      ),
    );
  }

  Widget buildBalances() {
    var mediaQuery = MediaQuery.of(context);
    if(_leaveBalances.isEmpty) {
      return Column(
        children: [
          Container(
            margin: const EdgeInsets.only(
              top: 10.0,
              left: 10.0,
            ),
            padding: const EdgeInsets.all(10.0),
            width: mediaQuery.size.width - 20,
            height: 185.0,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.all(
                Radius.circular(
                  5.0,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.3),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: Center(
              child: Text(
                "No Data Found".tr(),
                style: const TextStyle(
                  fontSize: 16.0,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Container(
            height: 8,
            margin: const EdgeInsets.only(top: 10.0),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: 1,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                return Container(
                  width: current == index ? 16.0 : 8.0,
                  height: 8.0,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 2.0,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(
                      Radius.circular(50.0),
                    ),
                    color:
                        current == index ? Config.DEFAULT_COLOR : Colors.grey[300],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10.0),
        ],
      );
    }

    return Column(
      children: <Widget>[
        SizedBox(
          height: 225.0,
          child: PageView.builder(
            onPageChanged: (int index) {
              setState(() {
                current = index;
              });
            },
            scrollDirection: Axis.horizontal,
            itemCount: _leaveBalances.length,
            itemBuilder: (context, index) {
              var balance = _leaveBalances[index];
              return Padding(
                padding: const EdgeInsets.all(10.0),
                child: Container(
                  width: mediaQuery.size.width - 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.all(
                      Radius.circular(
                        5.0,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.3),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LeaveBalanceHistoryPage(
                              leaveBalance: balance
                            ),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 15.0,
                              right: 15.0,
                              top: 15.0,
                              bottom: 5.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  balance.leaveGroup!.name,
                                  style: const TextStyle(
                                    fontSize: 20.0,
                                  ),
                                ),
                                const SizedBox(
                                  height: 2.0,
                                ),
                                Text(
                                  "${balance.balance} ${"Days".tr()}",
                                  style: const TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(
                                  height: 2.0,
                                ),
                                Text(
                                  "${DateProvider.convertDateStrFormat(balance.effectiveDate, "yyyy-MM-dd", "dd MMMM yyyy")} - ${DateProvider.convertDateStrFormat(balance.expiryDate, "yyyy-MM-dd", "dd MMMM yyyy")}",
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12.0,
                                  ),
                                ),
                                const SizedBox(
                                  height: 5.0,
                                ),
                                Divider(
                                  color: Colors.grey.shade300,
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 20.0,
                              right: 60.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      "Entitlement".tr(),
                                      style: const TextStyle(
                                        fontSize: 14.0,
                                      ),
                                    ),
                                    Text(
                                      "${balance.entitlement}",
                                      style: const TextStyle(
                                        fontSize: 20.0,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      "Balance".tr(),
                                      style: const TextStyle(
                                        fontSize: 14.0,
                                      ),
                                    ),
                                    Text(
                                      "${balance.balance}",
                                      style: const TextStyle(
                                        fontSize: 20.0,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: Stack(
                              children: [
                                Container(
                                  width: mediaQuery.size.width,
                                  height: 10.0,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(4),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: balance.balance > 0 ? (mediaQuery.size.width - 50) * (balance.balance/balance.entitlement) : 0,
                                  height: 10.0,
                                  decoration: BoxDecoration(
                                    color: Config.DEFAULT_COLOR,
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(4),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(
          height: 8,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _leaveBalances.length,
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              return Container(
                width: current == index ? 16.0 : 8.0,
                height: 8.0,
                margin: const EdgeInsets.symmetric(
                  horizontal: 2.0,
                ),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(
                    Radius.circular(50.0),
                  ),
                  color: current == index ? Config.DEFAULT_COLOR : Colors.grey[300],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10.0),
      ],
    );
  }
}
