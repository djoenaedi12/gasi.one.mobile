import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/module/payroll/model/document_type.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/provider/enum_provider.dart';

class EmployeeSalarySlip extends BaseModel {
  
  Employee? employee;
  String? salaryPeriod;
  int? year;
  int? month;
  String? description;
  String? filePath;
  DocumentType? documentType;

  EmployeeSalarySlip(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.employee,
    this.salaryPeriod,
    this.year,
    this.month,
    this.description,
    this.filePath,
    this.documentType,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static EmployeeSalarySlip? fromJson(dynamic json) {
    if (json == null) return null;

    return EmployeeSalarySlip(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      Employee.fromJson(json['employee']),
      json['salary_period'],
      json['year'],
      json['month'],
      json['description'],
      json['file_path'],
      EnumProvider.fromString(DocumentType.values, json['document_type']),
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
      "salary_period": salaryPeriod,
      "year": year,
      "month": month,
      "description": description,
      "file_path": filePath,
      "document_type": documentType,
    };
  }
}
