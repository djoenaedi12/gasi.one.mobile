import 'package:epeoplecare/model/company/attribute.dart';
import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/model/company/currency.dart';
import 'package:epeoplecare/module/businesstrip/model/allowance.dart';
import 'package:epeoplecare/module/businesstrip/model/destination.dart';
import 'package:epeoplecare/module/businesstrip/model/purpose.dart';

class AllowanceMapping extends BaseModel {
  
  Attribute? attribute;
  Purpose? purpose;
  Destination? destination;
  Allowance? allowance;
  Currency? currency;
  double amount;
  bool asDaily;
  bool asClaimed;
  bool beyondLimit;
  String effectiveDate;
  String? expiryDate;
  bool editable;

  AllowanceMapping(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.attribute,
    this.purpose,
    this.destination,
    this.allowance,
    this.currency,
    this.amount,
    this.asDaily,
    this.asClaimed,
    this.beyondLimit,
    this.effectiveDate,
    this.expiryDate,
    this.editable,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static AllowanceMapping? fromJson(dynamic json) {
    if (json == null) return null;

    return AllowanceMapping(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      Attribute.fromJson(json['attribute']),
      Purpose.fromJson(json['purpose']),
      Destination.fromJson(json['destination']),
      Allowance.fromJson(json['allowance']),
      Currency.fromJson(json['currency']),
      json['amount'],
      json['as_daily'],
      json['as_claimed'],
      json['beyond_limit'],
      json['effective_date'],
      json['expiry_date'],
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
      "attribute": attribute,
      "purpose": purpose,
      "destination": destination,
      "allowance": allowance,
      "currency": currency,
      "amount": amount,
      "as_daily": asDaily,
      "as_claimed": asClaimed,
      "beyond_limit": beyondLimit,
      "effective_date": effectiveDate,
      "expiry_date": expiryDate,
      "editable": editable,
    };
  }
}
