import 'package:epeoplecare/model/base_model.dart';

class Announcement extends BaseModel {
  String subject;
  String content;

  Announcement(
    id, 
    creator, 
    creationTime, 
    updater, 
    updateTime, 
    version, 
    customValues, 
    medias,
    this.subject, 
    this.content
  ) : super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static Announcement? fromJson(dynamic json) {
    if (json == null) return null;

    return Announcement(
      json['id'], 
      json['creator'], 
      json['creation_time'], 
      json['updater'], 
      json['update_time'], 
      json['version'], 
      BaseModel.getCustomValue(json), 
      BaseModel.getMedia(json),
      json['subject'], 
      json['content']
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
      "subject": subject,
      "content": content
    };
  }
}
