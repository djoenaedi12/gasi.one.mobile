import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/model/company/currency.dart';
import 'package:epeoplecare/module/businesstrip/model/allowance.dart';
import 'package:epeoplecare/module/businesstrip/model/business_trip_request_detail.dart';

class BusinessTripRequestAllowance extends BaseModel {
  
  BusinessTripRequestDetail? businessTripRequestDetail;
  String date;
  Allowance? allowance;
  Currency? currency;
  double allowanceAmount;
  double? actualAmount;
  double? paidAmount;
  String? remark;
  bool asClaimed;
  bool beyondLimit;
  bool additionalClaim;
  double? dedcutionAmount;
  bool editable;

  BusinessTripRequestAllowance(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.businessTripRequestDetail,
    this.date,
    this.allowance,
    this.currency,
    this.allowanceAmount,
    this.actualAmount,
    this.paidAmount,
    this.remark,
    this.asClaimed,
    this.beyondLimit,
    this.additionalClaim,
    this.dedcutionAmount,
    this.editable,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static BusinessTripRequestAllowance? fromJson(dynamic json) {
    if (json == null) return null;
    
    return BusinessTripRequestAllowance(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      BusinessTripRequestDetail.fromJson(json['business_trip_request_detail']),
      json['date'],
      Allowance.fromJson(json['allowance']),
      Currency.fromJson(json['currency']),
      json['allowance_amount'],
      json['actual_amount'],
      json['paid_amount'],
      json['remark'],
      json['as_claimed'],
      json['beyond_limit'],
      json['additional_claim'],
      json['deduction_amount'],
      json['editable'],
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
      "business_trip_request_detail": businessTripRequestDetail,
      "date": date,
      "allowance": allowance,
      "currency": currency,
      "allowance_amount": allowanceAmount,
      "actual_amount": actualAmount,
      "paid_amount": paidAmount,
      "remark": remark,
      "as_claimed": asClaimed,
      "beyond_limit": beyondLimit,
      "additional_claim": additionalClaim,
      "deduction_amount": dedcutionAmount,
      "editable": editable,
    };
  }
}