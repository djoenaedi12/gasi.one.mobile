// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/dropdown.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/model/employee/employee_dependent.dart';
import 'package:epeoplecare/module/benefit/model/benefit.dart';
import 'package:epeoplecare/module/benefit/repository/benefit_repository.dart';
import 'package:epeoplecare/module/benefit/repository/benefit_transaction_repository.dart';
import 'package:epeoplecare/module/customfield/model/custom_field.dart';
import 'package:epeoplecare/module/customfield/model/custom_value.dart';
import 'package:epeoplecare/module/customfield/repository/custom_field_repository.dart';
import 'package:epeoplecare/module/customfield/repository/custom_value_repository.dart';
import 'package:epeoplecare/module/customfield/view/custom_value_page.dart';
import 'package:epeoplecare/module/benefit/model/benefit_transaction_detail.dart';
import 'package:epeoplecare/provider/alert_provider.dart';
import 'package:epeoplecare/provider/date_provider.dart';
import 'package:epeoplecare/provider/number_provider.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/validation/validation.dart';
import 'package:epeoplecare/view/shared/input_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class BenefitApplicationDetailPage extends StatefulWidget {

  final BenefitTransactionDetail? benefitTransactionDetail;
  final EmployeeDependent? employeeDependent;
  final List<BenefitTransactionDetail> benefitTransactionDetails;
  final Employee? employee;
  const BenefitApplicationDetailPage({Key? key, this.benefitTransactionDetail, this.employeeDependent, this.benefitTransactionDetails = const [], this.employee}): super(key: key);

  @override
  State<StatefulWidget> createState() => _BenefitApplicationDetailPageState();
}

class _BenefitApplicationDetailPageState extends State<BenefitApplicationDetailPage> {
  
  final form = GlobalKey<FormState>();
  final CustomFieldRepository _customFieldRepository = Repository().getCustomFieldRepository();
  final CustomValuesRepository _customValueRepository = Repository().getCustomValueRepository();
  List<CustomValue> _customValues = [];
  Benefit? _valBenefit;
  List<Dropdown> benefits = [];
  final _incidentDateController = TextEditingController();
  final _requestedAmountController = TextEditingController();
  final _approvedAmountController = TextEditingController();
  final BenefitRepository _benefitRepository = Repository().getBenefitRepository();
  final BenefitTransactionRepository _benefitRequestRepository = Repository().getBenefitTransactionRepository();
  final _balanceController = TextEditingController();
  bool calcApprovedAmount = false;

  @override
  void initState() {
    super.initState();
    _balanceController.text = "0.00";
    _approvedAmountController.text = "0.00";
    if(widget.benefitTransactionDetail != null) {
      _incidentDateController.text = DateProvider.convertDateStrFormat(widget.benefitTransactionDetail!.incidentDate, "yyyy-MM-dd", "yyyy-MM-dd");
      _requestedAmountController.text = widget.benefitTransactionDetail!.requestedAmount.toString();
      _approvedAmountController.text = NumberProvider.decimalFormatDouble(widget.benefitTransactionDetail!.approvedAmount);
      if(widget.benefitTransactionDetail!.id != null) {
        _getCustomField(widget.benefitTransactionDetail!.id!).then((value) {
          setState(() {
          _customValues = value;
          });
        });
      } else {
        _customValues = widget.benefitTransactionDetail!.customValues;
      }
    } else {
      _initCustomField();
    }
    _getBenefit();
  }

  _getBenefit() {
    Dropdown dropdown = Dropdown(
        value: null,
        label: "Select Benefit".tr());
    benefits.add(dropdown);
    _benefitRepository.list().then((value) async {
      if (value.isEmpty) return;

      setState(() {
        for (var i = 0; i < value.length; i++) {
          Dropdown dropdown =
              Dropdown(value: value[i], label: value[i].name);
          if (widget.benefitTransactionDetail != null &&
              widget.benefitTransactionDetail!.benefit!.id == value[i].id) {
            _valBenefit = dropdown.value;
          }

          benefits.add(dropdown);
        }
      });
      getBalance();
    });
  }

  _calculateApprovedAmount() async {
    if (_valBenefit != null && _requestedAmountController.text.isNotEmpty) {
      List<int> prevBenefit = [];
      List<double> prevAmount = [];
      for (var benefitTransactionDetail in widget.benefitTransactionDetails) {
        prevBenefit.add(benefitTransactionDetail.benefit!.id!);
        prevAmount.add(benefitTransactionDetail.approvedAmount!);
      }

      EasyLoading.show(status: "Please Wait".tr()).then((value) async {
        double approvedAmount = await _benefitRequestRepository.getApprovedAmount(_valBenefit!, double.parse(_requestedAmountController.text), widget.employeeDependent, widget.employee, prevBenefit, prevAmount, widget.benefitTransactionDetail != null ? widget.benefitTransactionDetail!.benefitTransaction : null);
        _approvedAmountController.text = NumberProvider.decimalFormatDouble(approvedAmount);
        EasyLoading.dismiss();
      });
    }
  }

  getBalance() {
    if (_valBenefit != null && _valBenefit!.nonBalance == false) {
      _benefitRequestRepository.getBalance(_valBenefit!, DateProvider.getCurrentDate(), widget.employee!, widget.benefitTransactionDetail?.benefitTransaction).then((value) async {
        _balanceController.text = NumberProvider.decimalFormatDouble(value);
      });
    }
  }

  _initCustomField() {
    _customFieldRepository.listByType("BenefitTransactionDetail").then((items) {
      for (CustomField item in items) {
        setState(() {
          CustomValue customValue = CustomValue(
            null, 
            null, 
            null, 
            null, 
            null, 
            null, 
            null, 
            null, 
            item, 
            item.type, 
            null, 
            null,
          );

          _customValues.add(customValue);
        });
      }
    });
  }

  Future<List<CustomValue>> _getCustomField(int refId) async {
    List<CustomField> customFields = await _customFieldRepository.listByType("BenefitTransactionDetail");
    List<int> customFieldIds = [];
    for (CustomField customField in customFields) {
      customFieldIds.add(customField.id!);
    }

    List<CustomValue> customValuesTmp = await _customValueRepository.listByTypeAndRefId("BenefitTransactionDetail", refId, customFieldIds);
    
    bool isExist = false;
    for (CustomField customField in customFields) {
      isExist = false;
      for (CustomValue customValue in customValuesTmp) {
        if (customValue.customField!.id == customField.id) {
            isExist = true;
            break;
        }
      }

      if (!isExist) {
        setState(() {
          CustomValue customValue = CustomValue(
            null, 
            null, 
            null, 
            null, 
            null, 
            null, 
            null, 
            null, 
            customField, 
            customField.type, 
            null, 
            null,
          );

          _customValues.add(customValue);
        });
      }
    }  

    return _customValues;  
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
          "Application Form Detail".tr(),
          style: TextStyle(
            color: Config.DEFAULT_ACCENT_COLOR,
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Form(
          key: form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 5.0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: InputForm().renderDropdownField(
                    fieldName: "Benefit".tr(),
                    value: _valBenefit,
                    listItem: benefits,
                    onChanged: (val) {
                      setState(() {
                        _valBenefit = val as Benefit?;
                        _calculateApprovedAmount();
                        getBalance();
                      });
                    },
                    validator: (val) {
                      if (val == null) {
                        return "This field is required".tr();
                      }
                      return null;
                    }),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: InputForm().renderDateField(
                  fieldName: "Incident Date".tr(),
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1990),
                  lastDate: DateTime(2050),
                  controller: _incidentDateController,
                  validator: Validation.validateField,
                  onChanged: (value) {
                    if (value == null) return;
                    
                    _incidentDateController.text = DateProvider.convertDate2Str(value, "yyyy-MM-dd");
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: InputForm().renderTextField(
                  fieldName: "Requested Amount".tr(),
                  controller: _requestedAmountController,
                  validator: Validation.validateField,
                  textInputType: TextInputType.number,
                  onFieldSubmitted: (val){
                    setState(() {
                      calcApprovedAmount = false;
                      _calculateApprovedAmount();
                    });
                  },
                  onChanged: (val) {
                    setState(() {
                      calcApprovedAmount = true;
                    });
                  }
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: InputForm().renderTextField(
                  fieldName: "Approved Amount".tr(),
                  controller: _approvedAmountController,
                  validator: Validation.validateField,
                  enabled: false,
                ),
              ),
              Visibility(
                visible: _valBenefit != null && _valBenefit!.nonBalance == false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: InputForm().renderTextField(
                    fieldName: "Balance".tr(),
                    controller: _balanceController,
                    enabled: false,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: CustomValuesPage(
                  customValues: _customValues,
                  editMode: widget.benefitTransactionDetail != null ? true : false,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: InputForm().renderButton(
                  text: (widget.benefitTransactionDetail != null ? "Update" : "Add").tr(),
                  onPressed: () async {
                    if (form.currentState!.validate()) {
                      if(calcApprovedAmount) {
                          calcApprovedAmount = false;
                          await _calculateApprovedAmount();                          
                      }

                      double requestedAmount = double.parse(_requestedAmountController.text.replaceAll(",", ""));
                      double approvedAmount = double.parse(_approvedAmountController.text.replaceAll(",", ""));
                      if(requestedAmount != approvedAmount) {
                        AlertProvider.showConfirmationDialog(
                          message: "${"Approved amount not the same with requested amount".tr()}\n${"Do you want to continue".tr()}?",
                        ).then((value) {
                          if(value == false) return;

                          BenefitTransactionDetail detail = BenefitTransactionDetail(
                            widget.benefitTransactionDetail != null ? widget.benefitTransactionDetail!.id : null,
                            widget.benefitTransactionDetail != null ? widget.benefitTransactionDetail!.creator : null,
                            widget.benefitTransactionDetail != null ? widget.benefitTransactionDetail!.creationTime : null,
                            widget.benefitTransactionDetail != null ? widget.benefitTransactionDetail!.updater : null,
                            widget.benefitTransactionDetail != null ? widget.benefitTransactionDetail!.updateTime : null,
                            widget.benefitTransactionDetail != null ? widget.benefitTransactionDetail!.version : null,
                            _customValues,
                            widget.benefitTransactionDetail != null ? widget.benefitTransactionDetail!.medias : null,
                            widget.benefitTransactionDetail != null ? widget.benefitTransactionDetail!.benefitTransaction : null,
                            _valBenefit,
                            DateProvider.convertDateStrFormat(_incidentDateController.text, "yyyy-MM-dd", "yyyy-MM-dd HH:mm:ss"),
                            double.parse(_requestedAmountController.text.replaceAll(",", "")),
                            double.parse(_approvedAmountController.text.replaceAll(",", "")),
                            double.parse(_balanceController.text.replaceAll(",", "")),
                          );
                          
                          Navigator.of(context).pop(detail);
                        });
                      } else {
                        BenefitTransactionDetail detail = BenefitTransactionDetail(
                          widget.benefitTransactionDetail != null ? widget.benefitTransactionDetail!.id : null,
                          widget.benefitTransactionDetail != null ? widget.benefitTransactionDetail!.creator : null,
                          widget.benefitTransactionDetail != null ? widget.benefitTransactionDetail!.creationTime : null,
                          widget.benefitTransactionDetail != null ? widget.benefitTransactionDetail!.updater : null,
                          widget.benefitTransactionDetail != null ? widget.benefitTransactionDetail!.updateTime : null,
                          widget.benefitTransactionDetail != null ? widget.benefitTransactionDetail!.version : null,
                          _customValues,
                          widget.benefitTransactionDetail != null ? widget.benefitTransactionDetail!.medias : null,
                          widget.benefitTransactionDetail != null ? widget.benefitTransactionDetail!.benefitTransaction : null,
                          _valBenefit,
                          DateProvider.convertDateStrFormat(_incidentDateController.text, "yyyy-MM-dd", "yyyy-MM-dd HH:mm:ss"),
                          double.parse(_requestedAmountController.text.replaceAll(",", "")),
                          double.parse(_approvedAmountController.text.replaceAll(",", "")),
                          double.parse(_balanceController.text.replaceAll(",", "")),
                        );
                        
                        Navigator.of(context).pop(detail);
                      }
                    }
                  }
                ),
              ),
              const SizedBox(height: 10.0),
            ],
          ),
        ),
      ),
    );
  }
}