
import 'package:epeoplecare/module/attendance/model/attendance_transaction.dart';
import 'package:flutter/material.dart';

class ScreenArgument {
  String title;
  AttendanceTransaction? attendanceTransaction;
  IconData? icon;

  ScreenArgument(
    this.title,
    this.icon,
    this.attendanceTransaction
  );
}
