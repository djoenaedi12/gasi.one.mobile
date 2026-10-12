import 'dart:collection';
import 'dart:convert';

import 'package:epeoplecare/model/company/public_holiday.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/provider/date_provider.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class PublicHolidayRepository extends BaseRepository<PublicHoliday> {
  
  PublicHolidayRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/public-holiday");
  }

  Future<List<PublicHoliday>> listByDate(DateTime dateFrom, DateTime dateTo) async {
    Map<String, dynamic> parameters = HashMap();
    parameters["date.gte"] = DateProvider.convertDate2Str(dateFrom, "yyyy-MM-dd");
    parameters["date.lte"] = DateProvider.convertDate2Str(dateTo, "yyyy-MM-dd");
    return await list(parameters: parameters);
  }

  Future<List<PublicHoliday>> listScoupe(Employee employee, DateTime startDate, DateTime endDate) async {
    List<PublicHoliday> result = [];
    Map<String, dynamic> parameters = HashMap();
    parameters.putIfAbsent("employee", () => employee.id);
    parameters.putIfAbsent("dateFrom", () => DateProvider.convertDate2Str(startDate, "yyyy-MM-dd"));
    parameters.putIfAbsent("dateTo", () => DateProvider.convertDate2Str(endDate, "yyyy-MM-dd"));
    var response = await getApiProvider().get(
      url: "${getBaseUrl()}${getUrl()}/getscoupe${buildParameter(parameters, true)}",
      headers: generateHeader(),
    );

    if(response.statusCode == 200) {
      var json = jsonDecode(response.body);
      if(json['success'] == true) {
        for (var i = 0; i < json['data'].length; i++) {
          PublicHoliday? item = fromJson(json['data'][i]);
          if(item != null) {
            result.add(item);
          }
        }
      }
    }

    return result;
  }

  @override
  PublicHoliday? fromJson(Map<String, dynamic>? json) {
    return PublicHoliday.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(PublicHoliday entity) {
    return entity.toJson();  
  }

}