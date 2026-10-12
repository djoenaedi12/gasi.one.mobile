import 'package:epeoplecare/model/base_model.dart';

class Currency extends BaseModel {
  
  String code;
  String name;
  String symbol;

  Currency(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.code,
    this.name,
    this.symbol,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static Currency? fromJson(dynamic json) {
    if (json == null) return null;

    return Currency(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      json['code'],
      json['name'],
      json['symbol'],
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
      "code": code,
      "name": name,
      "symbol": symbol,
    };
  }
}
