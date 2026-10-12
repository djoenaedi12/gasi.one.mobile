import 'package:epeoplecare/model/base_model.dart';

class Sequence extends BaseModel {
  
  String code;
  String name;
  String format;
  int numberNext;
  int numberIncrement;
  bool useDateRange;

  Sequence(
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
    this.format,
    this.numberNext,
    this.numberIncrement,
    this.useDateRange,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static Sequence? fromJson(dynamic json) {
    if (json == null) return null;
    
    return Sequence(
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
      json['format'],
      json['number_next'],
      json['number_increment'],
      json['use_date_range'],
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
      "format": format,
      "number_next": numberNext,
      "number_increment": numberIncrement,
      "use_date_range": useDateRange,
    };
  }
}
