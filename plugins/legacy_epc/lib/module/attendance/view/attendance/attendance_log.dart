import 'dart:collection';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/company/public_holiday.dart';
import 'package:epeoplecare/model/company/working_location.dart';
import 'package:epeoplecare/model/sort.dart';
import 'package:epeoplecare/model/sort_direction.dart';
import 'package:epeoplecare/module/attendance/model/attendance_correction.dart';
import 'package:epeoplecare/module/attendance/model/attendance_status.dart';
import 'package:epeoplecare/module/attendance/model/attendance_transaction.dart';
import 'package:epeoplecare/model/schedule_shift_generated.dart';
import 'package:epeoplecare/model/company/shift.dart';
import 'package:epeoplecare/module/attendance/model/flex_hour.dart';
import 'package:epeoplecare/module/attendance/repository/attendance_correction_repository.dart';
import 'package:epeoplecare/module/attendance/repository/flex_hour_repository.dart';
import 'package:epeoplecare/module/attendance/view/attendance/attendance_detail.dart';
import 'package:epeoplecare/module/attendance/view/correction/attendance_correction_application_page.dart';
import 'package:epeoplecare/module/workflow/model/workflow_status.dart';
import 'package:epeoplecare/provider/date_provider.dart';
import 'package:epeoplecare/module/attendance/repository/attendance_transaction_repository.dart';
import 'package:epeoplecare/provider/enum_provider.dart';
import 'package:epeoplecare/repository/company/public_holiday_repository.dart';
import 'package:epeoplecare/repository/employee/employee_schedule_repository.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/view/shared/filter_date.dart';
import 'package:epeoplecare/view/shared/input_form.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class AttendanceLogPage extends StatefulWidget {
  const AttendanceLogPage({super.key});

  @override
  State<StatefulWidget>  createState() => _AttendanceLogPageState();
}

class _AttendanceLogPageState extends State<AttendanceLogPage> {
  // Ubah filter menjadi range date
  // Yang tadinya hanya 1 variable
  // Menjadi 2 _dateFrom & _dateTo
  DateTime _dateFrom = DateProvider.getFirstMidnightCurrentDate();
  DateTime _dateTo = DateProvider.getLastMidnightCurrentDate();
  // Ubah key map dari int menjadi DateTime
  // Karena awalnya 1 bulan jadi tidak mungkin sama day nya
  // Sekarang karena bisa nyebrang bulan kemungkinan sama day nya
  // Jadi key nya diubah menjadi DateTime
  Map<DateTime, List<AttendanceTransaction>> attendanceLogs = HashMap();
  Map<DateTime, Shift?> shifts = HashMap();
  Map<DateTime, PublicHoliday?> publicHolidays = HashMap();
  final EmployeeScheduleRepository _employeeScheduleRepository = Repository().getEmployeeScheduleRepository();
  final AttendanceTransactionRepository _attendanceTransactionRepository = Repository().getAttendanceTransactionRepository();
  final AttendanceCorrectionRepository _attendanceCorrectionRepository = Repository().getAttendanceCorrectionRepository();
  final FlexHourRepository _flexHourRepository = Repository().getFlexHourRepository();
  final PublicHolidayRepository _publicHolidayRepository = Repository().getPublicHolidayRepository();
  bool _initLoad = true;

  @override
  void initState() {
    super.initState();
    _getData();
  }

  _getData({bool isLoader = false}) async {
    if (isLoader) EasyLoading.show(status: "Please Wait".tr());
    if (Config.user!.employee == null) return;

    Map<String, dynamic> parameters = HashMap();
    parameters.putIfAbsent("employee.id", () => Config.user!.employee!.id);
    parameters.putIfAbsent("attendanceDate.gte", () => DateProvider.convertDate2Str(_dateFrom, "yyyy-MM-dd"));
    parameters.putIfAbsent("attendanceDate.lte", () => DateProvider.convertDate2Str(_dateTo, "yyyy-MM-dd"));
    List<AttendanceTransaction> attendanceTransactions = await _attendanceTransactionRepository.list(parameters: parameters);

    parameters.putIfAbsent("workflowStatus", () => EnumProvider.convertToString(WorkflowStatus.APPROVED));
    List<AttendanceCorrection> attendanceCorrections = await _attendanceCorrectionRepository.list(parameters: parameters);

    Duration duration = DateProvider.convertDuration(durationStr: Config.serverTimezone, inverse: true);
    for (AttendanceTransaction att in attendanceTransactions) {
      DateTime attDate = DateProvider.convertStr2Date(att.attendanceRecord, "yyyy-MM-dd HH:mm:ss")!;
      att.attendanceRecord = DateProvider.convertDate2Str(DateProvider.convertToLocal(attDate, duration), "yyyy-MM-dd HH:mm:ss");
    }
    for (AttendanceCorrection att in attendanceCorrections) {
      DateTime checkIn = DateProvider.convertStr2Date(att.checkIn, "yyyy-MM-dd HH:mm:ss")!;
      DateTime checkOut = DateProvider.convertStr2Date(att.checkOut, "yyyy-MM-dd HH:mm:ss")!;
      att.checkIn = DateProvider.convertDate2Str(DateProvider.convertToLocal(checkIn, duration), "yyyy-MM-dd HH:mm:ss");
      att.checkOut = DateProvider.convertDate2Str(DateProvider.convertToLocal(checkOut, duration), "yyyy-MM-dd HH:mm:ss");
    }
    attendanceTransactions.sort((a, b) {
      return DateProvider.convertStr2Date(a.attendanceRecord, "yyyy-MM-dd HH:mm:ss")!.compareTo(DateProvider.convertStr2Date(b.attendanceRecord, "yyyy-MM-dd HH:mm:ss")!);
    });
    attendanceCorrections.sort((a, b) {
      return DateProvider.convertStr2Date(a.attendanceDate, "yyyy-MM-dd")!.compareTo(DateProvider.convertStr2Date(b.attendanceDate, "yyyy-MM-dd")!);
    });

    attendanceLogs.clear();
    shifts.clear();
    DateTime dateFrom = _dateFrom;
    DateTime dateTo = _dateTo;
    List<ScheduleShiftGenerated> employeeSchedules = await _employeeScheduleRepository.generateShiftSchedule(Config.user!.employee!, dateFrom, dateTo);
    for (ScheduleShiftGenerated employeeSchedule in employeeSchedules) {
      DateTime date = DateProvider.convertStr2Date(employeeSchedule.date, "yyyy-MM-dd")!;
      shifts.putIfAbsent(date, () => employeeSchedule.shift);
    }

    List<String> status = [
      EnumProvider.convertToString(WorkflowStatus.APPROVED)!,
    ];
    List<FlexHour> flexHours = await _flexHourRepository.listByEmployeeWorkflowStatusAndDate(Config.user!.employee!, status, dateFrom, dateTo);
    for (var flexHour in flexHours) {
      var effectiveDate = DateProvider.convertStr2Date(flexHour.effectiveDate, "yyyy-MM-dd");
      var expiryDate = DateProvider.convertStr2Date(flexHour.expiryDate, "yyyy-MM-dd");
      if (dateFrom.compareTo(effectiveDate!) >= 0 && (expiryDate == null || dateFrom.compareTo(expiryDate) <= 0)) {
        shifts[dateFrom] = flexHour.shift!;
        break;
      }
    }

    while (dateFrom.difference(dateTo).inDays <= 0) {
      setState(() {
        attendanceLogs.putIfAbsent(dateFrom, () => []);
      });
      dateFrom = dateFrom.add(const Duration(days: 1));
    }

    for (var attendanceTransaction in attendanceTransactions) {
      setState(() {
        if (attendanceLogs.containsKey(DateProvider.convertStr2Date(attendanceTransaction.attendanceDate, "yyyy-MM-dd"))) {
          attendanceLogs[DateProvider.convertStr2Date(attendanceTransaction.attendanceDate, "yyyy-MM-dd")]!.add(attendanceTransaction);
        }
      });
    }

    for (var attendanceCorrection in attendanceCorrections) {
      var key = DateProvider.convertStr2Date(attendanceCorrection.attendanceDate, "yyyy-MM-dd");
      WorkingLocation? wlIn, wlOut;
      if(attendanceLogs.containsKey(key) && attendanceLogs[key] != null) {
        for (AttendanceTransaction attendaceTransaction in attendanceLogs[key]!) {
          if(wlIn == null && attendaceTransaction.attendanceStatus == AttendanceStatus.CHECK_IN) {
            wlIn = attendaceTransaction.workingLocation;
          }
          if(attendaceTransaction.attendanceStatus == AttendanceStatus.CHECK_OUT) {
            wlOut = attendaceTransaction.workingLocation;
          }
        }
      }
      List<AttendanceTransaction> att = [];
      att.add(AttendanceTransaction(null, null, null, null, null, null, null, null, attendanceCorrection.attendanceDate, attendanceCorrection.checkIn, "", "",
          "${attendanceCorrection.requestNo}", AttendanceStatus.CHECK_IN, attendanceCorrection.employee, shifts[key], null, wlIn));
      att.add(AttendanceTransaction(null, null, null, null, null, null, null, null, attendanceCorrection.attendanceDate, attendanceCorrection.checkOut, "", "",
          "${attendanceCorrection.requestNo}", AttendanceStatus.CHECK_OUT, attendanceCorrection.employee, shifts[key], null, wlOut));
      attendanceLogs[key!] = att;
    }

    parameters.clear();
    parameters['date.gte'] = DateProvider.convertDate2Str(_dateFrom, "yyyy-MM-dd");
    parameters['date.lte'] = DateProvider.convertDate2Str(_dateTo, "yyyy-MM-dd");
    List<Sort> sorts = [Sort("date", SortDirection.DESC)];
    List<PublicHoliday> publicHolidaysTmp = await _publicHolidayRepository.list(parameters: parameters, sorts: sorts);

    // Clear data map publicHolidays sebelum diisi lagi dengan data baru
    // Karena yang sekarang ketika pindah bulan data sebelumnya terbawa
    // Data map publicHolidays key nya berdasarkan tanggal
    publicHolidays.clear();
    for (PublicHoliday publicHoliday in publicHolidaysTmp) {
      DateTime date = DateProvider.convertStr2Date(publicHoliday.date, "yyyy-MM-dd")!;
      publicHolidays.putIfAbsent(date, () => publicHoliday);
    }

    if (isLoader) EasyLoading.dismiss();
    setState(() {
      _initLoad = false;
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Attendance Log".tr(),
                  style: TextStyle(color: Config.DEFAULT_ACCENT_COLOR),
                ),
                Text(
                  "${DateProvider.convertDate2Str(_dateFrom, "dd MMM yyyy")} - ${DateProvider.convertDate2Str(_dateTo, "dd MMM yyyy")}",
                  style: TextStyle(fontSize: 12.0, color: Config.DEFAULT_ACCENT_COLOR),
                ),
              ],
            ),
          ],
        ),
      ),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: 10.0,
                  right: 10.0,
                  bottom: 10.0,
                ),
                child: InputForm().renderButton(
                    text: "Correction".tr(),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AttendanceCorrectionApplicationPage(),
                        ),
                      );
                    }),
              ),
              Expanded(
                child: _initLoad
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Platform.isAndroid ? CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Config.DEFAULT_COLOR)) : const CupertinoActivityIndicator(),
                          const SizedBox(height: 15.0),
                          Text(
                            "Please Wait".tr(),
                            style: const TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      )
                    : buildDate(),
              )
            ],
          ),

          // Menambahkan widget untuk filter
          // Posisi fixed
          buildFilter(context),
        ],
      ),
    );
  }

  // Buat widget untuk filter 
  Widget buildFilter(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Positioned(
      bottom: 30.0,
      left: (size.width / 2) - 50,
      child: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            isScrollControlled: true,
            context: context,
            builder: (BuildContext bc) {
              return FilterDate(
                dateFrom: _dateFrom,
                dateTo: _dateTo,
                maxDateRange: 60,
              );
            }
          ).then((value) async {
            if (value == null) return;
            setState(() {
              _dateFrom = value['dateFrom'];
              _dateTo = value['dateTo'];
              _getData(
                isLoader: true,
              );
            });
          });
        },
        child: Container(
          padding: const EdgeInsets.all(5.0),
          width: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.all(
              Radius.circular(
                30.0,
              )
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  Icon(
                    Icons.filter_list_alt,
                    color: Config.DEFAULT_COLOR,
                  ),
                  Visibility(
                    visible: true,
                    child: Positioned(
                      top: 2.0,
                      right: 0.0,
                      child: Container(
                        width: 9.0,
                        height: 9.0,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 5.0),
              Text(
                "Filter".tr(),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget buildDate() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: attendanceLogs.entries.length,
      itemBuilder: (BuildContext context, int index) {
        DateTime now = DateTime.now();
        DateTime currentDate = DateTime(now.year, now.month, now.day);
        DateTime calendarDate = DateTime(_dateFrom.year, _dateFrom.month, _dateFrom.day + index);
        List<AttendanceTransaction> attendanceTransactions = attendanceLogs[calendarDate] ?? [];
        bool currentDay = false;
        if (currentDate.compareTo(calendarDate) == 0) {
          currentDay = true;
        }
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 75.0,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border(
                    left: BorderSide(
                      color: currentDay ? Config.DEFAULT_COLOR : Colors.transparent,
                      width: 2,
                    )
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      DateProvider.convertDate2Str(calendarDate, "dd MMM"),
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(
                      height: 3.0,
                    ),
                    Text(
                      DateProvider.convertDate2Str(_dateFrom.add(Duration(days: index)), "EEE"),
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                width: 30.0,
              ),
              buildAttendanceLog(attendanceTransactions, calendarDate),
            ],
          ),
        );
      },
    );
  }

  _getScheduleName(DateTime date) {
    String scheduleName = shifts.containsKey(date) && shifts[date] != null ? shifts[date]!.name : "No Schedule".tr();
    if(publicHolidays.containsKey(date)) {
      scheduleName += " - ${publicHolidays[date]!.description}";
    }
    return scheduleName;
  }

  Widget buildAttendanceLog(List<AttendanceTransaction> attendanceTransactions, DateTime date) {
    var mediaQuery = MediaQuery.of(context);
    return Expanded(
        child: attendanceTransactions.isNotEmpty
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getScheduleName(date),
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: publicHolidays.containsKey(date) || (shifts.containsKey(date) && shifts[date]!.dayOff) ? Colors.red : Colors.black,
                    ),
                  ),
                  const SizedBox(
                    height: 10.0,
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: attendanceTransactions.length,
                    itemBuilder: (BuildContext bc, int index2) {
                      AttendanceTransaction attendanceTransaction = attendanceTransactions[index2];
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 5.0),
                        width: mediaQuery.size.width - 90.0,
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AttendanceDetailPage(
                                      attendanceTransaction: attendanceTransaction,
                                    ),
                                  ),
                                );
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        DateProvider.convertDateStrFormat(attendanceTransaction.attendanceRecord, "yyyy-MM-dd HH:mm:ss", "HH:mm:ss"),
                                        style: TextStyle(
                                          color: attendanceTransaction.attendanceStatus == AttendanceStatus.CHECK_IN ? Config.DEFAULT_COLOR : Colors.red,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 15.0,
                                      ),
                                      Text(
                                        (attendanceTransaction.attendanceStatus == AttendanceStatus.CHECK_IN ? "Check In" : "Check Out").tr(),
                                        style: TextStyle(
                                          color: attendanceTransaction.attendanceStatus == AttendanceStatus.CHECK_IN ? Config.DEFAULT_COLOR : Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: Colors.grey[400],
                                  ),
                                ],
                              ),
                            ),
                            Divider(color: Colors.grey.shade300),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getScheduleName(date),
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: publicHolidays.containsKey(date) || (shifts.containsKey(date) && shifts[date]!.dayOff) ? Colors.red : Colors.black,
                    ),
                  ),
                  const SizedBox(
                    height: 15.0,
                  ),
                  Divider(color: Colors.grey.shade300),
                ],
              ));
  }
}
