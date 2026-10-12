import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/model/company/working_location.dart';

class Shift extends BaseModel {
  String name;
  bool dayOff;
  bool showInRequest;
  String? scheduleIn;
  String? scheduleOut;
  bool crossDay;
  String? breakStart;
  String? breakEnd;
  bool dispensation;
  int? clockInDispensation;
  int? clockOutDispensation;
  bool autoOvertime;
  String? overtimeBefore;
  String? overtimeAfter;
  bool additionalBreak;
  bool shiftValidation;
  WorkingLocation? workingLocation;

  Shift(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.name,
    this.dayOff,
    this.showInRequest,
    this.scheduleIn,
    this.scheduleOut,
    this.crossDay,
    this.breakStart,
    this.breakEnd,
    this.dispensation,
    this.clockInDispensation,
    this.clockOutDispensation,
    this.autoOvertime,
    this.overtimeBefore,
    this.overtimeAfter,
    this.additionalBreak,
    this.shiftValidation,
    this.workingLocation,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static Shift? fromJson(dynamic json) {
    if (json == null) return null;
    
    return Shift(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      json['name'],
      json['day_off'],
      json['show_in_request'],
      json['schedule_in'],
      json['schedule_out'],
      json['cross_day'],
      json['break_start'],
      json['break_end'],
      json['dispensation'],
      json['clock_in_dispensation'],
      json['clock_out_dispensation'],
      json['auto_overtime'],
      json['overtime_before'],
      json['overtime_after'],
      json['additional_break'],
      json['shift_validation'],
      WorkingLocation.fromJson(json['working_location']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "creator": creator,
      "creation_time": creationTime,
      "updater": updater,
      "update_time": updateTime,
      "version": version,
      "custom_values": customValues,
      "medias": medias,
      "name": name,
      "day_off": dayOff,
      "show_in_request": showInRequest,
      "schedule_in": scheduleIn,
      "schedule_out": scheduleOut,
      "cross_day": crossDay,
      "break_start": breakStart,
      "break_end": breakEnd,
      "dispensation": dispensation,
      "clock_in_dispensation": clockInDispensation,
      "clock_out_dispensation": clockOutDispensation,
      "auto_overtime": autoOvertime,
      "overtime_before": overtimeBefore,
      "overtime_after": overtimeAfter,
      "additional_break": additionalBreak,
      "shift_validation": shiftValidation,
      "working_location": workingLocation,
    };
  }
}