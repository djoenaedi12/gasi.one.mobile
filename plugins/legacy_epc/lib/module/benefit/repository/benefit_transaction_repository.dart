import 'dart:collection';
import 'dart:convert';

import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/model/employee/employee_dependent.dart';
import 'package:epeoplecare/module/benefit/model/benefit.dart';
import 'package:epeoplecare/module/benefit/model/benefit_transaction.dart';
import 'package:epeoplecare/module/workflow/repository/app_workflow_repository.dart';
import 'package:epeoplecare/provider/date_provider.dart';

class BenefitTransactionRepository
    extends AppWorkflowRepository<BenefitTransaction> {
  BenefitTransactionRepository(
      String url, String accessToken, String refreshToken, String language)
      : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/benefit/transaction");
  }

  Future<double> getApprovedAmount(Benefit benefit, double amount,
      EmployeeDependent? employeeDependent, Employee? employee, List<int>? prevBenefit, List<double>? prevAmount, BenefitTransaction? benefitTransaction) async {
    double approvedAmount = 0;
    Map<String, dynamic> parameters = HashMap();
    parameters['benefit'] = benefit.id;
    parameters['amount'] = amount;
    if (employeeDependent != null) {
      parameters['employeeDependent'] = employeeDependent.id;
    }
    if (employee != null) {
      parameters['employee'] = employee.id;
    }
    if (benefitTransaction != null) {
      parameters['benefitTransaction'] = benefitTransaction.id;
    }
    if (prevBenefit != null) {
      parameters['prevBenefit'] = prevBenefit;
    }
    if (prevAmount != null) {
      parameters['prevAmount'] = prevAmount;
    }

    var response = await getApiProvider().get(
      url:
          "${getBaseUrl()}${getUrl()}/approved-amount${buildParameter(parameters, true)}",
      headers: generateHeader(),
    );

    var data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      approvedAmount = data['data'];
    }

    return approvedAmount;
  }

  Future<double> getBalance(Benefit benefit, DateTime requestDate,
      Employee employee, BenefitTransaction? benefitTransaction) async {
    double balance = 0;
    Map<String, dynamic> parameters = HashMap();
    parameters['dateFrom'] =
        DateProvider.convertDate2Str(requestDate, "yyyy-MM-dd");
    parameters['dateTo'] =
        DateProvider.convertDate2Str(requestDate, "yyyy-MM-dd");
    parameters['benefit'] = benefit.id;
    parameters['employee'] = employee.id;

    if (benefitTransaction != null) {
      parameters['benefitTransaction'] = benefitTransaction.id;
    }

    var response = await getApiProvider().get(
      url:
          "${getBaseUrl()}${getUrl()}/effective-balance${buildParameter(parameters, true)}",
      headers: generateHeader(),
    );

    var data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      balance = data['data'];
    }

    return balance;
  }

  @override
  BenefitTransaction? fromJson(Map<String, dynamic>? json) {
    return BenefitTransaction.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(BenefitTransaction entity) {
    return entity.toJson();
  }
}
