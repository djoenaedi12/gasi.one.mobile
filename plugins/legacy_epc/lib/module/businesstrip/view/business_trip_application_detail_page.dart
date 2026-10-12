// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/dropdown.dart';
import 'package:epeoplecare/module/businesstrip/model/business_trip_request_allowance.dart';
import 'package:epeoplecare/module/businesstrip/model/business_trip_request_detail.dart';
import 'package:epeoplecare/module/businesstrip/model/destination.dart';
import 'package:epeoplecare/module/businesstrip/model/purpose.dart';
import 'package:epeoplecare/module/businesstrip/repository/business_trip_request_allowance_repository.dart';
import 'package:epeoplecare/module/businesstrip/repository/destination_repository.dart';
import 'package:epeoplecare/module/businesstrip/repository/purpose_repository.dart';
import 'package:epeoplecare/provider/date_provider.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/validation/validation.dart';
import 'package:epeoplecare/view/shared/input_form.dart';
import 'package:flutter/material.dart';

class BusinessTripApplicationDetailPage extends StatefulWidget {

  final BusinessTripRequestDetail? businessTripRequestDetail;
  final bool deductionVisibility;
  const BusinessTripApplicationDetailPage({Key? key, this.businessTripRequestDetail, this.deductionVisibility=false}) : super(key: key);

  @override
  State<StatefulWidget>  createState() => _BusinessTripApplicationDetailPageState();
}

class _BusinessTripApplicationDetailPageState extends State<BusinessTripApplicationDetailPage> {
  
  final form = GlobalKey<FormState>();
  Purpose? _valPurpose;
  List<Dropdown> purposes = [];
  Destination? _valDestination;
  List<Dropdown> destinations = [];
  final _dateFromController = TextEditingController();
  final _dateToController = TextEditingController();
  final _providedLunchController = TextEditingController();
  final _providedDinnerController = TextEditingController();
  DateTime _initialDateFrom = DateTime.now();
  DateTime _initialDateTo = DateTime.now();
  final PurposeRepository _purposeRepository = Repository().getPurposeRepository();
  final DestinationRepository _destinationRepository = Repository().getDestinationRepository();
  final BusinessTripRequestAllowanceRepository _businessTripRequestAllowanceRepository = Repository().getBusinessTripRequestAllowanceRepository();

  @override
  void initState() {
    super.initState();
    _getPurpose();
    _getDestination();
    if(widget.businessTripRequestDetail != null) {
      _dateFromController.text = DateProvider.convertDateStrFormat(widget.businessTripRequestDetail!.dateFrom, "yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd HH:mm");
      _dateToController.text = DateProvider.convertDateStrFormat(widget.businessTripRequestDetail!.dateTo, "yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd HH:mm");
    }
  }

  _getPurpose() {
    Dropdown dropdown = Dropdown(value: null, label: "Select Purpose".tr());
    purposes.add(dropdown);
    _purposeRepository.list().then((value) async {
      if(value.isEmpty) return;

      setState(() {
        for (var i = 0; i < value.length; i++) {
          Dropdown dropdown = Dropdown(value: value[i], label:  value[i].name);
          if(widget.businessTripRequestDetail != null && widget.businessTripRequestDetail!.purpose!.id == value[i].id) {
            _valPurpose = dropdown.value;
          }

          purposes.add(dropdown);
        }
      });
    });
  }

  _getDestination() {
    Dropdown dropdown = Dropdown(value: null, label: "Select Destination".tr());
    destinations.add(dropdown);
    _destinationRepository.list().then((value) async {
      if(value.isEmpty) return;

      setState(() {
        for (var i = 0; i < value.length; i++) {
          Dropdown dropdown = Dropdown(value: value[i], label: value[i].name);
          if(widget.businessTripRequestDetail != null && widget.businessTripRequestDetail!.destination!.id == value[i].id) {
            _valDestination = dropdown.value;
          }

          destinations.add(dropdown);
        }
      });
    });
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
                  fieldName: "Purpose".tr(),
                  value: _valPurpose,
                  listItem: purposes,
                  onChanged: (val) {
                    setState(() {
                      _valPurpose = val as Purpose?;
                    });
                  },
                  validator: (val) {
                    if(val == null) {
                      return "This field is required".tr();
                    }
                    return null;
                  }
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: InputForm().renderDropdownField(
                  fieldName: "Destination".tr(),
                  value: _valDestination,
                  listItem: destinations,
                  onChanged: (val) {
                    setState(() {
                      _valDestination = val as Destination?;
                    });
                  },
                  validator: (val) {
                    if(val == null) {
                      return "This field is required".tr();
                    }
                    return null;
                  }
                ),
              ),
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
                    setState(() {
                      _setInitialDateTo();
                    });
                  }
                ),
              ),
              Visibility(
                visible: widget.deductionVisibility,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: InputForm().renderTextField(
                    fieldName: "Provided Lunch".tr(),
                    controller: _providedLunchController,
                    textInputType: TextInputType.number,
                  ),
                ),
              ),
              Visibility(
                visible: widget.deductionVisibility,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: InputForm().renderTextField(
                    fieldName: "Provided Dinner".tr(),
                    controller: _providedDinnerController,
                    textInputType: TextInputType.number,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: InputForm().renderButton(
                  text: (widget.businessTripRequestDetail != null ? "Update" : "Add").tr(),
                  onPressed: () async {
                    if (form.currentState!.validate()) {
                      List<BusinessTripRequestAllowance> allowances = await _businessTripRequestAllowanceRepository.calculate(Config.user!.employee!, _valPurpose!, _valDestination!, DateProvider.convertStr2Date(_dateFromController.text, "yyyy-MM-dd HH:mm")!, DateProvider.convertStr2Date(_dateToController.text, "yyyy-MM-dd HH:mm")!, int.parse(_providedLunchController.text != "" ? _providedLunchController.text : "0"), int.parse(_providedDinnerController.text != "" ? _providedDinnerController.text : "0"));
                      BusinessTripRequestDetail detail = BusinessTripRequestDetail(
                        widget.businessTripRequestDetail != null ? widget.businessTripRequestDetail!.id : null,
                        widget.businessTripRequestDetail != null ? widget.businessTripRequestDetail!.creator : null,
                        widget.businessTripRequestDetail != null ? widget.businessTripRequestDetail!.creationTime : null,
                        widget.businessTripRequestDetail != null ? widget.businessTripRequestDetail!.updater : null,
                        widget.businessTripRequestDetail != null ? widget.businessTripRequestDetail!.updateTime : null,
                        widget.businessTripRequestDetail != null ? widget.businessTripRequestDetail!.version : null,
                        widget.businessTripRequestDetail != null ? widget.businessTripRequestDetail!.customValues : null,
                        widget.businessTripRequestDetail != null ? widget.businessTripRequestDetail!.medias : null,
                        widget.businessTripRequestDetail != null ? widget.businessTripRequestDetail!.businessTripRequest : null,
                        _valDestination,
                        _valPurpose,
                        DateProvider.convertDateStrFormat(_dateFromController.text, "yyyy-MM-dd HH:mm", "yyyy-MM-dd HH:mm:ss"),
                        DateProvider.convertDateStrFormat(_dateToController.text, "yyyy-MM-dd HH:mm", "yyyy-MM-dd HH:mm:ss"),
                        allowances,
                        int.parse(_providedLunchController.text != "" ? _providedLunchController.text : "0"),
                        int.parse(_providedDinnerController.text != "" ? _providedDinnerController.text : "0"),
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