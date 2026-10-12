import 'package:epeoplecare/model/base_model.dart';

class WorkingLocation extends BaseModel {
  String name;
  String? address;
  int radius;
  double latitude;
  double longitude;
  bool validateLocation;
  bool requireLocation;
  bool requireAttachment;
  bool validateBiometric;

  WorkingLocation(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.name,
    this.address,
    this.radius,
    this.latitude,
    this.longitude,
    this.validateLocation,
    this.requireLocation,
    this.requireAttachment,
    this.validateBiometric,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static WorkingLocation? fromJson(dynamic json) {
    if (json == null) return null;
    
    return WorkingLocation(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      json['name'],
      json['address'],
      json['radius'],
      json['latitude'],
      json['longitude'],
      json['validate_location'],
      json['require_location'],
      json['require_attachment'] ?? false,
      json['validate_biometric'] ?? false,
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
      "address": address,
      "radius": radius,
      "latitude": latitude,
      "longitude": longitude,
      "validate_location": validateLocation,
      "require_location": requireLocation,
      "require_attachment": requireAttachment,
      "validate_biometric": validateBiometric,
    };
  }
}