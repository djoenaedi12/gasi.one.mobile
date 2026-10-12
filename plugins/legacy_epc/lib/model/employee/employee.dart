import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/model/company/gender.dart';
import 'package:epeoplecare/model/company/marital.dart';
import 'package:epeoplecare/provider/enum_provider.dart';

class Employee extends BaseModel {
  
  String code;
  String name;
  Gender? gender;
  Marital? marital;
  String? email;
  String? phoneNumber;
  String? birthDate;
  String? joiningDate;
  String? terminationDate;
  Employee? parent;

  Employee(
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
    this.gender,
    this.marital,
    this.email,
    this.phoneNumber,
    this.birthDate,
    this.joiningDate,
    this.terminationDate,
    this.parent,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static Employee? fromJson(dynamic json) {
    if (json == null) return null;
    
    return Employee(
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
      EnumProvider.fromString(Gender.values, json['gender']),
      EnumProvider.fromString(Marital.values, json['marital']),
      json['email'],
      json['phone_number'],
      json['birth_date'],
      json['joining_date'],
      json['termination_date'],
      Employee.fromJson(json['parent']),
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
      "gender": EnumProvider.convertToString(gender),
      "marital": EnumProvider.convertToString(marital),
      "email": email,
      "phone_number": phoneNumber,
      "birth_date": birthDate,
      "joining_date": joiningDate,
      "termination_date": terminationDate,
      "parent": parent
    };
  }

}
