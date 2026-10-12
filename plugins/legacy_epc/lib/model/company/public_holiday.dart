import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/model/company/holiday_type.dart';
import 'package:epeoplecare/provider/enum_provider.dart';

class PublicHoliday extends BaseModel {
  String date;
  HolidayType? holidayType;
  String description;
  bool scoupe;

  PublicHoliday(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.date,
    this.holidayType,
    this.description,
    this.scoupe,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static PublicHoliday? fromJson(dynamic json) {
    if (json == null) return null;
    
    return PublicHoliday(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      json['date'],
      EnumProvider.fromString(HolidayType.values, json['holiday_type']),
      json['description'],
      json['scoupe'],
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
      "date": date,
      "holiday_type": EnumProvider.convertToString(holidayType),
      "description": description,
      "scoupe": scoupe,
    };
  }
}