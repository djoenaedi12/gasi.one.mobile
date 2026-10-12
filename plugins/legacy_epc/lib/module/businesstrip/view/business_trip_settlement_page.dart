import 'dart:collection';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/company/currency.dart';
import 'package:epeoplecare/module/businesstrip/model/business_trip_request.dart';
import 'package:epeoplecare/module/businesstrip/model/business_trip_request_allowance.dart';
import 'package:epeoplecare/module/businesstrip/model/business_trip_request_detail.dart';
import 'package:epeoplecare/module/businesstrip/repository/business_trip_request_repository.dart';
import 'package:epeoplecare/module/businesstrip/view/business_trip_additional_page.dart';
import 'package:epeoplecare/provider/date_provider.dart';
import 'package:epeoplecare/provider/number_provider.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/view/shared/card_page.dart';
import 'package:epeoplecare/view/shared/detail_page.dart';
import 'package:epeoplecare/view/shared/input_form.dart';
import 'package:epeoplecare/view/shared/message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class BusinessTripSettlementPage extends StatefulWidget {
  final BusinessTripRequest? businessTripRequest;
  final bool deductionVisibility;
  const BusinessTripSettlementPage({Key? key, this.businessTripRequest, this.deductionVisibility = false}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _BusinessTripSettlementPageState();
}

class _BusinessTripSettlementPageState extends State<BusinessTripSettlementPage> {
  
  Currency? _currency;
  double _totalAllowanceAmount = 0.0;
  double _totalActualAmount = 0.0;
  double _totalPaidAmount = 0.0;
  final form = GlobalKey<FormState>();
  BusinessTripRequest? _businessTripRequest;
  final BusinessTripRequestRepository _businessTripRequestRepository = Repository().getBusinessTripRequestRepository();
  Map<int, List<TextEditingController?>> actualAmountControllerMap = HashMap();
  Map<int, List<TextEditingController?>> remarkAmountControllerMap = HashMap();
  double _totalDeductionAmount = 0.0;

  @override
  void initState() {
    super.initState();
    List<BusinessTripRequestDetail> businessTripRequestDetails = [];
    _businessTripRequest = BusinessTripRequest(
      widget.businessTripRequest!.id,
      widget.businessTripRequest!.creator,
      widget.businessTripRequest!.creationTime,
      widget.businessTripRequest!.updater,
      widget.businessTripRequest!.updateTime,
      widget.businessTripRequest!.version,
      widget.businessTripRequest!.customValues,
      widget.businessTripRequest!.medias,
      widget.businessTripRequest!.workflow,
      widget.businessTripRequest!.requestNo,
      widget.businessTripRequest!.workflowStatus,
      widget.businessTripRequest!.employee,
      widget.businessTripRequest!.attachment,
      widget.businessTripRequest!.description,
      widget.businessTripRequest!.assignee,
      widget.businessTripRequest!.assignment,
      widget.businessTripRequest!.parameters,
      widget.businessTripRequest!.workflowExecutors,
      widget.businessTripRequest!.dateFrom,
      widget.businessTripRequest!.dateTo,
      widget.businessTripRequest!.settlementDate,
      businessTripRequestDetails,
    );

    for (BusinessTripRequestDetail detail in widget.businessTripRequest!.businessTripRequestDetails) {
      List<TextEditingController?> actualAmountControllers = [];
      List<TextEditingController?> remarkControllers = [];

      List<BusinessTripRequestAllowance> businessTripRequestAllowances = [];
      for (BusinessTripRequestAllowance allowance in detail.businessTripRequestAllowances) {
        BusinessTripRequestAllowance allowanceTmp = BusinessTripRequestAllowance(
          allowance.id, 
          allowance.creator, 
          allowance.creationTime, 
          allowance.updater, 
          allowance.updateTime, 
          allowance.version, 
          allowance.customValues, 
          allowance.medias,
          allowance.businessTripRequestDetail, 
          allowance.date, 
          allowance.allowance, 
          allowance.currency, 
          allowance.allowanceAmount, 
          allowance.actualAmount, 
          allowance.paidAmount, 
          allowance.remark, 
          allowance.asClaimed, 
          allowance.beyondLimit, 
          allowance.additionalClaim,
          allowance.dedcutionAmount,
          allowance.editable,
        );

        _currency = allowanceTmp.currency;
        _totalAllowanceAmount += allowanceTmp.allowanceAmount;
        if(allowanceTmp.actualAmount == null) {
          if(_businessTripRequest!.settlementDate == null) {
            allowanceTmp.actualAmount = allowanceTmp.allowanceAmount;
          } else {
            allowanceTmp.actualAmount = 0.0;
          }
        }
        if(allowanceTmp.paidAmount == null) {
          if(_businessTripRequest!.settlementDate == null) {
            allowanceTmp.paidAmount = allowanceTmp.allowanceAmount;
          } else {
            allowanceTmp.paidAmount = 0.0;
          }
        }
        _totalActualAmount += allowanceTmp.actualAmount ?? 0;
        _totalPaidAmount += allowanceTmp.paidAmount ?? 0;
        actualAmountControllers.add(null);
        remarkControllers.add(null);

        businessTripRequestAllowances.add(allowanceTmp);
        if(allowance.dedcutionAmount!= null) {
          _totalDeductionAmount += allowance.dedcutionAmount ?? 0;
        }
      } 

      actualAmountControllerMap.putIfAbsent(detail.id!, () => actualAmountControllers);
      remarkAmountControllerMap.putIfAbsent(detail.id!, () => remarkControllers);   
      businessTripRequestDetails.add(
        BusinessTripRequestDetail(
          detail.id, 
          detail.creator, 
          detail.creationTime, 
          detail.updater, 
          detail.updateTime, 
          detail.version, 
          detail.customValues, 
          detail.medias,
          detail.businessTripRequest, 
          detail.destination, 
          detail.purpose, 
          detail.dateFrom, 
          detail.dateTo, 
          businessTripRequestAllowances,
          detail.providedLunch,
          detail.providedDinner,
        )
      ); 
    }

    _businessTripRequest!.businessTripRequestDetails = businessTripRequestDetails;
  }

  _calculateActualAllowance() {
    _totalActualAmount = 0.0;
    _totalPaidAmount = 0.0;
    for (BusinessTripRequestDetail detail in _businessTripRequest!.businessTripRequestDetails) {
      for (BusinessTripRequestAllowance allowance in detail.businessTripRequestAllowances) {
        _totalActualAmount += allowance.actualAmount ?? 0;
        _totalPaidAmount += allowance.paidAmount ?? 0;
      } 
    }
  }

  _settlement() {
    if(form.currentState!.validate()) {
      EasyLoading.show(status: "Please Wait".tr());
      _businessTripRequestRepository.settlement(entity: _businessTripRequest!).then((value) {
        EasyLoading.dismiss();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessagePage(
              icon: const Icon(Icons.check_circle, size: 100, color: Colors.green),
              title: "Success".tr(),
              subTitle: "Data has been".tr(namedArgs: {"status": "settled".tr()}),
            ),
          ),
        ).then((value) {
          Navigator.pop(context, true);
        });
      }).catchError((onError){
        EasyLoading.dismiss();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessagePage(
              icon: const Icon(Icons.error, size: 100, color: Colors.red),
              title: "Error".tr(),
              subTitle: onError.toString(),
            ),
          ),
        );
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
          "Settlement".tr(),
          style: TextStyle(
            color: Config.DEFAULT_ACCENT_COLOR,
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: Form(
              key: form,
              child: CardPage(
                color: Colors.grey[200],
                list: _businessTripRequest!.businessTripRequestDetails,
                expanded: _businessTripRequest!.settlementDate != null ? false : true,
                renderTitle: (val, index) {
                  BusinessTripRequestDetail detail = val;
                  return Text(
                    "${DateProvider.convertDateStrFormat(detail.dateFrom, "yyyy-MM-dd", "dd MMMM yyyy")} - ${DateProvider.convertDateStrFormat(detail.dateTo, "yyyy-MM-dd", "dd MMMM yyyy")}"
                  );
                },
                renderBody: (val, index) {
                  BusinessTripRequestDetail detail = val;
                  return _businessTripRequest!.settlementDate != null
                  ? CardPage(
                      list: detail.businessTripRequestAllowances,
                      physics: const NeverScrollableScrollPhysics(),
                      renderTitle: (data, index) {
                        BusinessTripRequestAllowance allowance = data;
                        return Row(
                          children: [
                            Text(DateProvider.convertDateStrFormat(allowance.date, "yyyy-MM-dd", "dd MMM yyyy")),
                            const Text(" - "),
                            Text(allowance.allowance!.name),
                            const Text(" - "),
                            Text("${allowance.currency!.symbol} ${NumberProvider.decimalFormatDouble(allowance.allowanceAmount)}"),
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
                              Row(
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
                    )
                  : DetailPage(
                      isEditable: true,
                      expended: true,
                      itemList: detail.businessTripRequestAllowances,
                      title: "Add Allowance".tr(),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BusinessTripAdditionalPage(),
                          ),
                        ).then((value) {
                          if(value == null) return;

                          setState(() {
                            var actualAmountController = TextEditingController();
                            var remarkController = TextEditingController();
                            actualAmountController.text = value.actualAmount.toString();
                            remarkController.text = value.remark;
                            actualAmountControllerMap[detail.id]!.add(actualAmountController);
                            remarkAmountControllerMap[detail.id]!.add(remarkController);
                            detail.businessTripRequestAllowances.add(value);
                          });
                          _calculateActualAllowance();
                        });
                      },
                      onDelete: (index) {
                        setState(() {
                          detail.businessTripRequestAllowances.removeAt(index);
                          actualAmountControllerMap[detail.id]!.removeAt(index);
                          remarkAmountControllerMap[detail.id]!.removeAt(index);
                        });
                        _calculateActualAllowance();
                      },
                      onEdit: (item, index) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BusinessTripAdditionalPage(
                              businessTripRequestAllowance: item,
                            ),
                          ),
                        ).then((value) {
                          if(value == null) return;

                          setState(() {
                            detail.businessTripRequestAllowances[index] = value;
                            actualAmountControllerMap[detail.id]![index]!.text = value.actualAmount.toString();
                            remarkAmountControllerMap[detail.id]![index]!.text = value.remark;
                          });
                          _calculateActualAllowance();
                        });
                      },
                      isEditableForm: (data, index) {
                        BusinessTripRequestAllowance allowance = data;
                        return allowance.additionalClaim;
                      },
                      renderTitle: (data, index) {
                        BusinessTripRequestAllowance allowance = data;
                        return Row(
                          children: [
                            Text(DateProvider.convertDateStrFormat(allowance.date, "yyyy-MM-dd", "dd MMM yyyy")),
                            const Text(" - "),
                            Text(allowance.allowance!.name),
                            const Text(" - "),
                            Text("${allowance.currency!.symbol} ${NumberProvider.decimalFormatDouble(allowance.allowanceAmount)}"),
                          ],
                        );
                      },
                      renderBody: (data, index) {
                        BusinessTripRequestAllowance allowance = data;
                        return Container(
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
                              Row(
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
                                    "${"Paid Amount".tr()}: ",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text("${allowance.currency!.symbol} ${NumberProvider.decimalFormatDouble(allowance.paidAmount)}"),
                                ],
                              ),
                              InputForm().renderTextField(
                                textInputType: TextInputType.number,
                                initialValue: allowance.actualAmount.toString(),
                                controller: actualAmountControllerMap[detail.id]![index],
                                fieldName: "Actual Amount".tr(),
                                onFieldSubmitted: (val) {
                                  setState(() {
                                    allowance.actualAmount = double.parse(val);
                                    if(allowance.asClaimed) {
                                      if(allowance.beyondLimit && allowance.actualAmount! > allowance.allowanceAmount - (allowance.dedcutionAmount ?? 0.0)) {
                                        allowance.paidAmount = allowance.actualAmount;
                                      } else {
                                        allowance.paidAmount = allowance.allowanceAmount - (allowance.dedcutionAmount ?? 0.0);
                                      }
                                    } else {
                                      if(allowance.beyondLimit && allowance.actualAmount! > allowance.allowanceAmount - (allowance.dedcutionAmount ?? 0.0)) {
                                        allowance.paidAmount = allowance.actualAmount;
                                      }else if(!allowance.beyondLimit && allowance.actualAmount! > allowance.allowanceAmount - (allowance.dedcutionAmount ?? 0.0)) {
                                        allowance.paidAmount = allowance.allowanceAmount - (allowance.dedcutionAmount ?? 0.0);
                                      } else {
                                        allowance.paidAmount = allowance.actualAmount;
                                      }
                                    }
                                    _calculateActualAllowance();
                                  });
                                },
                              ),
                              InputForm().renderTextField(
                                fieldName: "Remark".tr(),
                                initialValue: allowance.remark,
                                controller: remarkAmountControllerMap[detail.id]![index],
                                onFieldSubmitted: (val) {
                                  setState(() {
                                    allowance.remark = val;
                                  });
                                },
                              )
                            ],
                          )
                        );
                      },
                    );
                },
              ),
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
                      "Settlement Date".tr(),
                      style: const TextStyle(
                        fontSize: 16.0,
                      ),
                    ),
                    Text(
                      DateProvider.convertDateStrFormat(_businessTripRequest!.settlementDate, "yyyy-MM-dd", "dd MMMM yyyy"),
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
                Visibility(
                  visible: _businessTripRequest!.settlementDate == null,
                  child: InputForm().renderButton(
                    text: "Save".tr(),
                    onPressed: _settlement,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}