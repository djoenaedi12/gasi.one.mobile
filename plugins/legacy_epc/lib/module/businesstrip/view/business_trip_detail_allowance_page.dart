import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/company/currency.dart';
import 'package:epeoplecare/module/businesstrip/model/business_trip_request_allowance.dart';
import 'package:epeoplecare/provider/date_provider.dart';
import 'package:epeoplecare/provider/number_provider.dart';
import 'package:epeoplecare/view/shared/card_page.dart';
import 'package:epeoplecare/view/shared/input_form.dart';
import 'package:flutter/material.dart';

class BusinessTripDetailAllowancePage extends StatefulWidget {

  final List<BusinessTripRequestAllowance> businessTripRequestAllowances;
  final bool editable;
  final bool deductionVisibility;
  const BusinessTripDetailAllowancePage({Key? key, this.businessTripRequestAllowances = const [], this.deductionVisibility = false, this.editable = false}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _BusinessTripDetailAllowancePageState();
}

class _BusinessTripDetailAllowancePageState extends State<BusinessTripDetailAllowancePage> {
  Currency? _currency;
  double _totalAllowanceAmount = 0.0;
  double _totalActualAmount = 0.0;
  double _totalPaidAmount = 0.0;
  double _totalDeductionAmount = 0.0;

  @override
  void initState() {
    super.initState();
    for (BusinessTripRequestAllowance allowance in widget.businessTripRequestAllowances) {
      _currency = allowance.currency;
      _totalAllowanceAmount += allowance.allowanceAmount;
      if(allowance.actualAmount != null) {
        _totalActualAmount += allowance.actualAmount ?? 0;
      }
      if(allowance.paidAmount!= null) {
        _totalPaidAmount += allowance.paidAmount ?? 0;
      }
      if(allowance.dedcutionAmount!= null) {
        _totalDeductionAmount += allowance.dedcutionAmount ?? 0;
      }
    }
  }

  _calculateAllowanceAmount() {
    _totalAllowanceAmount = 0;
    for (BusinessTripRequestAllowance allowance in widget.businessTripRequestAllowances) {
      setState(() {
        _totalAllowanceAmount += allowance.allowanceAmount;        
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var mediaQuery = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Config.DEFAULT_COLOR,
        iconTheme: IconThemeData(
          color: Config.DEFAULT_ACCENT_COLOR,
        ),
        title: Text(
          "Detail Allowance".tr(),
          style: TextStyle(
            color: Config.DEFAULT_ACCENT_COLOR,
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: CardPage(
              list: widget.businessTripRequestAllowances,
              renderTitle: (data, index) {
                BusinessTripRequestAllowance allowance = data;
                return Row(
                  children: [
                    Text(DateProvider.convertDateStrFormat(allowance.date, "yyyy-MM-dd", "dd MMM yyyy")),
                    const Text(" - "),
                    Text(allowance.allowance!.name),
                    const Text(" - "),
                    Text("${allowance.currency!.symbol} ${NumberProvider.decimalFormatDouble(allowance.allowanceAmount - (allowance.dedcutionAmount ?? 0.0))}"),
                  ],
                );
              },
              renderBody: (data, index) {
                BusinessTripRequestAllowance allowance = data;
                return Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            "${"Date".tr()}: ",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(DateProvider.convertDateStrFormat(allowance.date, "yyyy-MM-dd", "dd MMMM yyyy")),
                        ],
                      ),
                      const SizedBox(height: 5.0),
                      Row(
                        children: [
                          Text(
                            "${"Allowance".tr()}: ",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(allowance.allowance!.name),
                        ],
                      ),
                      const SizedBox(height: 5.0),
                      widget.editable && allowance.editable 
                      ? InputForm().renderTextField(
                          textInputType: TextInputType.number,
                          initialValue: allowance.allowanceAmount.toString(),
                          fieldName: "Allowance Amount".tr(),
                          onFieldSubmitted: (val) {
                            allowance.allowanceAmount = double.parse(val);
                            _calculateAllowanceAmount();
                          },
                        )
                      : Row(
                          children: [
                            Text(
                              "${"Allowance Amount".tr()}: ",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text("${allowance.currency!.symbol} ${NumberProvider.decimalFormatDouble(allowance.allowanceAmount)}"),
                          ],
                        ),
                      const SizedBox(height: 5.0),
                      Visibility(
                        visible: widget.deductionVisibility,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 5.0),
                          child: Row(
                            children: [
                              Text(
                                "${"Deduction Amount".tr()}: ",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text("${allowance.currency!.symbol} ${NumberProvider.decimalFormatDouble(allowance.dedcutionAmount)}"),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            "${"Actual Amount".tr()}: ",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text("${allowance.currency!.symbol} ${NumberProvider.decimalFormatDouble(allowance.actualAmount)}"),
                        ],
                      ),
                      const SizedBox(height: 5.0),
                      Row(
                        children: [
                          Text(
                            "${"Paid Amount".tr()}: ",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text("${allowance.currency!.symbol} ${NumberProvider.decimalFormatDouble(allowance.paidAmount)}"),
                        ],
                      ),
                      const SizedBox(height: 5.0),
                      Row(
                        children: [
                          Text(
                            "${"Remark".tr()}: ",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(allowance.remark ?? ""),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10.0),
            width: mediaQuery.width,
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey,
                  blurRadius: 3,
                )
              ]
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total Allowance".tr(),
                      style: const TextStyle(
                        fontSize: 16.0,
                      ),
                    ),
                    Text(
                      "${_currency != null ? _currency!.symbol : ""} ${NumberProvider.decimalFormatDouble(_totalAllowanceAmount)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                Visibility(
                  visible: widget.deductionVisibility,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Deduction Amount".tr(),
                          style: const TextStyle(
                            fontSize: 16.0,
                          ),
                        ),
                        Text(
                          "${_currency != null ? _currency!.symbol : ""} ${NumberProvider.decimalFormatDouble(_totalDeductionAmount)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Actual Amount".tr(),
                      style: const TextStyle(
                        fontSize: 16.0,
                      ),
                    ),
                    Text(
                      "${_currency != null ? _currency!.symbol : ""} ${NumberProvider.decimalFormatDouble(_totalActualAmount)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Paid Amount".tr(),
                      style: const TextStyle(
                        fontSize: 16.0,
                      ),
                    ),
                    Text(
                      "${_currency != null ? _currency!.symbol : ""} ${NumberProvider.decimalFormatDouble(_totalPaidAmount)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}