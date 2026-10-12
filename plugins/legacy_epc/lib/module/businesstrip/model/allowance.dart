import 'package:epeoplecare/model/base_model.dart';

class Allowance extends BaseModel {
  
  String name;
  bool asClaimed;
  bool beyondLimit;

  Allowance(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.name,
    this.asClaimed,
    this.beyondLimit,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static Allowance? fromJson(dynamic json) {
    if (json == null) return null;

    return Allowance(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      json['name'],
      json['as_claimed'],
      json['beyond_limit'],
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
      "as_claimed": asClaimed,
      "beyond_limit": beyondLimit,
    };
  }
}
