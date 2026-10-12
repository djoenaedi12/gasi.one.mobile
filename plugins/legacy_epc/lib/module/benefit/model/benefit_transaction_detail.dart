import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/module/benefit/model/benefit.dart';
import 'package:epeoplecare/module/benefit/model/benefit_transaction.dart';

class BenefitTransactionDetail extends BaseModel {

    BenefitTransaction? benefitTransaction;
    Benefit? benefit;
    String incidentDate;
    double requestedAmount;
    double? approvedAmount;
    double? balance;

    BenefitTransactionDetail(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.benefitTransaction,
    this.benefit,
    this.incidentDate,
    this.requestedAmount,
    this.approvedAmount,
    this.balance,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static BenefitTransactionDetail? fromJson(dynamic json) {
    if (json == null) return null;
    
    return BenefitTransactionDetail(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      BenefitTransaction.fromJson(json['benefit_transaction']),
      Benefit.fromJson(json['benefit']),
      json['incident_date'],
      json['requested_amount'],
      json['approved_amount'],
      json['balance'],
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
      "benefit_transaction": benefitTransaction,
      "benefit": benefit,
      "incident_date": incidentDate,
      "requested_amount": requestedAmount,
      "approved_amount": approvedAmount,
      "balance": balance,
    };
  }
}