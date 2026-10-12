import 'package:epeoplecare/model/base_model.dart';

class Purpose extends BaseModel {
  
  String name;
  int seqNumber;

  Purpose(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.name,
    this.seqNumber,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static Purpose? fromJson(dynamic json) {
    if (json == null) return null;

    return Purpose(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      json['name'],
      json['seq_number'],
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
      "seq_number": seqNumber,
    };
  }
}
