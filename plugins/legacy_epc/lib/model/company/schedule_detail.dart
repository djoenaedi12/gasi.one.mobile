import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/model/company/shift.dart';

class ScheduleDetail extends BaseModel {
  Shift? shift;
  int sequence;

  ScheduleDetail(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.shift,
    this.sequence,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static ScheduleDetail? fromJson(dynamic json) {
    if (json == null) return null;
    
    return ScheduleDetail(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      Shift.fromJson(json['shift']),
      json['sequence'],
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
      "shift": shift,
      "sequence": sequence,
    };
  }
}