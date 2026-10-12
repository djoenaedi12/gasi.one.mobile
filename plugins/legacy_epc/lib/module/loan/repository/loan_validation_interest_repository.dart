import 'dart:collection';
import 'dart:convert';

import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/module/loan/model/loan_type.dart';
import 'package:epeoplecare/module/loan/model/loan_validation_interest.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class LoanValidationInterestRepository extends BaseRepository<LoanValidationInterest> {
  
  LoanValidationInterestRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/loan/validation/interest");
  }

  Future<double> getInterest(Employee employee, LoanType loanType, int period) async {
    double result = 0.0;
    Map<String, dynamic> parameters = HashMap();
    parameters.putIfAbsent("employee", () => employee.id);
    parameters.putIfAbsent("loanType", () => loanType.id);
    parameters.putIfAbsent("period", () => period);
    var response = await getApiProvider().get(
      url: "${getBaseUrl()}${getUrl()}/get-interest${buildParameter(parameters, true)}",
      headers: generateHeader(),
    );

    if(response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if(data['success'] == true) {
        result = double.parse(data['data'].toString());
      }
    }
    return result;
  }

  @override
  LoanValidationInterest? fromJson(Map<String, dynamic>? json) {
    return LoanValidationInterest.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(LoanValidationInterest entity) {
    return entity.toJson();  
  }

}