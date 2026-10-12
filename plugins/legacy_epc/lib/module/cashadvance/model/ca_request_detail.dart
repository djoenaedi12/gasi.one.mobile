import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/module/cashadvance/model/ca_category.dart';
import 'package:epeoplecare/module/cashadvance/model/ca_request.dart';

class CARequestDetail extends BaseModel {
  
  CARequest? caRequest;
  CACategory? caCategory;
  String name;
  String? description;
  double amount;

  CARequestDetail(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.caRequest,
    this.caCategory,
    this.name,
    this.description,
    this.amount,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static CARequestDetail? fromJson(dynamic json) {
    if (json == null) return null;

    return CARequestDetail(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      CARequest.fromJson(json['ca_request']),
      CACategory.fromJson(json['ca_category']),
      json['name'],
      json['description'],
      json['amount'],
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
      "ca_request": caRequest,
      "ca_category": caCategory,
      "name": name,
      "description": description,
      "amount": amount,
    };
  }
}