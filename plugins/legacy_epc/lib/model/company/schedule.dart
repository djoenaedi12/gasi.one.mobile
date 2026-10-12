import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/model/company/schedule_detail.dart';

class Schedule extends BaseModel {
  String name;
  bool asDefault;
  String effectiveDate;
  bool overridePublicHoliday;
  bool overrideCompanyHoliday;
  List<ScheduleDetail> scheduleDetails = []; 

  Schedule(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.name,
    this.asDefault,
    this.effectiveDate,
    this.overridePublicHoliday,
    this.overrideCompanyHoliday,
    this.scheduleDetails,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static Schedule? fromJson(dynamic json) {
    if (json == null) return null;

    List<ScheduleDetail> scheduleDetails = [];
    if(json['schedule_details'] != null) {
      for (var i = 0; i < json['schedule_details'].length; i++) {
        ScheduleDetail? scheduleDetail = ScheduleDetail.fromJson(json['schedule_details'][i]);
        if(scheduleDetail != null) {
          scheduleDetails.add(scheduleDetail);
        }
      }
    }
    
    return Schedule(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      json['name'],
      json['as_default'],
      json['effective_date'],
      json['override_public_holiday'],
      json['override_company_holiday'],
      scheduleDetails,
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
      "as_default": asDefault,
      "effective_date": effectiveDate,
      "override_public_holiday": overridePublicHoliday,
      "override_company_holiday": overrideCompanyHoliday,
      "schedule_details": scheduleDetails,
    };
  }
}