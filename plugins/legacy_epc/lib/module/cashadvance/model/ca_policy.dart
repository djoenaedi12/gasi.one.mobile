import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/module/cashadvance/model/ca_category.dart';

class CAPolicy extends BaseModel {
  
  String name;
  List<CACategory> caCategories = [];

  CAPolicy(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.name,
    this.caCategories,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static CAPolicy? fromJson(dynamic json) {
    if (json == null) return null;

    List<CACategory> caCategories = [];
    if(json['ca_categories'] != null) {
      for (var i = 0; i < json['ca_categories'].length; i++) {
        CACategory? item = CACategory.fromJson(json['ca_categories'][i]);
        if(item != null) {
          caCategories.add(item);
        }
      }
    }

    return CAPolicy(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      json['name'],
      caCategories,
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
