import 'package:epeoplecare/model/base_model.dart';

class Client extends BaseModel{

  String code;
  String name;
  String url;
  String? image;
  String clientId;
  String clientSecret;

  Client(
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
    this.url,
    this.image,
    this.clientId,
    this.clientSecret,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static Client? fromJson(dynamic json) {
    if (json == null) return null;

    return Client(
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
      json['url'],
      json['image'],
      json['client_id'],
      json['client_secret'],
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
      "url": url,
      "image": image,
      "client_id": clientId,
      "client_secret": clientSecret,
    };
  }

}