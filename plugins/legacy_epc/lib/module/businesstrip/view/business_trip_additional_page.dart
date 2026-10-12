import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/company/currency.dart';
import 'package:epeoplecare/module/businesstrip/model/allowance.dart';
import 'package:epeoplecare/module/businesstrip/model/business_trip_request_allowance.dart';
import 'package:epeoplecare/module/businesstrip/view/allowance_picker.dart';
import 'package:epeoplecare/provider/date_provider.dart';
import 'package:epeoplecare/validation/validation.dart';
import 'package:epeoplecare/view/shared/currency_picker.dart';
import 'package:epeoplecare/view/shared/input_form.dart';
import 'package:flutter/material.dart';

class BusinessTripAdditionalPage extends StatefulWidget {
  final BusinessTripRequestAllowance? businessTripRequestAllowance;
  const BusinessTripAdditionalPage({Key? key, this.businessTripRequestAllowance}): super(key: key);

  @override
  State<StatefulWidget> createState() => _BusinessTripAdditionalPageState();
}

class _BusinessTripAdditionalPageState extends State<BusinessTripAdditionalPage> {

  final form = GlobalKey<FormState>();
  Currency? _valCurrency;
  Allowance? _valAllowance;
  final _dateController = TextEditingController();
  final _currencyController = TextEditingController();
  final _allowanceController = TextEditingController();
  final _amountController = TextEditingController();
  final _remarkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if(widget.businessTripRequestAllowance != null) {
      _valCurrency = widget.businessTripRequestAllowance!.currency;
      _valAllowance = widget.businessTripRequestAllowance!.allowance;
      _currencyController.text = _valCurrency!.code;
      _allowanceController.text = _valAllowance!.name;
      _dateController.text = DateProvider.convertDateStrFormat(widget.businessTripRequestAllowance!.date, "yyyy-MM-dd", "yyy-MM-dd");
      _amountController.text = widget.businessTripRequestAllowance!.actualAmount.toString();
      _remarkController.text = widget.businessTripRequestAllowance!.remark ?? "";
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
          "Additional Allowance".tr(),
          style: TextStyle(
            color: Config.DEFAULT_ACCENT_COLOR,
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: Form(
        key: form,
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 5.0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: InputForm().renderDateField(
                  fieldName: "Date".tr(),
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1990),
                  lastDate: DateTime(2050),
                  controller: _dateController,
                  validator: Validation.validateField,
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      _dateController.text = DateProvider.convertDate2Str(value, "yyyy-MM-dd");                      
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: InputForm().renderCustomField(
                  fieldName: "Allowance".tr(),
                  controller: _allowanceController,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AllowancePicker(
                          allowance: _valAllowance,
                        )
                      ),
                    ).then((value) {
                      if(value == null) return;

                      setState(() {
                        _valAllowance = value;
                        _allowanceController.text = _valAllowance!.name;
                      });
                    });
                  }
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: InputForm().renderCustomField(
                  fieldName: "Currency".tr(),
                  controller: _currencyController,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CurrencyPicker(
                          currency: _valCurrency,
                        )
                      ),
                    ).then((value) {
                      if(value == null) return;

                      setState(() {
                        _valCurrency = value;
                        _currencyController.text = _valCurrency!.code;
                      });
                    });
                  }
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: InputForm().renderTextField(
                  initialValue: "",
                  fieldName: "Amount".tr(),
                  controller: _amountController,
                  validator: Validation.validateField,
                  textInputType: TextInputType.number,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: InputForm().renderTextField(
                  initialValue: "",
                  fieldName: "Remark".tr(),
                  controller: _remarkController,
                  maxLines: 5,
                  maxLength: 100,
                  textInputType: TextInputType.multiline,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: InputForm().renderButton(
                  text: (widget.businessTripRequestAllowance != null ? "Update" : "Add").tr(),
                  onPressed: () async {
                    if (form.currentState!.validate()) {
                      
                      BusinessTripRequestAllowance allowance = BusinessTripRequestAllowance(
                        widget.businessTripRequestAllowance != null ? widget.businessTripRequestAllowance!.id : null,
                        widget.businessTripRequestAllowance != null ? widget.businessTripRequestAllowance!.creator : null,
                        widget.businessTripRequestAllowance != null ? widget.businessTripRequestAllowance!.creationTime : null,
                        widget.businessTripRequestAllowance != null ? widget.businessTripRequestAllowance!.updater : null,
                        widget.businessTripRequestAllowance != null ? widget.businessTripRequestAllowance!.updateTime : null,
                        widget.businessTripRequestAllowance != null ? widget.businessTripRequestAllowance!.version : null,
                        widget.businessTripRequestAllowance != null ? widget.businessTripRequestAllowance!.customValues : null,
                        widget.businessTripRequestAllowance != null ? widget.businessTripRequestAllowance!.medias : null,
                        widget.businessTripRequestAllowance != null ? widget.businessTripRequestAllowance!.businessTripRequestDetail : null,
                        DateProvider.convertDateStrFormat(_dateController.text, "yyyy-MM-dd", "yyyy-MM-dd"),
                        _valAllowance,
                        _valCurrency,
                        0.0,
                        double.parse(_amountController.text),
                        double.parse(_amountController.text),
                        _remarkController.text,
                        false,
                        true,
                        true,
                        0.0,
                        true,
                      );
                      
                      Navigator.of(context).pop(allowance);
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