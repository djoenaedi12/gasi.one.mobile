import 'dart:collection';
import 'dart:convert';

import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/module/loan/model/loan_type.dart';
import 'package:epeoplecare/module/loan/model/loan_validation.dart';
import 'package:epeoplecare/provider/date_provider.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class LoanValidationRepository extends BaseRepository<LoanValidation> {
  
  LoanValidationRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/loan/validation");
  }

  Future<List<String>> isEligible(Employee employee, LoanType loanType, int period, double amount, int? loanRequestId, DateTime? firstInstallmentDate) async {
    List<String> result = [];
    Map<String, dynamic> parameters = HashMap();
    parameters.putIfAbsent("employee", () => employee.id);
    parameters.putIfAbsent("loanType", () => loanType.id);
    parameters.putIfAbsent("period", () => period);
    parameters.putIfAbsent("amount", () => amount);
    parameters.putIfAbsent("firstInstallmentDate", () => DateProvider.convertDate2Str(firstInstallmentDate, "yyyy-MM-dd"));
    if (loanRequestId != null) {
      parameters.putIfAbsent("loanRequest", () => loanRequestId);
    }
    var response = await getApiProvider().get(
      url: "${getBaseUrl()}${getUrl()}/is-eligible${buildParameter(parameters, true)}",
      headers: generateHeader(),
    );

    if(response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if(data['success'] == true) {
        for (var i = 0; i < data['data'].length; i++) {
          result.add(data['data'][i].toString());
        }
      }
    }

    return result;
  }

  @override
  LoanValidation? fromJson(Map<String, dynamic>? json) {
    return LoanValidation.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(LoanValidation entity) {
    return entity.toJson();  
  }

}