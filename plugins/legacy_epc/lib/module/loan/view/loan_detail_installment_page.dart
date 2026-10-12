import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/module/loan/model/interest_type.dart';
import 'package:epeoplecare/module/loan/model/loan_request.dart';
import 'package:epeoplecare/module/loan/model/loan_request_installment.dart';
import 'package:epeoplecare/module/loan/repository/loan_request_installment_repository.dart';
import 'package:epeoplecare/provider/date_provider.dart';
import 'package:epeoplecare/provider/number_provider.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/view/shared/card_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LoanDetailInstallmentPage extends StatefulWidget {
  final LoanRequest? loanRequest;
  final double? amount;
  final int? period;
  final double? interest;
  final InterestType? interestType;
  final DateTime? firstInstallmentDate;
  const LoanDetailInstallmentPage({Key? key, this.loanRequest, this.amount, this.period, this.interest, this.interestType, this.firstInstallmentDate}): super(key: key);

  @override
  State<StatefulWidget> createState() => _LoanDetailInstallmentPageState();
}

class _LoanDetailInstallmentPageState extends State<LoanDetailInstallmentPage> {

  List<LoanRequestInstallment> _loanRequestInstallments = [];
  final LoanRequestInstallmentRepository _loanRequestInstallmentRepository = Repository().getLoanRequestInstallmentRepository();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getInstallments(); 
  }

  _getInstallments() {
    if(widget.loanRequest != null) {
      _loanRequestInstallmentRepository.getInstallments(widget.loanRequest!).then((value) {
        setState(() {
          _loanRequestInstallments = value;
        });
      }).whenComplete(() {
        setState(() {
          _isLoading = false;
        });
      });
    } else if(widget.amount != null && widget.period != null && widget.interest != null && widget.interestType != null && widget.firstInstallmentDate != null) {
      _loanRequestInstallmentRepository.calculate(widget.amount!, widget.amount!, widget.period!, widget.period!, widget.interest!, widget.interestType!, widget.firstInstallmentDate!).then((value) {
        setState(() {
          _loanRequestInstallments = value;
        });
      }).whenComplete(() {
        setState(() {
          _isLoading = false;
        });
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Config.DEFAULT_COLOR,
        iconTheme: IconThemeData(
          color: Config.DEFAULT_ACCENT_COLOR,
        ),
        title: Text(
          "Installment".tr(),
          style: TextStyle(
            color: Config.DEFAULT_ACCENT_COLOR,
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: _isLoading 
      ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Platform.isAndroid
              ? CircularProgressIndicator(valueColor:AlwaysStoppedAnimation<Color>(Config.DEFAULT_COLOR))
              : const CupertinoActivityIndicator(),
              const SizedBox(height: 15.0),
              Text(
                "Please Wait".tr(),
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        )
      : Padding(
          padding: const EdgeInsets.all(5.0),
          child: CardPage(
            list: _loanRequestInstallments,
            renderTitle: (data, index) {
              LoanRequestInstallment installment = data;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    NumberProvider.decimalFormatDouble(installment.interestAmount + installment.principalAmount),
                    style: const TextStyle(
                      fontSize: 14.0,
                    ),
                  ),
                  const SizedBox(width: 5.0),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5.0,
                      vertical: 2.0,
                    ),
                    decoration: BoxDecoration(
                      color: installment.paymentDate != null ? Colors.green : Colors.grey[300],
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    child: Text(
                      (installment.paymentDate != null ? "Paid" : "Unpaid").tr(),
                      style: TextStyle(
                        color: installment.paymentDate != null ? Colors.white : Colors.black
                      ),
                    ),
                  )
                ],
              );
            },
            renderBody: (data, index) {
              LoanRequestInstallment installment = data;
              return Container(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "${"Period".tr()}: ",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text("${installment.period}"),
                      ],
                    ),
                    const SizedBox(height: 5.0),
                    Row(
                      children: [
                        Text(
                          "${"Due Date".tr()}: ",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(DateProvider.convertDateStrFormat(installment.dueDate, "yyyy-MM-dd", "dd MMMM yyyy")),
                      ],
                    ),
                    const SizedBox(height: 5.0),
                    Row(
                      children: [
                        Text(
                          "${"Principal Amount".tr()}: ",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(NumberProvider.decimalFormatDouble(installment.principalAmount)),
                      ],
                    ),
                    const SizedBox(height: 5.0),
                    Row(
                      children: [
                        Text(
                          "${"Interest Amount".tr()}: ",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(NumberProvider.decimalFormatDouble(installment.interestAmount)),
                      ],
                    ),
                    const SizedBox(height: 5.0),
                    Row(
                      children: [
                        Text(
                          "${"Penalty Amount".tr()}: ",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(NumberProvider.decimalFormatDouble(installment.penaltyAmount)),
                      ],
                    ),
                    const SizedBox(height: 5.0),
                    Row(
                      children: [
                        Text(
                          "${"Payment Date".tr()}: ",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(DateProvider.convertDateStrFormat(installment.paymentDate, "yyyy-MM-dd", "dd MMMM yyyy")),
                      ],
                    ),
                  ],
                ),
              );
            },
          )
        ),
    );
  }
}