import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/module/cashadvance/model/ca_request_detail.dart';
import 'package:epeoplecare/module/cashadvance/model/ca_settlement.dart';

class CASettlementDetail extends BaseModel {
  
  CASettlement? caSettlement;
  CARequestDetail? caRequestDetail;
  String? attachment;
  double amount;

  CASettlementDetail(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.caSettlement,
    this.caRequestDetail,
    this.attachment,
    this.amount,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static CASettlementDetail? fromJson(dynamic json) {
    if (json == null) return null;

    return CASettlementDetail(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      CASettlement.fromJson(json['ca_settlement']),
      CARequestDetail.fromJson(json['ca_request_detail']),
      json['attachment'],
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
      "ca_settlement": caSettlement,
      "ca_request_detail": caRequestDetail,
      "attachment": attachment,
      "amount": amount,
    };
  }
}