import 'package:epeoplecare/model/custom_value.dart';
import 'package:epeoplecare/module/customfield/model/custom_value.dart';

class BaseModel
{
  int? id;
  String? creator;
  String? creationTime;
  String? updater;
  String? updateTime;
  int? version;
  List<CustomValue> customValues = [];
  List<Media> medias = [];

  BaseModel(
    this.id,
    this.creator,
    this.creationTime,
    this.updater,
    this.updateTime,
    this.version,
    customValues,
    medias,
  ) {
    this.customValues = customValues ?? getCustomValue(null);
    this.medias = medias ?? getMedia(null);
  }

  static List<CustomValue> getCustomValue(dynamic json) {
    List<CustomValue> customValues = [];
    if(json != null && json['custom_values'] != null) {
      for (var i = 0; i < json['custom_values'].length; i++) {
        var customValue = CustomValue.fromJson(json['custom_values'][i]);
        if(customValue != null) {
          customValues.add(customValue);
        }
      }
    }

    return customValues;
  }

  static List<Media> getMedia(dynamic json) {
    List<Media> medias = [];
    if(json != null && json['medias'] != null) {
      for (var i = 0; i < json['medias'].length; i++) {
        var media = Media.fromJson(json['medias'][i]);
        if(media != null) {
          medias.add(media);
        }
      }
    }

    return medias;
  }

}