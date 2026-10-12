import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/module/benefit/model/benefit_balance.dart';
import 'package:epeoplecare/module/benefit/model/benefit_transaction.dart';

class BenefitBalanceHistory extends BaseModel {
  
  BenefitBalance? benefitBalance;
  BenefitTransaction? benefitTransaction;
  double amount;
  String? remark;

  BenefitBalanceHistory(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.benefitBalance,
    this.benefitTransaction,
    this.amount,
    this.remark,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static BenefitBalanceHistory? fromJson(dynamic json) {
    if (json == null) return null;
    
    return BenefitBalanceHistory(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      BenefitBalance.fromJson(json['benefit_balance']),
      BenefitTransaction.fromJson(json['benefit_transaction']),
      json['amount'],
      json['remark'],
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
      "benefit_balance": benefitBalance,
      "benefit_transaction": benefitTransaction,
      "amount": amount,
      "remark": remark,
    };
  }
}