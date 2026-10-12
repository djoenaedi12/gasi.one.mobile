import 'dart:collection';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/model/company/public_holiday.dart';
import 'package:epeoplecare/module/attendance/model/attendance_correction.dart';
import 'package:epeoplecare/module/attendance/model/attendance_status.dart';
import 'package:epeoplecare/module/attendance/model/attendance_transaction.dart';
import 'package:epeoplecare/model/sort.dart';
import 'package:epeoplecare/model/sort_direction.dart';
import 'package:epeoplecare/model/company/schedule.dart';
import 'package:epeoplecare/module/attendance/repository/attendance_correction_repository.dart';
import 'package:epeoplecare/provider/date_provider.dart';
import 'package:epeoplecare/provider/preferences_provider.dart';
import 'package:epeoplecare/provider/storage_provider.dart';
import 'package:epeoplecare/provider/string_provider.dart';
import 'package:epeoplecare/module/attendance/repository/attendance_transaction_repository.dart';
import 'package:epeoplecare/repository/company/public_holiday_repository.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/view/shared/filter_date.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:epeoplecare/model/schedule_shift_generated.dart';
import 'package:epeoplecare/repository/employee/employee_schedule_repository.dart';
import 'package:epeoplecare/model/schedule_generated.dart';
import 'package:epeoplecare/model/company/shift.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class AttendanceRecordPage extends StatefulWidget {
  const AttendanceRecordPage({super.key});

  @override
  State<StatefulWidget>  createState() => _AttendanceRecordPageState();
}

class _AttendanceRecordPageState extends State<AttendanceRecordPage> {
  double _percentagePresent = 0.0;
  double _percentageOnTime = 0.0;
  DateTime _dateFrom = DateProvider.getFirstMidnightCurrentDate();
  DateTime _dateTo = DateProvider.getCurrentDateMidnight();
  Future<String?>? imageName;
  bool animate = false;
  final AttendanceTransactionRepository _attendanceTransactionRepository = Repository().getAttendanceTransactionRepository();
  final PublicHolidayRepository _publicHolidayRepository = Repository().getPublicHolidayRepository();
  final EmployeeScheduleRepository _employeeScheduleRepository = Repository().getEmployeeScheduleRepository();
  final AttendanceCorrectionRepository _attendanceCorrectionRepository = Repository().getAttendanceCorrectionRepository();
  Map<DateTime, List<AttendanceTransaction>> attendanceGroupByDate = HashMap();
  Map<DateTime, PublicHoliday> publicHolidayGroupByDate = HashMap();
  Map<DateTime, Schedule?> scheduleGroupByDate = HashMap();
  Map<DateTime, Shift?> shiftGroupByDate = HashMap();

  @override
  void initState() {
    super.initState();
    _setImage();
    _initData();
  }

  _setImage() {
    imageName = getImageFilePath();
  }

  Future<String?> getImageFilePath() async {
    String path = await StorageProvider().getExternalStorage();
    String fileName = await PreferencesProvider().getSharedPref("image") ?? "";
    if (await File("$path/$fileName").exists()) {
      return "$path/$fileName";
    } else {
      return null;
    }
  }

  _prepareData(DateTime dateFrom, DateTime dateTo) async {
    DateTime dateFromTmp = dateFrom;
    Map<String, dynamic> parameters = HashMap();
    parameters['employee.id'] = Config.user!.employee!.id;
    parameters['attendanceDate.gte'] = DateProvider.convertDate2Str(dateFrom, "yyyy-MM-dd");
    parameters['attendanceDate.lte'] = DateProvider.convertDate2Str(dateTo, "yyyy-MM-dd");
    List<Sort> sorts = [Sort("attendanceDate", SortDirection.DESC)];
    List<AttendanceTransaction> attendanceTransactions = await _attendanceTransactionRepository.list(parameters: parameters, sorts: sorts);
    
    parameters.clear();
    parameters['employee.id'] = Config.user!.employee!.id;
    parameters['attendanceDate.gte'] = DateProvider.convertDate2Str(dateFrom, "yyyy-MM-dd");
    parameters['attendanceDate.lte'] = DateProvider.convertDate2Str(dateTo, "yyyy-MM-dd");
    parameters['workflowStatus'] = "APPROVED";
    List<AttendanceCorrection> attendanceCorrections = await _attendanceCorrectionRepository.list(parameters: parameters, sorts: sorts);

    parameters.clear();
    parameters['date.gte'] = DateProvider.convertDate2Str(dateFrom, "yyyy-MM-dd");
    parameters['date.lte'] = DateProvider.convertDate2Str(dateTo, "yyyy-MM-dd");
    sorts = [Sort("date", SortDirection.DESC)];
    List<PublicHoliday> publicHolidays = await _publicHolidayRepository.list(parameters: parameters, sorts: sorts);
    for (PublicHoliday publicHoliday in publicHolidays) {
      DateTime date = DateProvider.convertStr2Date(publicHoliday.date, "yyyy-MM-dd")!;
      publicHolidayGroupByDate.putIfAbsent(date, () => publicHoliday);
    }

    List<ScheduleShiftGenerated> employeeShiftSchedules = await _employeeScheduleRepository.generateShiftSchedule(Config.user!.employee!, _dateFrom, _dateTo);
    for (ScheduleShiftGenerated employeeShiftSchedule in employeeShiftSchedules) {
      DateTime date = DateProvider.convertStr2Date(employeeShiftSchedule.date, "yyyy-MM-dd")!;
      shiftGroupByDate.putIfAbsent(date, () => employeeShiftSchedule.shift);
    }

    List<ScheduleGenerated> employeeSchedules = await _employeeScheduleRepository.generateSchedule(Config.user!.employee!, _dateFrom, _dateTo);
    for (ScheduleGenerated employeeSchedule in employeeSchedules) {
      DateTime date = DateProvider.convertStr2Date(employeeSchedule.date, "yyyy-MM-dd")!;
      scheduleGroupByDate.putIfAbsent(date, () => employeeSchedule.schedule);
    }

    Duration duration = DateProvider.convertDuration(durationStr: Config.serverTimezone, inverse: true);
    for (AttendanceTransaction att in attendanceTransactions) {
      DateTime attDate = DateProvider.convertStr2Date(att.attendanceRecord, "yyyy-MM-dd HH:mm:ss")!;
      att.attendanceRecord = DateProvider.convertDate2Str(DateProvider.convertToLocal(attDate, duration), "yyyy-MM-dd HH:mm:ss");
    }
    attendanceTransactions.sort((a,b) {
      return DateProvider.convertStr2Date(a.attendanceRecord, "yyyy-MM-dd HH:mm:ss")!.compareTo(DateProvider.convertStr2Date(b.attendanceRecord, "yyyy-MM-dd HH:mm:ss")!);
    });

    attendanceGroupByDate.clear();
    while (dateFromTmp.difference(dateTo).inDays <= 0) {
      attendanceGroupByDate.putIfAbsent(dateFromTmp, () => []);
      dateFromTmp = dateFromTmp.add(const Duration(days: 1));
    }

    for (var attendanceTransaction in attendanceTransactions) {
      DateTime attendanceDate = DateProvider.convertStr2Date(attendanceTransaction.attendanceDate, "yyyy-MM-dd")!;
      if(attendanceGroupByDate.containsKey(attendanceDate)) {
        attendanceGroupByDate[attendanceDate]!.add(attendanceTransaction);
      }
    }

    for (var attendanceCorrection in attendanceCorrections) {
      DateTime attendanceDate = DateProvider.convertStr2Date(attendanceCorrection.attendanceDate, "yyyy-MM-dd")!;
      if(attendanceGroupByDate.containsKey(attendanceDate)) {
        AttendanceTransaction attendanceTransactionIn = AttendanceTransaction(
          null,
          null,
          null,
          null,
          null,
          null,
          BaseModel.getCustomValue(null),
          BaseModel.getMedia(null),
          attendanceCorrection.attendanceDate,
          attendanceCorrection.checkIn,
          null,
          null,
          null,
          AttendanceStatus.CHECK_IN,
          attendanceCorrection.employee,
          null,
          null,
          null,
        );
        AttendanceTransaction attendanceTransactionOut = AttendanceTransaction(
          null,
          null,
          null,
          null,
          null,
          null,
          BaseModel.getCustomValue(null),
          BaseModel.getMedia(null),
          attendanceCorrection.attendanceDate,
          attendanceCorrection.checkOut,
          null,
          null,
          null,
          AttendanceStatus.CHECK_OUT,
          attendanceCorrection.employee,
          null,
          null,
          null,
        );

        attendanceGroupByDate[attendanceDate]!.clear();
        attendanceGroupByDate[attendanceDate]!.add(attendanceTransactionIn);
        attendanceGroupByDate[attendanceDate]!.add(attendanceTransactionOut);
      }
    }
  }

  AttendanceTransaction? _getAttendanceIn(List<AttendanceTransaction> attendances) {
    for (var attendance in attendances) {
      if(attendance.attendanceStatus == AttendanceStatus.CHECK_IN) {
        return attendance;
      }
    } 

    return null;
  }

  AttendanceTransaction? _getAttendanceOut(List<AttendanceTransaction> attendances) {
    AttendanceTransaction? attendanceTransaction;
    for (var attendance in attendances) {
      if(attendance.attendanceStatus == AttendanceStatus.CHECK_OUT) {
        attendanceTransaction = attendance;
      }
    } 

    return attendanceTransaction;
  }

  bool _isPublicHoliday(Schedule? schedule, DateTime date) {
    if((schedule == null || schedule.overridePublicHoliday == false) && publicHolidayGroupByDate.containsKey(date)) {
      return true;
    }

    return false;
  }

  Future<Map<String, double>> getPercentage() async {
    Map<String, double> result = HashMap();
    double totalPresent = 0;
    double totalWorkingDay = 0;
    double totalOnTime = 0;
    double totalLate = 0;
    for (var item in attendanceGroupByDate.entries) {
      AttendanceTransaction? attendanceIn = _getAttendanceIn(item.value);
      AttendanceTransaction? attendanceOut = _getAttendanceOut(item.value);
      Shift? shift = shiftGroupByDate[item.key];
      Schedule? schedule = scheduleGroupByDate[item.key];

      if(shift != null && shift.dayOff == false && !_isPublicHoliday(schedule, item.key)) {
        totalWorkingDay++;
        var workFromTmp = DateProvider.convertStr2Date(shift.scheduleIn, "HH:mm:ss");
        var workToTmp = DateProvider.convertStr2Date(shift.scheduleOut, "HH:mm:ss");
        var workFrom = DateTime(item.key.year, item.key.month, item.key.day, workFromTmp!.hour, workFromTmp.minute, workFromTmp.second);
        var workTo = DateTime(item.key.year, item.key.month, item.key.day, workToTmp!.hour, workToTmp.minute, workToTmp.second);
        if(shift.crossDay) {
          workTo = workTo.add(const Duration(days: 1));
        }

        if(item.value.isNotEmpty) {
          totalPresent++;
          totalOnTime++;
          bool late = false;

          if(attendanceIn != null) {
            var attendanceRecord = DateProvider.convertStr2Date(attendanceIn.attendanceRecord, "yyyy-MM-dd HH:mm:ss");            
            int dispensation = 0;
            if(shift.dispensation == true) {
              dispensation = shift.clockInDispensation!;
            }
            if(attendanceRecord!.difference(workFrom).inMinutes > dispensation) {
              late = true;
            }
          }

          if(attendanceOut != null && !late) {
            var attendanceRecord = DateProvider.convertStr2Date(attendanceOut.attendanceRecord, "yyyy-MM-dd HH:mm:ss");
            int dispensation = 0;
            if(shift.dispensation == true) {
              dispensation = shift.clockOutDispensation!;
            }
            if(attendanceRecord!.difference(workFrom).inMinutes < dispensation) {
              late = true;
            }            
          }

          if(late) {
            totalLate++;
          }
        }
      }
    }

    if(totalWorkingDay == 0) {
      result['present'] = 0.0;
    } else {
      result['present'] = (totalPresent/totalWorkingDay * 100).roundToDouble();
    }
    if(totalOnTime == 0) {
      result['ontime'] = 0.0;
    } else {
      result['ontime'] = 100 - (totalLate/totalOnTime * 100).roundToDouble();
    }
    return result;
  }

  _initData() async {
    EasyLoading.show(status: "Please Wait".tr());
    Map<String, double> result = HashMap();
    await _prepareData(_dateFrom, _dateTo);
    result = await getPercentage();
    setState(() {
      animate = true;
      if(result.containsKey("present")) {
        _percentagePresent = result['present']!;
      }
      if(result.containsKey("ontime")) {
        _percentageOnTime = result['ontime']!;
      }
    });
    EasyLoading.dismiss();
  }

  _filterAttendanceRecord() {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext bc) {
        return FilterDate(
          dateFrom: _dateFrom,
          dateTo: _dateTo,
        );
      }
    ).then((value) async {
      if (value == null) return;
      setState(() {
        _dateFrom = value['dateFrom'];
        _dateTo = value['dateTo'];
      });

      EasyLoading.show(status: "Please Wait".tr());
      Map<String, double> result = HashMap();
      await _prepareData(_dateFrom, _dateTo);
      result = await getPercentage();
      setState(() {
        animate = true;
        if(result.containsKey("present")) {
          _percentagePresent = result['present']!;
        }
        if(result.containsKey("ontime")) {
          _percentageOnTime = result['ontime']!;
        }
      });
      EasyLoading.dismiss();
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Attendance Record".tr(),
                  style: TextStyle(
                    color: Config.DEFAULT_ACCENT_COLOR,
                  ),
                ),
                Text(
                  "${DateProvider.convertDate2Str(_dateFrom, "dd MMM yyyy")} - ${DateProvider.convertDate2Str(_dateTo, "dd MMM yyyy")}",
                  style: TextStyle(
                    fontSize: 12.0,
                    color: Config.DEFAULT_ACCENT_COLOR,
                  ),
                )
              ],
            ),
            GestureDetector(
              onTap: _filterAttendanceRecord,
              child: Icon(
                Icons.calendar_today,
                color: Config.DEFAULT_ACCENT_COLOR,
              ),
            )
          ],
        ),
        elevation: 0.0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Stack(
          children: [
            buildHeader(),
            buildBody(),
          ],
        )
      )
    );
  }

  Widget buildHeader() {
    var mediaQuery = MediaQuery.of(context);
    return Container(
      padding: const EdgeInsets.all(15.0),
      width: mediaQuery.size.width,
      height: 150,
      color: Config.DEFAULT_COLOR,
      child: Column(
        children: [
          Row(
            children: [
              FutureBuilder(
                future: imageName,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return ClipRRect(
                      borderRadius: const BorderRadius.all(
                        Radius.circular(100.0),
                      ),
                      child: Image(
                        height: 75.0,
                        width: 75.0,
                        fit: BoxFit.cover,
                        image: FileImage(File("${snapshot.data}")),
                      ),
                    );
                  } else {
                    return ClipRRect(
                      borderRadius: const BorderRadius.all(
                        Radius.circular(100.0),
                      ),
                      child: Container(
                        height: 75.0,
                        width: 75.0,
                        color: Colors.grey,
                        child: Center(
                          child: Text(
                            StringProvider.getInitials(Config.user!.employee != null ? Config.user!.employee!.name : ""),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 28.0,
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(width: 20.0,),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Config.user!.employee != null ? Config.user!.employee!.name : "",
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.w500,
                        color: Config.DEFAULT_ACCENT_COLOR,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5.0,),
                    Text(
                      Config.user!.employee != null ? Config.user!.employee!.code : "",
                      style: TextStyle(
                        color: Config.DEFAULT_ACCENT_COLOR,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildBody() {
    return Column(
      children: [
        const SizedBox(height: 115.0),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            builGrafik("Present".tr(), "Absent".tr(), _percentagePresent, Config.DEFAULT_COLOR),
            builGrafik("On Time".tr(), "${"Late".tr()} / ${"Early Leave".tr()}", _percentageOnTime, Colors.green),
          ],
        ),
      ],
    );
  }

  Widget builGrafik(
    String indicatorName1,
    String indicatorName2, 
    double percentage,
    Color color,
  ) {
    var mediaQuery = MediaQuery.of(context);
    return Container(
      width: mediaQuery.size.width / 2 - 10,
      padding: const EdgeInsets.all(15.0),
      margin: const EdgeInsets.all(5.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(5),
          topRight: Radius.circular(5),
          bottomLeft: Radius.circular(5),
          bottomRight: Radius.circular(5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10.0,
                height: 10.0,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(50),
                  ),
                ),
              ),
              const SizedBox(width: 5.0),
              Flexible(
                child: Text(
                  indicatorName1,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5.0),
          Row(
            children: [
              Container(
                width: 10.0,
                height: 10.0,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: const BorderRadius.all(
                    Radius.circular(50),
                  ),
                ),
              ),
              const SizedBox(width: 5.0),
              Flexible(
                child: Text(
                  indicatorName2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(
            height: 135.0,
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    startDegreeOffset: 270,
                    sectionsSpace: 0,
                    centerSpaceRadius: 45,
                    sections: [
                      PieChartSectionData(
                        value: percentage,
                        color: color,
                        radius: 7,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: 100 - percentage,
                        color: Colors.grey[300],
                        radius: 7,
                        showTitle: false,                     
                      ),
                    ],
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${percentage.toStringAsFixed(0)}%",
                        style: const TextStyle(
                          fontSize: 28.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 5.0),
                      Text(indicatorName1),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}