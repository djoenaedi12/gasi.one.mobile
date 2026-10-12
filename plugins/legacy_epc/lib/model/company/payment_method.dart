import 'package:epeoplecare/model/base_model.dart';

class PaymentMethod extends BaseModel {
  
  String name;

  PaymentMethod(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.name,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static PaymentMethod? fromJson(dynamic json) {
    if (json == null) return null;

    return PaymentMethod(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      json['name'],
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
      "name": name,
    };
  }
}
