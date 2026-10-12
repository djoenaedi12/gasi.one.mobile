import 'dart:collection';
import 'dart:convert';

import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/model/sort.dart';
import 'package:epeoplecare/model/sort_direction.dart';
import 'package:epeoplecare/module/businesstrip/model/business_trip_request_allowance.dart';
import 'package:epeoplecare/module/businesstrip/model/business_trip_request_detail.dart';
import 'package:epeoplecare/module/businesstrip/model/destination.dart';
import 'package:epeoplecare/module/businesstrip/model/purpose.dart';
import 'package:epeoplecare/provider/date_provider.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class BusinessTripRequestAllowanceRepository extends BaseRepository<BusinessTripRequestAllowance> {
  
  BusinessTripRequestAllowanceRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/businesstrip/detail/allowance");
  }

  Future<List<BusinessTripRequestAllowance>> listByBusinessTripRequestDetail(BusinessTripRequestDetail businessTripRequestDetail) async {
    Map<String, dynamic> parameters = HashMap();
    List<Sort> sorts = [];
    sorts.add(Sort("date", SortDirection.ASC));
    parameters["businessTripRequestDetail"] = businessTripRequestDetail.id;
    return await list(parameters: parameters, sorts: sorts);
  }

  Future<List<BusinessTripRequestAllowance>> listByBusinessTripRequestDetails(List<BusinessTripRequestDetail> businessTripRequestDetails) async {
    Map<String, dynamic> parameters = HashMap();
    List<Sort> sorts = [];
    List<int> ids = [];
    for (BusinessTripRequestDetail businessTripRequestDetail in businessTripRequestDetails) {
      ids.add(businessTripRequestDetail.id!);
    }
    sorts.add(Sort("date", SortDirection.ASC));
    parameters["businessTripRequestDetail.in"] = ids;
    return await list(parameters: parameters, sorts: sorts);
  }

  Future<List<BusinessTripRequestAllowance>> calculate(Employee employee, Purpose purpose, Destination destination, DateTime dateFrom, DateTime dateTo, int providedLunch, int providedDinner) async {
    List<BusinessTripRequestAllowance> result = [];
    Map<String, dynamic> parameters = HashMap();
    parameters.putIfAbsent("employee", () => employee.id);
    parameters.putIfAbsent("destination", () => destination.id);
    parameters.putIfAbsent("purpose", () => purpose.id);
    parameters.putIfAbsent("dateFrom", () => DateProvider.convertDate2Str(dateFrom, "yyyy-MM-dd HH:mm:ss"));
    parameters.putIfAbsent("dateTo", () => DateProvider.convertDate2Str(dateTo, "yyyy-MM-dd HH:mm:ss"));
    parameters.putIfAbsent("providedLunch", () => providedLunch);
    parameters.putIfAbsent("providedDinner", () => providedDinner);
    var response = await getApiProvider().get(
      url: "${getBaseUrl()}${getUrl()}/calculate${buildParameter(parameters, true)}",
      headers: generateHeader(),
    );

    if(response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if(data['success'] == true) {
        for (var i = 0; i < data['data'].length; i++) {
          BusinessTripRequestAllowance? item = fromJson(data['data'][i]);
          if(item != null) {
            result.add(item);
          }
        }
      }
    }
    return result;
  }

  @override
  BusinessTripRequestAllowance? fromJson(Map<String, dynamic>? json) {
    return BusinessTripRequestAllowance.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(BusinessTripRequestAllowance entity) {
    return entity.toJson();  
  }

}