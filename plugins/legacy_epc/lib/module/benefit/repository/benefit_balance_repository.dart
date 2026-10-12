import 'dart:collection';
import 'dart:convert';

import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/module/benefit/model/benefit_balance.dart';
import 'package:epeoplecare/module/benefit/model/benefit.dart';
import 'package:epeoplecare/provider/date_provider.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class BenefitBalanceRepository extends BaseRepository<BenefitBalance> {
  
  BenefitBalanceRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/benefit/balance");
  }

  Future<List<BenefitBalance>> listByEmployeeAndDate(Employee employee, DateTime dateFrom, DateTime dateTo) async {
    List<BenefitBalance> result = [];
    Map<String, dynamic> parameters = HashMap();
    parameters['employee'] = employee.id;
    parameters['effectiveDate'] = DateProvider.convertDate2Str(dateFrom, "yyyy-MM-dd");
    parameters['expiryDate'] = DateProvider.convertDate2Str(dateTo, "yyyy-MM-dd");
    var response = await getApiProvider().get(
      url: "${getBaseUrl()}${getUrl()}/getbyemployeebenefitanddate${buildParameter(parameters, true)}",
      headers: generateHeader(),
    );

    if(response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if(data['success'] == true) {
        for (var i = 0; i < data['data'].length; i++) {
          BenefitBalance? item = fromJson(data['data'][i]);
          if(item != null) {
            result.add(item);
          }
        }
      }
    }

    return result;
  }

  Future<List<BenefitBalance>> listByEmployeeAndDateAndBenefit(Employee employee, DateTime dateFrom, DateTime dateTo, Benefit benefit) async {
    List<BenefitBalance> result = [];
    Map<String, dynamic> parameters = HashMap();
    parameters['employee'] = employee.id;
    parameters['benefit'] = benefit.id;
    parameters['effectiveDate'] = DateProvider.convertDate2Str(dateFrom, "yyyy-MM-dd");
    parameters['expiryDate'] = DateProvider.convertDate2Str(dateTo, "yyyy-MM-dd");
    var response = await getApiProvider().get(
      url: "${getBaseUrl()}${getUrl()}/getbyemployeebenefitanddate${buildParameter(parameters, true)}",
      headers: generateHeader(),
    );

    if(response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if(data['success'] == true) {
        for (var i = 0; i < data['data'].length; i++) {
          BenefitBalance? item = fromJson(data['data'][i]);
          if(item != null) {
            result.add(item);
          }
        }
      }
    }

    return result;
  }

  @override
  BenefitBalance? fromJson(Map<String, dynamic>? json) {
    return BenefitBalance.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(BenefitBalance entity) {
    return entity.toJson();
  }

}