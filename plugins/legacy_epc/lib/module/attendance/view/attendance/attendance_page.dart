import 'dart:async';
import 'dart:collection';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/module.dart';
import 'package:epeoplecare/module/attendance/model/attendance_status.dart';
import 'package:epeoplecare/module/attendance/model/attendance_transaction.dart';
import 'package:epeoplecare/module/attendance/view/attendance/attendance_checkinout.dart';
import 'package:epeoplecare/module/attendance/view/attendance/attendance_detail.dart';
import 'package:epeoplecare/module/attendance/view/attendance/attendance_log.dart';
import 'package:epeoplecare/module/attendance/view/attendance/attendance_record.dart';
import 'package:epeoplecare/provider/date_provider.dart';
import 'package:epeoplecare/module/attendance/repository/attendance_transaction_repository.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class AttendancePage extends StatefulWidget {
  final AttendanceTransaction? attendanceTransaction;
  final String title;
  final IconData? icon;
  const AttendancePage({Key? key, this.attendanceTransaction, this.title="", this.icon}) : super(key: key);
  @override
  State<StatefulWidget> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  String _currentTime = "";
  String _currentDate = "";
  Timer? _timer;
  Map<DateTime, bool> _isLoading = HashMap();
  Map<DateTime, AttendanceTransaction?> _attendanceTransaction = HashMap();
  Map<DateTime, List<AttendanceTransaction>> _attendanceTransactionHistory = HashMap();
  final AttendanceTransactionRepository _attendanceTransactionRepository = Repository().getAttendanceTransactionRepository();
  List<Module> menuModules = [];
  List<DateTime> attendances = [DateProvider.getCurrentDateMidnight()];
  int current = 0;

  @override
  void initState() {
    super.initState();
    _attendanceTransaction[DateProvider.getCurrentDateMidnight()] = widget.attendanceTransaction;
    _initData();
    menuModules = Config.getMenuOthers("/module/attendance", context);
  }

  _initData() {
    _isLoading[attendances[0]] = true;
    _getLastAttendance(attendances[0]);
    _getAttendanceHistory(attendances[0]);
    _getPrevAttendance();
    final DateTime now = DateTime.now();
    _currentTime = DateProvider.convertDate2Str(now, "HH:mm");
    _currentDate = DateProvider.convertDate2Str(now, "EEEE, dd MMMM yyyy");
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _getCurrentTime());
  }

  _getLastAttendance(DateTime date) {
    if(Config.user!.employee == null) return;
    _attendanceTransactionRepository.getLastByEmployee(Config.user!.employee!, date).then((value) {
      setState(() {
        _attendanceTransaction[date] = value;
      });
    });
  }

  _getPrevAttendance() {
  _attendanceTransactionRepository.getPrevByEmployee(Config.user!.employee!, DateProvider.getCurrentDateMidnight()).then((value) {
      if(value != null) {
        setState(() {     
          DateTime? date = DateProvider.convertStr2Date(value.attendanceDate, "yyyy-MM-dd");
          if(date != null) {
            attendances.add(date);

            _getLastAttendance(attendances[1]);
            _getAttendanceHistory(attendances[1]);
          }
        });
      }
    });
  }

  _getAttendanceHistory(DateTime date) async {
    if(Config.user!.employee == null) return;

    setState(() {
      _isLoading[date] = true;
    });

    if(_attendanceTransactionHistory.containsKey(date)) {
      _attendanceTransactionHistory[date]!.clear();
    }
    Map<String, dynamic> parameters = HashMap();
    parameters.putIfAbsent("employee", () => Config.user!.employee!.id);
    parameters.putIfAbsent("attendanceDate", () => DateProvider.convertDate2Str(date, "yyyy-MM-dd"));
    _attendanceTransactionRepository.list(parameters: parameters).then((value) {
      setState(() {
        _isLoading[date] = false;
        Duration duration = DateProvider.convertDuration(durationStr: Config.serverTimezone, inverse: true);
        for (AttendanceTransaction att in value) {
          DateTime attDate = DateProvider.convertStr2Date(att.attendanceRecord, "yyyy-MM-dd HH:mm:ss")!;
          att.attendanceRecord = DateProvider.convertDate2Str(DateProvider.convertToLocal(attDate, duration), "yyyy-MM-dd HH:mm:ss");
        }
        _attendanceTransactionHistory[date] = value;
      });
    });
  }

  @override
  void dispose() {
    _timer!.cancel();
    super.dispose();
  }

  void _getCurrentTime() {
    final DateTime now = DateTime.now();
    setState(() {
      _currentTime = DateProvider.convertDate2Str(now, "HH:mm");
      _currentDate = DateProvider.convertDate2Str(now, "EEEE, dd MMMM yyyy");
    });
  }

  _checkInOut(DateTime date, int index) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext bc){
        return  SingleChildScrollView(
          child: AttendanceCheckInOut(
            attendanceTransaction: _attendanceTransaction[date],
            attendanceDate: date,
            isCurrentDate: index == 0,
          )
        );
      },
    ).then((value) {
      if(value == null) return;

      _getLastAttendance(date);
      _getAttendanceHistory(date);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Config.DEFAULT_COLOR,
        iconTheme: IconThemeData(
          color: Config.DEFAULT_ACCENT_COLOR,
        ),
        elevation: 0.0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.title,
              style: TextStyle(
                color: Config.DEFAULT_ACCENT_COLOR,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AttendanceRecordPage(),
                  ),
                );
              },
              child: Icon(
                Icons.poll,
                color: Config.DEFAULT_ACCENT_COLOR,
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            buildDateTime(),
            buildAttendances(),
            buildOthers(),
          ],
        ),
      ),
    );
  }

  Widget buildDateTime() {
    var mediaQuery = MediaQuery.of(context);
    return Container(
      padding: const EdgeInsets.only(
        top: 20.0,
        bottom: 20.0,
      ),
      margin: const EdgeInsets.only(bottom: 10.0),
      color: Config.DEFAULT_COLOR,
      width: mediaQuery.size.width,
      child: Column(
        children: [
          Text(
            _currentTime,
            style: TextStyle(
              color: Config.DEFAULT_ACCENT_COLOR,
              fontSize: 50.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(
            height: 10.0,
          ),
          Text(
            _currentDate,
            style: TextStyle(
              color: Config.DEFAULT_ACCENT_COLOR,
              fontSize: 18.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildButtonCheckInOut(DateTime date, int index) {
    return GestureDetector(
      onTap: () {
        _checkInOut(date, index);
      },
      child: (_attendanceTransaction.containsKey(date) &&  _attendanceTransaction[date] != null && _attendanceTransaction[date]!.attendanceStatus == AttendanceStatus.CHECK_IN ?
        Icon(
          Icons.logout_outlined,
          size: 125,
          color: Config.SEMANTIC_COLOR_DANGER,
        ) :
        Icon(
          Icons.login_outlined, 
          size: 125,
          color: Config.SEMANTIC_COLOR_SUCCESS,
        )
      ),
    );
  }

  Widget builLogAttendance(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 15.0,
        horizontal: 15.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "${"Attendance Log".tr()} (${DateProvider.convertDate2Str(date, "dd MMM yyyy")})",
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16.0,
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AttendanceLogPage(),
                ),
              );
            },
            child: Text(
              "View All".tr(),
              style: const TextStyle(
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAttendanceHistory(DateTime date) {
    var mediaQuery = MediaQuery.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 10.0, 
        horizontal: 15.0,
      ),
      child: ListView.separated(              
        shrinkWrap: true,
        itemCount: !_isLoading.containsKey(date) || _isLoading[date] == true ? 3 : _attendanceTransactionHistory.containsKey(date) ? _attendanceTransactionHistory[date]!.length : 0,
        separatorBuilder: (context, index) {
          if(!_isLoading.containsKey(date) || _isLoading[date] == true) {
            return const SizedBox(height: 10.0);
          }
          return Divider(height: 30.0, color: Colors.grey.shade300);
        },
        itemBuilder: (context, index) {
          if(!_isLoading.containsKey(date) || _isLoading[date] == true) {
            return Shimmer.fromColors(
              baseColor: Colors.grey.shade200,
              highlightColor: Colors.grey.shade100,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20.0,
                    height: 20.0,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(
                        Radius.circular(50),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 10.0,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: mediaQuery.size.width / 2,
                        height: 15.0,
                        color: Colors.white,
                      ),
                      const SizedBox(
                        height: 5.0,
                      ),
                      Container(
                        width: mediaQuery.size.width - 80,
                        height: 40.0,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
          AttendanceTransaction att = _attendanceTransactionHistory[date]![index];
          return InkWell(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AttendanceDetailPage(
                    attendanceTransaction: att,
                  ),
                ),
              );
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 20.0,
                      height: 20.0,
                      decoration: BoxDecoration(
                        color: att.attendanceStatus == AttendanceStatus.CHECK_IN ? Config.DEFAULT_COLOR : Colors.red,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(50),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 10.0,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "${(att.attendanceStatus == AttendanceStatus.CHECK_IN ? "Check In" : "Check Out").tr()} at ${DateProvider.convertDateStrFormat(att.attendanceRecord, "yyyy-MM-dd HH:mm:ss", "HH:mm:ss")}",
                          style: const TextStyle(
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildShimmer() {
    var mediaQuery = MediaQuery.of(context);
    return Visibility(
      visible: false,
        child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          width: mediaQuery.size.width,
          height: 100.0,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget buildOthers() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 15.0,
        horizontal: 15.0,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                "Others".tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          SizedBox(
            height: 100.0,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: menuModules.length,
              itemBuilder: (BuildContext context, int index) {
                return GestureDetector(
                  onTap: menuModules[index].onTap,
                  child: SizedBox(
                    width: 100.0,
                    child: Card(
                      color: Colors.white,
                      elevation: 1.5,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 5.0),
                        child: Column(
                          children: [
                            Icon(
                              menuModules[index].icon,
                              size: 45.0,
                              color: Config.DEFAULT_COLOR,
                            ),
                            const SizedBox(
                              height: 5.0,
                            ),
                            Text(
                              menuModules[index].title,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
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
        ],
      ),
    );
  }

  Widget buildAttendances() {
    var mediaQuery = MediaQuery.of(context);

    return Column(
      children: <Widget>[
        SizedBox(
          height: 304.0,
          child: PageView.builder(
            onPageChanged: (int index) {
              setState(() {
                current = index;
              });
            },
            scrollDirection: Axis.horizontal,
            itemCount: attendances.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      const SizedBox(height: 10),
                      buildButtonCheckInOut(attendances[index], index),
                      const SizedBox(height: 10),
                      builLogAttendance(attendances[index]),
                      SizedBox(
                        height: 100.0,
                        child: buildAttendanceHistory(attendances[index]),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 8,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: attendances.length,
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
