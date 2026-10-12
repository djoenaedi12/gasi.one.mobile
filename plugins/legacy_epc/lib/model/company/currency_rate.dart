import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/model/company/currency.dart';

class CurrencyRate extends BaseModel {
  
  Currency? currency;
  String effectiveDate;
  double rate;

  CurrencyRate(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.currency,
    this.effectiveDate,
    this.rate,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static CurrencyRate? fromJson(dynamic json) {
    if (json == null) return null;

    return CurrencyRate(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      Currency.fromJson(json['currency']),
      json['effective_date'],
      json['rate'],
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
      "currency": currency,
      "effective_date": effectiveDate,
      "rate": rate,
    };
  }
}
