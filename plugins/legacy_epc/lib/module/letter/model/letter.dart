import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/module/letter/model/letter_type.dart';

class Letter extends BaseModel {
  
  Employee? employee;
  LetterType? letterType;
  String issuedDate;
  String? description;
  String? filePath;

  Letter(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.employee,
    this.letterType,
    this.issuedDate,
    this.description,
    this.filePath,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static Letter? fromJson(dynamic json) {
    if (json == null) return null;
    
    return Letter(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      Employee.fromJson(json['employee']),
      LetterType.fromJson(json['letter_type']),
      json['issued_date'],
      json['description'],
      json['file_path'],
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
      "employee": employee,
      "letter_type": letterType,
      "issued_date": issuedDate,
      "description": description,
      "file_path": filePath,
    };
  }
}
