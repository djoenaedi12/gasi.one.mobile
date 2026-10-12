import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/model/company/public_holiday.dart';
import 'package:epeoplecare/module/leave/model/leave_transaction.dart';

class LeaveTransactionScoupePublicHoliday extends BaseModel {
  
  LeaveTransaction? leaveTransaction;
  PublicHoliday? publicHoliday;
  double duration;
  bool scoupe;

  LeaveTransactionScoupePublicHoliday(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.leaveTransaction,
    this.publicHoliday,
    this.duration,
    this.scoupe,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static LeaveTransactionScoupePublicHoliday? fromJson(dynamic json) {
    if (json == null) return null;
    
    return LeaveTransactionScoupePublicHoliday(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      LeaveTransaction.fromJson(json['leave_transaction']),
      PublicHoliday.fromJson(json['public_holiday']),
      json['duration'],
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
      "leave_transaction": leaveTransaction,
      "public_holiday": publicHoliday,
      "duration": duration,
      "scoupe": scoupe,
    };
  }
}