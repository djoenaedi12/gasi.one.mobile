import 'package:epeoplecare/model/company/working_location.dart';
import 'package:epeoplecare/module/attendance/model/attendance_status.dart';
import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/model/company/shift.dart';
import 'package:epeoplecare/provider/enum_provider.dart';

class AttendanceTransaction extends BaseModel {
  String attendanceDate;
  String attendanceRecord;
  String? location;
  String? locationStr;
  String? remark;
  AttendanceStatus? attendanceStatus;
  Employee? employee;
  Shift? shift;
  String? attachment;
  WorkingLocation? workingLocation;

  AttendanceTransaction(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.attendanceDate,
    this.attendanceRecord,
    this.location,
    this.locationStr,
    this.remark,
    this.attendanceStatus,
    this.employee,
    this.shift,
    this.attachment,
    this.workingLocation,
  ) : super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static AttendanceTransaction? fromJson(dynamic json) {
    if (json == null) return null;

    return AttendanceTransaction(
        json['id'],
        json['creator'],
        json['creation_time'],
        json['updater'],
        json['update_time'],
        json['version'],
        BaseModel.getCustomValue(json),
        BaseModel.getMedia(json),
        json['attendance_date'],
        json['attendance_record'],
        json['location'],
        json['location_str'],
        json['remark'],
        EnumProvider.fromString(AttendanceStatus.values, json['attendance_status']),
        Employee.fromJson(json['employee']),
        Shift.fromJson(json['shift']),
        json['attachment'],
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
      "attendance_date": attendanceDate,
      "attendance_record": attendanceRecord,
      "location": location,
      "location_str": locationStr,
      "remark": remark,
      "attendance_status": EnumProvider.convertToString(attendanceStatus),
      "employee": employee,
      "shift": shift,
      "attachment": attachment,
      "working_location": workingLocation,
    };
  }
}
