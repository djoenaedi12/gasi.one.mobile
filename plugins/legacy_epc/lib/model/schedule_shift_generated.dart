import 'package:epeoplecare/model/company/shift.dart';
class ScheduleShiftGenerated {

  String date;
  Shift? shift;

  ScheduleShiftGenerated(
    this.date,
    this.shift,
  );

  static ScheduleShiftGenerated? fromJson(dynamic json) {
    if (json == null) return null;

    return ScheduleShiftGenerated(
      json['date'],
      Shift.fromJson(json['shift']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "date": date,
      "shift": shift,
    };
  }

}