import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/module/loan/model/loan_request.dart';

class LoanRequestInstallment extends BaseModel {
  
  LoanRequest? loanRequest;
  int period;
  String dueDate;
  double interestAmount;
  double principalAmount;
  double principalBalance;
  String? paymentDate;
  double? penaltyAmount;

  LoanRequestInstallment(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.loanRequest,
    this.period,
    this.dueDate,
    this.interestAmount,
    this.principalAmount,
    this.principalBalance,
    this.paymentDate,
    this.penaltyAmount,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static LoanRequestInstallment? fromJson(dynamic json) {
    if (json == null) return null;

    return LoanRequestInstallment(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      LoanRequest.fromJson(json['loan_request']),
      json['period'],
      json['due_date'],
      json['interest_amount'],
      json['principal_amount'],
      json['principal_balance'],
      json['payment_date'],
      json['penalty_amount'],
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
      "loan_request": loanRequest,
      "period": period,
      "due_date": dueDate,
      "interest_amount": interestAmount,
      "principal_amount": principalAmount,
      "principal_balance": principalBalance,
      "payment_date": paymentDate,
      "penalty_amount": penaltyAmount,
    };
  }
}
