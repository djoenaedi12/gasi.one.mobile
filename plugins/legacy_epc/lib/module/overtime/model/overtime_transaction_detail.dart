import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/module/overtime/model/overtime_transaction.dart';

class OvertimeTransactionDetail extends BaseModel {
  
  OvertimeTransaction? overtimeTransaction;
  String startDate;
  String endDate;
  double duration;
  double? breakDuration;

  OvertimeTransactionDetail(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.overtimeTransaction,
    this.startDate,
    this.endDate,
    this.duration,
    this.breakDuration,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static OvertimeTransactionDetail? fromJson(dynamic json) {
    if (json == null) return null;
    
    return OvertimeTransactionDetail(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      OvertimeTransaction.fromJson(json['overtime_transaction']),
      json['start_date'],
      json['end_date'],
      json['duration'],
      json['break_duration'],
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
      "overtime_transaction": overtimeTransaction,
      "start_date": startDate,
      "end_date": endDate,
      "duration": duration,
      "break_duration": breakDuration,
    };
  }
}