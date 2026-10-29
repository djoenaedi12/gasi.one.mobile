import 'package:flutter/material.dart';

import 'package:epeoplecare/model/screen_argument.dart';
import 'package:epeoplecare/module/attendance/view/attendance/attendance_page.dart';
import 'package:epeoplecare/module/attendance/view/correction/attendance_correction_page.dart';
import 'package:epeoplecare/module/attendance/view/flex_hour/flex_hour_page.dart';
import 'package:epeoplecare/module/attendance/view/wfh/work_from_home_page.dart';
import 'package:epeoplecare/module/benefit/view/benefit_page.dart';
import 'package:epeoplecare/module/businesstrip/view/business_trip_page.dart';
import 'package:epeoplecare/module/cashadvance/view/ca_page.dart';
import 'package:epeoplecare/module/cashadvance/view/settlement/ca_settlement_page.dart';
import 'package:epeoplecare/module/leave/view/calendar/calendar_page.dart';
import 'package:epeoplecare/module/leave/view/leave/leave_page.dart';
import 'package:epeoplecare/module/leave/view/whereabout/whereabout_page.dart';
import 'package:epeoplecare/module/letter/view/letter_page.dart';
import 'package:epeoplecare/module/loan/view/change/loan_change_page.dart';
import 'package:epeoplecare/module/loan/view/loan_page.dart';
import 'package:epeoplecare/module/overtime/view/overtime/overtime_page.dart';
import 'package:epeoplecare/module/payroll/view/payroll/payroll_page.dart';
import 'package:epeoplecare/module/task/view/task_page.dart';

/// Routes still owned by EPC business modules.
/// TRANSITION[LEGACY-ROUTES]: remove each route after its plugin owns it, then
/// remove this factory once no legacy route remains.
Route<dynamic>? buildLegacyRoute(RouteSettings settings) {
  var screenArg = ScreenArgument("", null, null);
  if (settings.arguments != null) {
    screenArg = settings.arguments as ScreenArgument;
  }
  switch (settings.name) {
    case "/module/attendance":
      return MaterialPageRoute(
        builder: (context) => AttendancePage(
          title: screenArg.title,
          icon: screenArg.icon,
          attendanceTransaction: screenArg.attendanceTransaction,
        ),
      );
    case "/module/attendance/correction":
      return MaterialPageRoute(
        builder: (context) => AttendanceCorrectionPage(
          title: screenArg.title,
          icon: screenArg.icon,
        ),
      );
    case "/module/attendance/flex-hour":
      return MaterialPageRoute(
        builder: (context) =>
            FlexHourPage(title: screenArg.title, icon: screenArg.icon),
      );
    case "/module/attendance/wfh":
      return MaterialPageRoute(
        builder: (context) =>
            WorkFromHomePage(title: screenArg.title, icon: screenArg.icon),
      );
    case "/module/leave":
      return MaterialPageRoute(
        builder: (context) =>
            LeavePage(title: screenArg.title, icon: screenArg.icon),
      );
    case "/module/leave/whereabout":
      return MaterialPageRoute(
        builder: (context) =>
            WhereaboutPage(title: screenArg.title, icon: screenArg.icon),
      );
    case "/module/leave/calendar":
      return MaterialPageRoute(
        builder: (context) =>
            CalendarPage(title: screenArg.title, icon: screenArg.icon),
      );
    case "/module/overtime":
      return MaterialPageRoute(
        builder: (context) =>
            OvertimePage(title: screenArg.title, icon: screenArg.icon),
      );
    case "/module/payroll":
      return MaterialPageRoute(
        builder: (context) =>
            PayrollPage(title: screenArg.title, icon: screenArg.icon),
      );
    case "/module/businesstrip":
      return MaterialPageRoute(
        builder: (context) =>
            BusinessTripPage(title: screenArg.title, icon: screenArg.icon),
      );
    case "/module/loan":
      return MaterialPageRoute(
        builder: (context) =>
            LoanPage(title: screenArg.title, icon: screenArg.icon),
      );
    case "/module/loan/change":
      return MaterialPageRoute(
        builder: (context) =>
            LoanChangePage(title: screenArg.title, icon: screenArg.icon),
      );
    case "/module/letter":
      return MaterialPageRoute(
        builder: (context) =>
            LetterPage(title: screenArg.title, icon: screenArg.icon),
      );
    case "/module/benefit":
      return MaterialPageRoute(
        builder: (context) =>
            BenefitPage(title: screenArg.title, icon: screenArg.icon),
      );
    case "/module/cashadvance":
      return MaterialPageRoute(
        builder: (context) =>
            CAPage(title: screenArg.title, icon: screenArg.icon),
      );
    case "/module/cashadvance/settlement":
      return MaterialPageRoute(
        builder: (context) =>
            CASettlementPage(title: screenArg.title, icon: screenArg.icon),
      );
    case "/module/task":
      return MaterialPageRoute(
        builder: (context) =>
            TaskPage(title: screenArg.title, icon: screenArg.icon),
      );
    default:
      return null;
  }
}
