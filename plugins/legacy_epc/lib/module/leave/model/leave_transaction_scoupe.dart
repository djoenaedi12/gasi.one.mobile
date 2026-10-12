import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/module/leave/model/leave_transaction.dart';

class LeaveTransactionScoupe extends BaseModel {
  
  LeaveTransaction? leaveTransaction;
  LeaveTransaction? leaveTransactionScoupe;
  double duration;
  bool scoupe;

  LeaveTransactionScoupe(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.leaveTransaction,
    this.leaveTransactionScoupe,
    this.duration,
    this.scoupe,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static LeaveTransactionScoupe? fromJson(dynamic json) {
    if (json == null) return null;
    
    return LeaveTransactionScoupe(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      LeaveTransaction.fromJson(json['leave_transaction']),
      LeaveTransaction.fromJson(json['leave_transaction_scoupe']),
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
      "leave_transaction_scoupe": leaveTransactionScoupe,
      "duration": duration,
      "scoupe": scoupe,
    };
  }
}