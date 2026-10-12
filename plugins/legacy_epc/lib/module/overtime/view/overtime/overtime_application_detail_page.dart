import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/module/customfield/model/custom_field.dart';
import 'package:epeoplecare/module/customfield/model/custom_value.dart';
import 'package:epeoplecare/module/customfield/repository/custom_field_repository.dart';
import 'package:epeoplecare/module/customfield/repository/custom_value_repository.dart';
import 'package:epeoplecare/module/customfield/view/custom_value_page.dart';
import 'package:epeoplecare/module/overtime/model/overtime_transaction_detail.dart';
import 'package:epeoplecare/provider/date_provider.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/validation/validation.dart';
import 'package:epeoplecare/view/shared/input_form.dart';
import 'package:flutter/material.dart';

class OvertimeApplicationDetailPage extends StatefulWidget {

  final OvertimeTransactionDetail? overtimeTransactionDetail;
  const OvertimeApplicationDetailPage({Key? key, this.overtimeTransactionDetail}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _OvertimeApplicationDetailPageState();
}

class _OvertimeApplicationDetailPageState extends State<OvertimeApplicationDetailPage> {
  
  final form = GlobalKey<FormState>();
  final _dateFromController = TextEditingController();
  final _dateToController = TextEditingController();
  final _durationController = TextEditingController();
  final _breakDurationController = TextEditingController();
  final _totalDurationController = TextEditingController();
  DateTime _initialDateFrom = DateTime.now();
  DateTime _initialDateTo = DateTime.now();
  final CustomFieldRepository _customFieldRepository = Repository().getCustomFieldRepository();
  final CustomValuesRepository _customValueRepository = Repository().getCustomValueRepository();
  List<CustomValue> _customValues = [];

  @override
  void initState() {
    super.initState();
    _breakDurationController.text = "0.0";
    if(widget.overtimeTransactionDetail != null) {
      _dateFromController.text = DateProvider.convertDateStrFormat(widget.overtimeTransactionDetail!.startDate, "yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd HH:mm");
      _dateToController.text = DateProvider.convertDateStrFormat(widget.overtimeTransactionDetail!.endDate, "yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd HH:mm");
      _durationController.text = widget.overtimeTransactionDetail!.duration.toString();
      _breakDurationController.text = widget.overtimeTransactionDetail!.breakDuration.toString();
      _totalDurationController.text = (widget.overtimeTransactionDetail!.duration - widget.overtimeTransactionDetail!.breakDuration!).toString();
      if(widget.overtimeTransactionDetail!.id != null) {
        _getCustomField(widget.overtimeTransactionDetail!.id!).then((value) {
          setState(() {
          _customValues = value;
          });
        });
      } else {
        _customValues = widget.overtimeTransactionDetail!.customValues;
      }
    } else {
      _initCustomField();
    }
  }

  _initCustomField() {
    _customFieldRepository.listByType("OvertimeTransactionDetail").then((items) {
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
    List<CustomField> customFields = await _customFieldRepository.listByType("OvertimeTransactionDetail");
    List<int> customFieldIds = [];
    for (CustomField customField in customFields) {
      customFieldIds.add(customField.id!);
    }

    List<CustomValue> customValuesTmp = await _customValueRepository.listByTypeAndRefId("OvertimeTransactionDetail", refId, customFieldIds);
    
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

  _setInitialDateFrom() {
    if(_dateFromController.text.isNotEmpty && _dateToController.text.isNotEmpty) {
      DateTime dateFrom = DateProvider.convertDateFormat(DateProvider.convertStr2Date(_dateFromController.text, "yyyy-MM-dd HH:mm")!, "yyyy-MM-dd HH:mm", "yyyy-MM-dd")!;
      DateTime dateTo = DateProvider.convertDateFormat(DateProvider.convertStr2Date(_dateToController.text, "yyyy-MM-dd HH:mm")!, "yyyy-MM-dd HH:mm", "yyyy-MM-dd")!;
      if(dateFrom.compareTo(dateTo) > 0) {
          _initialDateFrom = dateTo;
      } else {
        _initialDateFrom = dateFrom;
      }
    } else if(_dateToController.text.isNotEmpty) {
      DateTime dateTo = DateProvider.convertDateFormat(DateProvider.convertStr2Date(_dateToController.text, "yyyy-MM-dd HH:mm")!, "yyyy-MM-dd HH:mm", "yyyy-MM-dd")!;
      if(dateTo.compareTo(DateTime.now()) < 0) {
          _initialDateFrom = dateTo;
      }
    } else if (_dateFromController.text.isNotEmpty) {
      DateTime dateFrom = DateProvider.convertDateFormat(DateProvider.convertStr2Date(_dateFromController.text, "yyyy-MM-dd HH:mm")!, "yyyy-MM-dd HH:mm", "yyyy-MM-dd")!;
      _initialDateFrom = dateFrom;
    }
  }

  _setInitialDateTo() {
    if(_dateFromController.text.isNotEmpty && _dateToController.text.isNotEmpty) {
      DateTime dateFrom = DateProvider.convertDateFormat(DateProvider.convertStr2Date(_dateFromController.text, "yyyy-MM-dd HH:mm")!, "yyyy-MM-dd HH:mm", "yyyy-MM-dd")!;
      DateTime dateTo = DateProvider.convertDateFormat(DateProvider.convertStr2Date(_dateToController.text, "yyyy-MM-dd HH:mm")!, "yyyy-MM-dd HH:mm", "yyyy-MM-dd")!;
      if(dateFrom.compareTo(dateTo) > 0) {
          _initialDateTo = dateFrom;
      } else {
        _initialDateTo = dateTo;
      }
    } else if(_dateFromController.text.isNotEmpty) {
      DateTime dateFrom = DateProvider.convertDateFormat(DateProvider.convertStr2Date(_dateFromController.text, "yyyy-MM-dd HH:mm")!, "yyyy-MM-dd HH:mm", "yyyy-MM-dd")!;
      if(dateFrom.compareTo(DateTime.now()) > 0) {
          _initialDateTo = dateFrom;
      }
    } else if (_dateToController.text.isNotEmpty) {
      DateTime dateTo = DateProvider.convertDateFormat(DateProvider.convertStr2Date(_dateToController.text, "yyyy-MM-dd HH:mm")!, "yyyy-MM-dd HH:mm", "yyyy-MM-dd")!;
      _initialDateTo = dateTo;
    }
  }

  _calculateDuration() {
    if(_dateFromController.text != "" && _dateToController.text != "") {
      var dateFrom = DateProvider.convertStr2Date(_dateFromController.text, "yyyy-MM-dd HH:mm");
      var dateTo = DateProvider.convertStr2Date(_dateToController.text, "yyyy-MM-dd HH:mm");
      int diffMinutes = dateTo!.difference(dateFrom!).inMinutes;
      _durationController.text = (diffMinutes/60).toStringAsFixed(2);
    }
  }

  _calculateTotalDuration() {
    if(_durationController.text != "" && _breakDurationController.text != "") {
      double totalDuration = double.parse(_durationController.text) - double.parse(_breakDurationController.text);
      _totalDurationController.text = totalDuration.toString();
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
                child: InputForm().renderDateTimeField(
                  fieldName: "Date From".tr(),
                  initialDate: _initialDateFrom,
                  firstDate: DateTime(1990),
                  lastDate: _dateToController.text.isNotEmpty
                            ? DateProvider.convertStr2Date(_dateToController.text, "yyyy-MM-dd HH:mm")!
                            : DateTime(2050),
                  controller: _dateFromController,
                  validator: Validation.validateField,
                  onChanged: (value) {
                    if (value == null) return;

                    _dateFromController.text = DateProvider.convertDate2Str(value, "yyyy-MM-dd HH:mm");
                    _calculateDuration();
                    _calculateTotalDuration();
                    setState(() {
                      _setInitialDateFrom();
                    });
                  }
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: InputForm().renderDateTimeField(
                  fieldName: "Date To".tr(),
                  initialDate: _initialDateTo,
                  firstDate: _dateFromController.text.isNotEmpty 
                            ? DateProvider.convertStr2Date(_dateFromController.text, "yyyy-MM-dd HH:mm")!
                            : DateTime(1990),
                  lastDate: DateTime(2050),
                  controller: _dateToController,
                  validator: (val) {
                    if(val == null || val.isEmpty) {
                      return "This field is required".tr();
                    }
                    if(val.isNotEmpty && _dateFromController.text.isNotEmpty) {
                      var dateFrom = DateProvider.convertStr2Date(_dateFromController.text, "yyyy-MM-dd HH:mm");
                      var dateTo = DateProvider.convertStr2Date(val, "yyyy-MM-dd HH:mm");
                      if(!dateFrom!.isBefore(dateTo!)) {
                        return "End time must be greater than Start time".tr();
                      }
                    }
                    return null;
                  },
                  onChanged: (value) {
                    if (value == null) return;

                    _dateToController.text = DateProvider.convertDate2Str(value, "yyyy-MM-dd HH:mm");
                    _calculateDuration();
                    _calculateTotalDuration();
                    setState(() {
                      _setInitialDateTo();
                    });
                  }
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: InputForm().renderTextField(
                  fieldName: "Duration".tr(),
                  controller: _durationController,
                  validator: (val) {
                    if(val == null || val.isEmpty) {
                      return "This field is required".tr();
                    }
                    if(double.parse(val) <= 0) {
                      return "Duration must be greater than 0".tr();
                    }
                    return null;
                  },
                  enabled: false,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: InputForm().renderTextField(
                  textInputType: TextInputType.number,
                  fieldName: "Break Duration".tr(),
                  controller: _breakDurationController,
                  validator: (val) {
                    if(val == null || val.isEmpty) {
                      return "This field is required".tr();
                    }
                    return null;
                  },
                  onChanged: (val) {
                    _calculateTotalDuration();
                  }
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: InputForm().renderTextField(
                  fieldName: "Total Duration".tr(),
                  controller: _totalDurationController,
                  enabled: false,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: CustomValuesPage(
                  customValues: _customValues,
                  editMode: widget.overtimeTransactionDetail != null ? true : false,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: InputForm().renderButton(
                  text: (widget.overtimeTransactionDetail != null ? "Update" : "Add").tr(),
                  onPressed: () async {
                    if (form.currentState!.validate()) {
                      OvertimeTransactionDetail detail = OvertimeTransactionDetail(
                        widget.overtimeTransactionDetail != null ? widget.overtimeTransactionDetail!.id : null,
                        widget.overtimeTransactionDetail != null ? widget.overtimeTransactionDetail!.creator : null,
                        widget.overtimeTransactionDetail != null ? widget.overtimeTransactionDetail!.creationTime : null,
                        widget.overtimeTransactionDetail != null ? widget.overtimeTransactionDetail!.updater : null,
                        widget.overtimeTransactionDetail != null ? widget.overtimeTransactionDetail!.updateTime : null,
                        widget.overtimeTransactionDetail != null ? widget.overtimeTransactionDetail!.version : null,
                        _customValues,
                        widget.overtimeTransactionDetail != null ? widget.overtimeTransactionDetail!.medias : null,
                        widget.overtimeTransactionDetail != null ? widget.overtimeTransactionDetail!.overtimeTransaction : null,
                        DateProvider.convertDateStrFormat(_dateFromController.text, "yyyy-MM-dd HH:mm", "yyyy-MM-dd HH:mm:ss"),
                        DateProvider.convertDateStrFormat(_dateToController.text, "yyyy-MM-dd HH:mm", "yyyy-MM-dd HH:mm:ss"),
                        double.parse(_durationController.text != "" ? _durationController.text : "0.0"),
                        double.parse(_breakDurationController.text != "" ? _breakDurationController.text : "0.0"),
                      );
                      
                      Navigator.of(context).pop(detail);
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