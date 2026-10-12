import 'dart:collection';
import 'dart:convert';

import 'package:epeoplecare/model/sort.dart';
import 'package:epeoplecare/model/sort_direction.dart';
import 'package:epeoplecare/module/loan/model/interest_type.dart';
import 'package:epeoplecare/module/loan/model/loan_change_reason.dart';
import 'package:epeoplecare/module/loan/model/loan_request.dart';
import 'package:epeoplecare/module/loan/model/loan_request_installment.dart';
import 'package:epeoplecare/provider/date_provider.dart';
import 'package:epeoplecare/provider/enum_provider.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class LoanRequestInstallmentRepository extends BaseRepository<LoanRequestInstallment> {
  
  LoanRequestInstallmentRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/loan/installment");
  }

  Future<List<LoanRequestInstallment>> listByLoanRequest(LoanRequest loanRequest) async {
    Map<String, dynamic> parameters = HashMap();
    List<Sort> sorts = [];
    sorts.add(Sort("period", SortDirection.ASC));
    parameters["loanRequest"] = loanRequest.id;
    return await list(parameters: parameters);
  }

  Future<List<LoanRequestInstallment>> calculate(double amount, double balanceAmount, int period, int balancePeriod, double interest, InterestType interestType, DateTime firstInstallment) async {
    List<LoanRequestInstallment> result = [];
    Map<String, dynamic> parameters = HashMap();
    parameters.putIfAbsent("amount", () => amount);
    parameters.putIfAbsent("balanceAmount", () => balanceAmount);
    parameters.putIfAbsent("period", () => period);
    parameters.putIfAbsent("balancePeriod", () => balancePeriod);
    parameters.putIfAbsent("interest", () => interest);
    parameters.putIfAbsent("interestType", () => EnumProvider.convertToString(interestType));
    parameters.putIfAbsent("firstInstallment", () => DateProvider.convertDate2Str(firstInstallment, "yyyy-MM-dd"));
    var response = await getApiProvider().get(
      url: "${getBaseUrl()}${getUrl()}/calculate${buildParameter(parameters, true)}",
      headers: generateHeader(),
    );

    if(response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if(data['success'] == true) {
        for (var i = 0; i < data['data'].length; i++) {
          LoanRequestInstallment? item = fromJson(data['data'][i]);
          if(item != null) {
            result.add(item);
          }
        }
      }
    }
    return result;
  }

  Future<List<LoanRequestInstallment>> calculateAdjustment(LoanRequest loanRequest, double extraAmount, int period, DateTime effectiveDate, LoanChangeReason loanChangeReason) async {
    List<LoanRequestInstallment> result = [];
    Map<String, dynamic> parameters = HashMap();
    parameters.putIfAbsent("loanRequest", () => loanRequest.id);
    parameters.putIfAbsent("extraAmount", () => extraAmount);
    parameters.putIfAbsent("period", () => period);
    parameters.putIfAbsent("effectiveDate", () => DateProvider.convertDate2Str(effectiveDate, "yyyy-MM-dd"));
    parameters.putIfAbsent("loanChangeReason", () => loanChangeReason);
    var response = await getApiProvider().get(
      url: "${getBaseUrl()}${getUrl()}/calculate-adjustment${buildParameter(parameters, true)}",
      headers: generateHeader(),
    );

    if(response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if(data['success'] == true) {
        for (var i = 0; i < data['data'].length; i++) {
          LoanRequestInstallment? item = fromJson(data['data'][i]);
          if(item != null) {
            result.add(item);
          }
        }
      }
    }
    return result;
  }

  Future<List<LoanRequestInstallment>> getInstallments(LoanRequest loanRequest) async {
    List<LoanRequestInstallment> result = [];
    Map<String, dynamic> parameters = HashMap();
    parameters.putIfAbsent("loanRequest", () => loanRequest.id);
    var response = await getApiProvider().get(
      url: "${getBaseUrl()}${getUrl()}/getbyloanrequest${buildParameter(parameters, true)}",
      headers: generateHeader(),
    );

    if(response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if(data['success'] == true) {
        for (var i = 0; i < data['data'].length; i++) {
          LoanRequestInstallment? item = fromJson(data['data'][i]);
          if(item != null) {
            result.add(item);
          }
        }
      }
    }
    return result;
  }

  Future<bool> isVisible() async {
    bool result = true;
    var response = await getApiProvider().get(
      url: "${getBaseUrl()}${getUrl()}/visibility",
      headers: generateHeader(),
    );

    if(response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if(data['success'] == true) {
        result = data['data'];
      }
    }
    return result;
  }

  @override
  LoanRequestInstallment? fromJson(Map<String, dynamic>? json) {
    return LoanRequestInstallment.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(LoanRequestInstallment entity) {
    return entity.toJson();  
  }

}