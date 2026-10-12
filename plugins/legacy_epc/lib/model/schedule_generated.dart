import 'package:epeoplecare/model/company/schedule.dart';
class ScheduleGenerated {

  String date;
  Schedule? schedule;

  ScheduleGenerated(
    this.date,
    this.schedule,
  );

  static ScheduleGenerated? fromJson(dynamic json) {
    if (json == null) return null;

    return ScheduleGenerated(
      json['date'],
      Schedule.fromJson(json['schedule']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "date": date,
      "schedule": schedule,
    };
  }

}