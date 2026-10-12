
import 'package:epeoplecare/model/base_model.dart';

class RecordRule  extends BaseModel {
  String name;
  String tableStr;
  String ruleStr;
  String? url;

  RecordRule(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.name,
    this.tableStr,
    this.ruleStr,
    this.url,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static RecordRule? fromJson(dynamic json) {
    if (json == null) return null;
    
    return RecordRule(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      json['name'],
      json['table_str'],
      json['rule_str'],
      json['url'],
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
      "table_str": tableStr,
      "rule_str": ruleStr,
      "url": url,
    };
  }
}
