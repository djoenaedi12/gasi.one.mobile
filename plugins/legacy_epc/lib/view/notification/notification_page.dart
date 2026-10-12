import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/notification_model.dart';
import 'package:epeoplecare/model/pagination.dart';
import 'package:epeoplecare/model/sort.dart';
import 'package:epeoplecare/model/sort_direction.dart';
import 'package:epeoplecare/module/attendance/repository/attendance_correction_repository.dart';
import 'package:epeoplecare/module/attendance/repository/flex_hour_repository.dart';
import 'package:epeoplecare/module/attendance/repository/work_from_home_repository.dart';
import 'package:epeoplecare/module/attendance/view/correction/attendance_correction_detail_page.dart';
import 'package:epeoplecare/module/attendance/view/flex_hour/flex_hour_detail_page.dart';
import 'package:epeoplecare/module/attendance/view/wfh/work_from_home_detail_page.dart';
import 'package:epeoplecare/module/benefit/repository/benefit_transaction_repository.dart';
import 'package:epeoplecare/module/benefit/view/benefit_detail_page.dart';
import 'package:epeoplecare/module/businesstrip/repository/business_trip_request_repository.dart';
import 'package:epeoplecare/module/businesstrip/view/business_trip_detail_page.dart';
import 'package:epeoplecare/module/cashadvance/repository/ca_request_repository.dart';
import 'package:epeoplecare/module/cashadvance/repository/ca_settlement_repository.dart';
import 'package:epeoplecare/module/cashadvance/view/ca_detail_page.dart';
import 'package:epeoplecare/module/cashadvance/view/settlement/ca_settlement_detail_page.dart';
import 'package:epeoplecare/module/leave/repository/leave_transaction_repository.dart';
import 'package:epeoplecare/module/leave/view/leave/leave_detail_page.dart';
import 'package:epeoplecare/module/loan/repository/loan_change_request_repository.dart';
import 'package:epeoplecare/module/loan/repository/loan_request_repository.dart';
import 'package:epeoplecare/module/loan/view/change/loan_change_detail_page.dart';
import 'package:epeoplecare/module/loan/view/loan_detail_page.dart';
import 'package:epeoplecare/module/overtime/repository/overtime_transaction_repository.dart';
import 'package:epeoplecare/module/overtime/view/overtime/overtime_detail_page.dart';
import 'package:epeoplecare/module/workflow/model/route_type.dart';
import 'package:epeoplecare/provider/date_provider.dart';
import 'package:epeoplecare/provider/enum_provider.dart';
import 'package:epeoplecare/repository/notification_repository.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/view/shared/message.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<StatefulWidget>  createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  int _currentPage = 0;
  Pagination<NotificationModel> _notifications = Pagination();
  final NotificationRepository _notificationRepository = Repository().getNotificationRepository();
  final OvertimeTransactionRepository _overtimeTransactionRepository = Repository().getOvertimeTransactionRepository();
  final LeaveTransactionRepository _leaveTransactionRepository = Repository().getLeaveTransactionRepository();
  final LoanRequestRepository _loanRequestRepository = Repository().getLoanRequestRepository();
  final LoanChangeRequestRepository _loanChangeRequestRepository = Repository().getLoanChangeRequestRepository();
  final BusinessTripRequestRepository _businessTripRequestRepository = Repository().getBusinessTripRequestRepository();
  final AttendanceCorrectionRepository _attendanceCorrectionRepository = Repository().getAttendanceCorrectionRepository();
  final WorkFromHomeRepository _workFromHomeRepository = Repository().getWorkFromHomeRepository();
  final BenefitTransactionRepository _benefitTransactionRepository = Repository().getBenefitTransactionRepository();
  final CARequestRepository _caRequestRepository = Repository().getCARequestRepository();
  final CASettlementRepository _caSettlementRepository = Repository().getCASettlementRepository();
  final FlexHourRepository _flexHourRepository = Repository().getFlexHourRepository();
  List<Sort> sorts = [Sort("id", SortDirection.DESC)];
  Map<String, dynamic> parameters = HashMap();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    String fcmToken = "-1";
    if(Config.fcmToken != "") {
      fcmToken = Config.fcmToken;
    }

    parameters['receiver'] = fcmToken;
    _initData();
  }

  _initData() {
    _notificationRepository.listPagination(page: _currentPage, sorts: sorts, parameters: parameters).then((value) {
      setState(() {
        _notifications = value;
        _isLoading = false;
      });
    });
  }

  void _onRefresh() async {
    setState(() {
      _currentPage = 0;
    });
    _initData();
    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    setState(() {
      _currentPage = _currentPage + 1;
    });
    await _notificationRepository.listPagination(page: _currentPage, sorts: sorts, parameters: parameters).then((value) {
      for (var item in value.content) {
        setState(() {
          _notifications.add(item);          
        });
      }
    });
    if (mounted) setState(() {});
    _refreshController.loadComplete();
  }

  _onTapItem(int index) {
    setState(() {
      _notifications.content[index].readAt = DateProvider.convertDate2Str(DateTime.now(), "yyyy-MM-dd HH:mm:ss");
    });
    _notificationRepository.markAsRead(_notifications.content[index].id ?? 0);
    _openPageDetail(_notifications.content[index].data);
  }

  _markAllAsRead() {
    EasyLoading.show(status: "Please Wait".tr());
    String receiver = Config.fcmToken;
    _notificationRepository.markAllAsReadByReceiver(receiver).then((value) {
      EasyLoading.dismiss();
      _initData();
      Navigator.pop(context);
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

  _deleteAll() async {
    EasyLoading.show(status: "Please Wait".tr());
    String receiver = Config.fcmToken;
    _notificationRepository.deleteAllByReceiver(receiver).then((value) {
      EasyLoading.dismiss();
      _initData();
      Navigator.pop(context);
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

  void _moreAction() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SizedBox(
          height: 170.0,
          child: ListView(
            children: [
              ListTile(
                title: Text("Mark All as Read".tr()),
                onTap: _markAllAsRead,
              ),
              ListTile(
                title: Text("Delete All".tr()),
                onTap: _deleteAll,
              ),
              ListTile(
                title: Text("Cancel".tr()),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  _openPageDetail(String? json) {
    if(json == null) return;

    var data = jsonDecode(json);
    if(data['workflow_type'] != null && data["workflow_id"] != null) {
      int workflowId = int.parse(data['workflow_id'].toString());
      RouteType transactionType =  EnumProvider.fromString(RouteType.values, data['workflow_type'])!;
      switch (transactionType) {
        case RouteType.OVERTIME:
          _overtimeTransactionRepository.findByWorkflow(workflowId: workflowId).then((value) {
            if(value != null) {
              Navigator.push(
                Config.navigatorKey.currentContext!,
                MaterialPageRoute(
                  builder: (context) => OvertimeDetailPage(
                    title: data["is_applicant"] == "true" 
                          ? "Overtime Application".tr() 
                          : "Overtime Approval".tr(),
                    isApplication: data["is_applicant"] == "true",
                    overtimeTransaction: value,
                    index: 0,
                  ),
                ),
              );
            }
          });
          break;
        case RouteType.LEAVE:
          _leaveTransactionRepository.findByWorkflow(workflowId: workflowId).then((value) {
            if(value != null) {
              Navigator.push(
                Config.navigatorKey.currentContext!,
                MaterialPageRoute(
                  builder: (context) => LeaveDetailPage(
                    title: data["is_applicant"] == "true" 
                          ? "Leave Application".tr() 
                          : "Leave Approval".tr(),
                    isApplication: data["is_applicant"] == "true",
                    leaveTransaction: value,
                    index: 0,
                  ),
                ),
              );
            }
          });
          break;
        case RouteType.LOAN:
          _loanRequestRepository.findByWorkflow(workflowId: workflowId).then((value) {
            if(value != null) {
              Navigator.push(
                Config.navigatorKey.currentContext!,
                MaterialPageRoute(
                  builder: (context) => LoanDetailPage(
                    title: data["is_applicant"] == "true" 
                          ? "Loan Application".tr() 
                          : "Loan Approval".tr(),
                    isApplication: data["is_applicant"] == "true",
                    loanRequest: value,
                    index: 0,
                  ),
                ),
              );
            }
          });
          break;
        case RouteType.LOAN_CHANGE:
          _loanChangeRequestRepository.findByWorkflow(workflowId: workflowId).then((value) {
            if(value != null) {
              Navigator.push(
                Config.navigatorKey.currentContext!,
                MaterialPageRoute(
                  builder: (context) => LoanChangeDetailPage(
                    title: data["is_applicant"] == "true" 
                          ? "Loan Change Application".tr()
                          : "Loan Change Approval".tr(),
                    isApplication: data["is_applicant"] == "true",
                    loanChangeRequest: value,
                    index: 0,
                  ),
                ),
              );
            }
          });
          break;
        case RouteType.BUSINESS_TRIP:
          _businessTripRequestRepository.findByWorkflow(workflowId: workflowId).then((value) {
            if(value != null) {
              Navigator.push(
                Config.navigatorKey.currentContext!,
                MaterialPageRoute(
                  builder: (context) => BusinessTripDetailPage(
                    title: data["is_applicant"] == "true" 
                          ? "Business Trip Application".tr()
                          : "Business Trip Approval".tr(),
                    isApplication: data["is_applicant"] == "true",
                    businessTripRequest: value,
                    index: 0,
                  ),
                ),
              );
            }
          });
          break;
        case RouteType.ATTENDANCE_CORRECTION:
          _attendanceCorrectionRepository.findByWorkflow(workflowId: workflowId).then((value) {
            if(value != null) {
              Navigator.push(
                Config.navigatorKey.currentContext!,
                MaterialPageRoute(
                  builder: (context) => AttendanceCorrectionDetailPage(
                    title: data["is_applicant"] == "true" 
                          ? "Attendance Correction Application".tr() 
                          : "Attendance Correction Approval".tr(),
                    isApplication: data["is_applicant"] == "true",
                    attendanceCorrection: value,
                    index: 0,
                  ),
                ),
              );
            }
          });
          break;
        case RouteType.WORK_FROM_HOME:
          _workFromHomeRepository.findByWorkflow(workflowId: workflowId).then((value) {
            if(value != null) {
              Navigator.push(
                Config.navigatorKey.currentContext!,
                MaterialPageRoute(
                  builder: (context) => WorkFromHomeDetailPage(
                    title: data["is_applicant"] == "true" 
                          ? "Work From Home Application".tr() 
                          : "Work From Home Approval".tr(),
                    isApplication: data["is_applicant"] == "true",
                    workFromHome: value,
                    index: 0,
                  ),
                ),
              );
            }
          });
          break;
        case RouteType.FLEX_HOUR:
          _flexHourRepository.findByWorkflow(workflowId: workflowId).then((value) {
            if(value != null) {
              Navigator.push(
                Config.navigatorKey.currentContext!,
                MaterialPageRoute(
                  builder: (context) => FlexHourDetailPage(
                    title: data["is_applicant"] == "true" 
                          ? "Flex Hour Application".tr() 
                          : "Flex Hour Approval".tr(),
                    isApplication: data["is_applicant"] == "true",
                    flexHour: value,
                    index: 0,
                  ),
                ),
              );
            }
          });
          break;
        case RouteType.BENEFIT:
          _benefitTransactionRepository.findByWorkflow(workflowId: workflowId).then((value) {
            if(value != null) {
              Navigator.push(
                Config.navigatorKey.currentContext!,
                MaterialPageRoute(
                  builder: (context) => BenefitDetailPage(
                    title: data["is_applicant"] == "true" 
                          ? "Benefit Application".tr()
                          : "Benefit Approval".tr(),
                    isApplication: data["is_applicant"] == "true",
                    benefitRequest: value,
                    index: 0,
                  ),
                ),
              );
            }
          });
          break;
        case RouteType.CASH_ADVANCE:
          _caRequestRepository.findByWorkflow(workflowId: workflowId).then((value) {
            if(value != null) {
              Navigator.push(
                Config.navigatorKey.currentContext!,
                MaterialPageRoute(
                  builder: (context) => CADetailPage(
                    title: data["is_applicant"] == "true" 
                          ? "Cash Advance Application".tr()
                          : "Cash Advance Approval".tr(),
                    isApplication: data["is_applicant"] == "true",
                    caRequest: value,
                    index: 0,
                  ),
                ),
              );
            }
          });
          break;
        case RouteType.CASH_ADVANCE_SETTLEMENT:
          _caSettlementRepository.findByWorkflow(workflowId: workflowId).then((value) {
            if(value != null) {
              Navigator.push(
                Config.navigatorKey.currentContext!,
                MaterialPageRoute(
                  builder: (context) => CASettlementDetailPage(
                    title: data["is_applicant"] == "true" 
                          ? "Settlement Application".tr()
                          : "Settlement Approval".tr(),
                    isApplication: data["is_applicant"] == "true",
                    caSettlement: value,
                    index: 0,
                  ),
                ),
              );
            }
          });
          break;
      } 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(),
      backgroundColor: Colors.white,
      body: SmartRefresher(
        controller: _refreshController,
        enablePullUp: _notifications.totalPages - _currentPage > 1,
        enablePullDown: true,
        onRefresh: _onRefresh,
        onLoading: _onLoading,
        header: const ClassicHeader(),
        footer: CustomFooter(
          builder: (context, mode) {
            Widget? body;
            if (mode == LoadStatus.loading) {
              body = const CircularProgressIndicator();
            }
            return SizedBox(
              height: body != null ? 50.0 : 0.0,
              child: Center(child: body),
            );
          },
        ),
        child: buildData(),
      ),
    );
  }

  Widget buildData() {
    if(_isLoading) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Platform.isAndroid
          ? CircularProgressIndicator(valueColor:AlwaysStoppedAnimation<Color>(Config.DEFAULT_COLOR))
          : const CupertinoActivityIndicator(),
          const SizedBox(height: 15.0),
          Text(
            "Please Wait".tr(),
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      );
    }
      
    if(_notifications.content.isEmpty) {
      return Center(
        child: Text(
          "No Data Found".tr(),
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16.0,
            color: Colors.grey,
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: _notifications.content.length,
      separatorBuilder: (BuildContext context, int index) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.0),
          child: Divider(color: Colors.grey.shade300),
        );
      },
      itemBuilder: (BuildContext context, int index) {
        var notification = _notifications.content[index];
        return GestureDetector(
          onTap: () {
            _onTapItem(index);
          },
          child: Container(
            color: Colors.white,
            margin: const EdgeInsets.only(
              top: 10.0,
              left: 10.0,
              right: 10.0,
            ),
            padding: const EdgeInsets.all(
              7.0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.message,
                  size: 40.0,
                  color: notification.readAt != null 
                        ? Colors.grey 
                        : Config.DEFAULT_COLOR,
                ),
                const SizedBox(width: 15.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${notification.subject}",
                        style: const TextStyle(
                          fontSize: 16.0,
                        ),
                      ),
                      const SizedBox(height: 3.0),
                      Text(
                        DateProvider.convertDateStrReadable(notification.notificationDate),
                        style: const TextStyle(
                          fontSize: 14.0,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      backgroundColor: Config.DEFAULT_COLOR,
      iconTheme: IconThemeData(
        color: Colors.white,
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Notification".tr(),
            style: TextStyle(
              color: Config.DEFAULT_ACCENT_COLOR,
            ),
          ),
          GestureDetector(
            onTap: _moreAction,
            child: Icon(
              Icons.more_vert,
              color: Config.DEFAULT_ACCENT_COLOR,
            ),
          )
        ],
      ),
    );
  }
}
