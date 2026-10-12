import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/module/leave/model/leave_balance.dart';
import 'package:epeoplecare/module/leave/model/leave_transaction.dart';

class LeaveBalanceHistory extends BaseModel {
  
  LeaveBalance? leaveBalance;
  LeaveTransaction? leaveTransaction;
  double amount;
  String? remark;
  String? transactionDate;

  LeaveBalanceHistory(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.leaveBalance,
    this.leaveTransaction,
    this.amount,
    this.remark,
    this.transactionDate,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static LeaveBalanceHistory? fromJson(dynamic json) {
    if (json == null) return null;
    
    return LeaveBalanceHistory(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      LeaveBalance.fromJson(json['leave_balance']),
      LeaveTransaction.fromJson(json['leave_transaction']),
      json['amount'],
      json['remark'],
      json['transaction_date'],
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
      "leave_balance": leaveBalance,
      "leave_transaction": leaveTransaction,
      "amount": amount,
      "remark": remark,
      "transaction_date": transactionDate,
    };
  }
}