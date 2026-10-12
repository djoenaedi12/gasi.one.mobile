import 'package:epeoplecare/model/base_model.dart';

class NotificationModel extends BaseModel {
  
  String notificationDate;
  String? receiver;
  String? subject;
  String? content;
  String? readAt;
  String? data;

  NotificationModel(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.notificationDate,
    this.receiver,
    this.subject,
    this.content,
    this.readAt,
    this.data,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static NotificationModel? fromJson(dynamic json) {
    if (json == null) return null;
    
    return NotificationModel(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      json['notification_date'],
      json['receiver'],
      json['subject'],
      json['content'],
      json['read_at'],
      json['data'],
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
      "notification_date": notificationDate,
      "receiver": receiver,
      "subject": subject,
      "content": content,
      "read_at": readAt,
      "data": data,
    };
  }
}