import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/module/workflow/model/sequence.dart';
import 'package:epeoplecare/module/workflow/model/workflow_status.dart';
import 'package:epeoplecare/provider/enum_provider.dart';

class Route extends BaseModel {
  
  String code;
  String name;
  Sequence? sequence;
  int seqNumber;
  // mandatory remark workflow status revoked, rejected, sent back, pullbacked
  List<WorkflowStatus> requiredRemarks = [];

  Route(
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
    this.sequence,
    this.seqNumber,
    this.requiredRemarks,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static Route? fromJson(dynamic json) {
    if (json == null) return null;
    
    List<WorkflowStatus> requiredRemarks = [];
    if(json['required_remarks'] != null) {
      for (var i = 0; i < json['required_remarks'].length; i++) {
        WorkflowStatus? item = EnumProvider.fromString(WorkflowStatus.values, json['required_remarks'][i]);
        if(item != null) {
          requiredRemarks.add(item);
        }
      }
    }

    return Route(
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
      Sequence.fromJson(json['sequence']),
      json['seq_number'],
      requiredRemarks,
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
      "sequence": sequence,
      "seq_number": seqNumber,
      "required_remarks": requiredRemarks.map((e) => e.name.toUpperCase()).toList(),
    };
  }
}