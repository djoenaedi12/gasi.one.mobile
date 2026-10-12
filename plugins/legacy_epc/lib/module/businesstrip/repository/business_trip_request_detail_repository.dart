import 'dart:collection';

import 'package:epeoplecare/model/sort.dart';
import 'package:epeoplecare/model/sort_direction.dart';
import 'package:epeoplecare/module/businesstrip/model/business_trip_request.dart';
import 'package:epeoplecare/module/businesstrip/model/business_trip_request_detail.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class BusinessTripRequestDetailRepository extends BaseRepository<BusinessTripRequestDetail> {
  
  BusinessTripRequestDetailRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/businesstrip/detail");
  }

  Future<List<BusinessTripRequestDetail>> listByBusinessTripRequest(BusinessTripRequest businessTripRequest) async {
    Map<String, dynamic> parameters = HashMap();
    List<Sort> sorts = [];
    sorts.add(Sort("dateFrom", SortDirection.ASC));
    parameters["businessTripRequest"] = businessTripRequest.id;
    return await list(parameters: parameters, sorts: sorts);
  }

  @override
  BusinessTripRequestDetail? fromJson(Map<String, dynamic>? json) {
    return BusinessTripRequestDetail.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(BusinessTripRequestDetail entity) {
    return entity.toJson();  
  }

}