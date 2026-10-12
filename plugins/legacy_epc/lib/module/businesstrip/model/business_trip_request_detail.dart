import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/module/businesstrip/model/business_trip_request.dart';
import 'package:epeoplecare/module/businesstrip/model/business_trip_request_allowance.dart';
import 'package:epeoplecare/module/businesstrip/model/destination.dart';
import 'package:epeoplecare/module/businesstrip/model/purpose.dart';

class BusinessTripRequestDetail extends BaseModel {
  
  BusinessTripRequest? businessTripRequest;
  Destination? destination;
  Purpose? purpose;
  String dateFrom;
  String dateTo;
  List<BusinessTripRequestAllowance> businessTripRequestAllowances = [];
  int? providedLunch;
  int? providedDinner;

  BusinessTripRequestDetail(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.businessTripRequest,
    this.destination,
    this.purpose,
    this.dateFrom,
    this.dateTo,
    this.businessTripRequestAllowances,
    this.providedLunch,
    this.providedDinner,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static BusinessTripRequestDetail? fromJson(dynamic json) {
    if (json == null) return null;

    List<BusinessTripRequestAllowance> businessTripRequestAllowances = [];
    if(json['business_trip_request_allowances'] != null) {
      for (var i = 0; i < json['business_trip_request_allowances'].length; i++) {
        BusinessTripRequestAllowance? item = BusinessTripRequestAllowance.fromJson(json['business_trip_request_allowances'][i]);
        if(item != null) {
          businessTripRequestAllowances.add(item);
        }
      }
    }
    
    return BusinessTripRequestDetail(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      BusinessTripRequest.fromJson(json['business_trip_request']),
      Destination.fromJson(json['destination']),
      Purpose.fromJson(json['purpose']),
      json['date_from'],
      json['date_to'],
      businessTripRequestAllowances,
      json['provided_lunch'],
      json['provided_dinner'],
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
      "businessTripRequest": businessTripRequest,
      "destination": destination,
      "purpose": purpose,
      "date_from": dateFrom,
      "date_to": dateTo,
      "business_trip_request_allowances": businessTripRequestAllowances,
      "provided_lunch": providedLunch,
      "provided_dinner": providedDinner,
    };
  }
}