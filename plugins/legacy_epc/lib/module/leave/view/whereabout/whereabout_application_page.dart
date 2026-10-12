// ignore_for_file: use_build_context_synchronously

import 'dart:collection';
import 'dart:io';

import 'package:datetime_setting/datetime_setting.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/custom_value.dart';
import 'package:epeoplecare/model/dropdown.dart';
import 'package:epeoplecare/module/customfield/model/custom_field.dart';
import 'package:epeoplecare/module/customfield/model/custom_value.dart';
import 'package:epeoplecare/module/customfield/repository/custom_field_repository.dart';
import 'package:epeoplecare/module/customfield/view/custom_value_page.dart';
import 'package:epeoplecare/module/leave/model/whereabout_category.dart';
import 'package:epeoplecare/module/leave/model/whereabout_status.dart';
import 'package:epeoplecare/module/leave/model/whereabout_transaction.dart';
import 'package:epeoplecare/provider/alert_provider.dart';
import 'package:epeoplecare/provider/date_provider.dart';
import 'package:epeoplecare/provider/geolocation_provider.dart';
import 'package:epeoplecare/repository/file_repository.dart';
import 'package:epeoplecare/repository/media_repository.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/module/leave/repository/whereabout_transaction_repository.dart';
import 'package:epeoplecare/validation/validation.dart';
import 'package:epeoplecare/view/shared/input_form.dart';
import 'package:epeoplecare/view/shared/message.dart';
import 'package:epeoplecare/view/shared/multiple_attachment_page.dart';
import 'package:epeoplecare/view/shared/picker_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class WhereaboutApplicationPage extends StatefulWidget {
  const WhereaboutApplicationPage({super.key});

  @override
  State<StatefulWidget> createState() => _WhereaboutApplicationPageState();
}

class _WhereaboutApplicationPageState extends State<WhereaboutApplicationPage> {
  final form = GlobalKey<FormState>();
  WhereaboutCategory? _valWhereaboutCategory;
  List<Dropdown> whereaboutCategory = [
    Dropdown(value: null, label: "Select Whereabouts Category".tr()),
    Dropdown(value: WhereaboutCategory.DAILY_ROUTINE, label: WhereaboutCategory.DAILY_ROUTINE.toString().tr()),
    Dropdown(value: WhereaboutCategory.CLIENT_MEETING, label: WhereaboutCategory.CLIENT_MEETING.toString().tr()),
    Dropdown(value: WhereaboutCategory.OTHER, label: WhereaboutCategory.OTHER.toString().tr()),
  ];
  final WhereaboutRepository _whereaboutRepository = Repository().getWhereaboutRepository();
  final FileRepository _fileRepository = Repository().getFileRepository();
  
  final _dateController = TextEditingController();
  final _timeFromController = TextEditingController();
  final _timeToController = TextEditingController();
  final _durationController = TextEditingController();
  final _remarkController = TextEditingController();
  final _destinationController = TextEditingController();
  final _contactPersonController = TextEditingController();
  File? _attachmentFile;
  String? _alternateAttachment;
  final CustomFieldRepository _customFieldRepository = Repository().getCustomFieldRepository();
  List<CustomValue> customValues = [];
  final MediaRepository _mediaRepository = Repository().getMediaRepository();
  List<Media> _medias = [];
  final GeolocationProvider _geolocationProvider = GeolocationProvider();
  List<Widget> actions = [
    TextButton(
      child: Text("Cancel".tr()),
      onPressed: () {
        Navigator.pop(Config.navigatorKey.currentContext!);
      },
    ),
    TextButton(
      child: Text("Open Setting".tr()),
      onPressed: () {
        openAppSettings();
        Navigator.pop(Config.navigatorKey.currentContext!);
      },
    ),
  ];
  Position? _currentCoordinate;
  String _currentLocation = "";

  @override
  void initState() {
    super.initState();
    if(Config.user!.employee != null) {
      _contactPersonController.text = Config.user!.employee!.phoneNumber ?? "";
    }

    _initCustomField();
  }

  _initCustomField() {
    _customFieldRepository.listByType("WhereaboutTransaction").then((items) {
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

          customValues.add(customValue);
        });
      }
    });
  }

  _submitForm() async {
    if(Platform.isAndroid) {
      bool timeIsAuto = await DatetimeSetting.timeIsAuto();
      bool timeZoneIsAuto = await DatetimeSetting.timeZoneIsAuto();
      if(!timeIsAuto || !timeZoneIsAuto) {
        AlertProvider.showAlertDialog(
          title: "Enable Automatic Date & Time".tr(),
          message: "Please enable automatic date & time configuration to continue using the application".tr(),
        );
        return;
      }
    }
    
    if (form.currentState!.validate()) {
      EasyLoading.show(status: "Please Wait".tr());
      if(_attachmentFile != null) {
        try {
        dynamic uploadRes = await _fileRepository.upload(_attachmentFile!, "file");

        if(uploadRes.success == true) {
          _alternateAttachment = uploadRes.data;
          _attachmentFile = null;
        } else {
          return;
        } 
        } catch (onError) {
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
        }
      }
      
      WhereaboutTransaction whereaboutTransaction = WhereaboutTransaction(
        null, 
        null, 
        null, 
        null, 
        null, 
        null,
        customValues,
        Config.excludeOldAttachment(_medias),
        DateProvider.convertDateStrFormat(_dateController.text, "yyyy-MM-dd", "yyyy-MM-dd"),
        DateProvider.convertDateStrFormat(_timeFromController.text, "HH:mm", "HH:mm:ss"),
        DateProvider.convertDateStrFormat(_timeToController.text, "HH:mm", "HH:mm:ss"),
        DateProvider.convertDateStrFormat(_durationController.text, "HH:mm", "HH:mm:ss"),
        _remarkController.text,
        Config.oldAttachment(_alternateAttachment, _medias),
        null,
        null,
        _valWhereaboutCategory,
        WhereaboutStatus.OPEN,
        Config.user!.employee, 
        _destinationController.text,
        _contactPersonController.text,
        "",
      );
      _whereaboutRepository.save(entity: whereaboutTransaction).then((value) {
        EasyLoading.dismiss();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessagePage(
              icon: const Icon(Icons.check_circle, size: 100, color: Colors.green),
              title: "Success".tr(),
              subTitle: "Data has been saved".tr(),
            ),
          ),
        ).then((value) {
          Navigator.pop(context, true);
        });
      }).catchError((onError) {
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

  _calculateDuration() {
    if(_timeFromController.text != "" && _timeToController.text != "") {
      var now = DateTime.now();
      var timeFromTmp = _timeFromController.text.split(":");
      var timeToTmp = _timeToController.text.split(":");
      var timeFrom = DateTime(now.year, now.month, now.day, int.parse(timeFromTmp[0]), int.parse(timeFromTmp[1]));
      var timeTo = DateTime(now.year, now.month, now.day, int.parse(timeToTmp[0]), int.parse(timeToTmp[1]));
      int diffMinutes = timeTo.difference(timeFrom).inMinutes;
      var duration = DateTime(now.year, now.month, now.day, (diffMinutes/60).floor(), diffMinutes % 60);
      _durationController.text = DateProvider.convertDate2Str(duration, "HH:mm");
    }
  }

  _onFilePicker() {
    showModalBottomSheet(
      context: Config.navigatorKey.currentContext!,
      builder: (BuildContext bc) {
        return PickerFile(
          filePicker: false,
          galleryPicker: false,
          preferredCameraDevice: CameraDevice.front,
        );
      },
    ).then((value) {
      if(value != null) {
        EasyLoading.show(status: "Please Wait".tr());
        Map<String, String>? property = HashMap();
        property["property"] = "{\"latitude\":\"${_currentCoordinate!.latitude}\",\"longitude\":\"${_currentCoordinate!.longitude}\",\"address\":\"$_currentLocation\"}";
        _mediaRepository.upload(value, "file", property).then((value) {
          setState(() {
            _medias.add(value.data);
          });
        }).whenComplete(() {
          EasyLoading.dismiss();
        });
      }
    });
  }

  _getCurrentLocation() {
    EasyLoading.show(status: "Please Wait".tr());
    _geolocationProvider.getCurrentLocation().then((val) {
      setState(() {
        _currentCoordinate = val;
      });
      _geolocationProvider.getAddressFromCoordinate(val.latitude, val.longitude).then((value) {
        setState(() {
          _currentLocation = "${value[0].name}, ${value[0].thoroughfare} ${value[0].subThoroughfare}, ${value[0].subLocality} ${value[0].locality} ${value[0].subAdministrativeArea} ${value[0].country}, ${value[0].postalCode}";
        });
      });
    }).catchError((e) {
      Future.delayed(const Duration(milliseconds: 500)).then((value) {
        EasyLoading.dismiss();
      });
    }).whenComplete(() {
      Future.delayed(const Duration(milliseconds: 500)).then((value) {
        EasyLoading.dismiss();
        if (_currentCoordinate!.isMocked) {
          AlertProvider.showAlertDialog(
            title: "Location not valid".tr(),
            message: "Please check the location in your Settings".tr(),
          );
        }
      });
    });
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
          "Application Form".tr(),
          style: TextStyle(
            color: Config.DEFAULT_ACCENT_COLOR,
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Form(
          key: form,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InputForm().renderDropdownField(
                  fieldName: "Whereabout Category".tr(),
                  listItem: whereaboutCategory,
                  value: _valWhereaboutCategory,
                  onChanged: (value) {
                    setState(() {
                      _valWhereaboutCategory = value as WhereaboutCategory?;
                    });
                  },
                  validator: (value) {
                    if(value == null) {
                      return "This field is required".tr();
                    }
                    return null;
                  }
                ),
                InputForm().renderDateField(
                  initialDate: _dateController.text.isNotEmpty
                  ? DateFormat("yyyy-MM-dd").parse(_dateController.text)
                  : DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2050),
                  fieldName: "Date".tr(),
                  controller: _dateController,
                  onChanged: (value) {
                    if (value == null) return;
                      
                    _dateController.text = DateFormat("yyyy-MM-dd").format(value);
                  },
                  validator: Validation.validateField
                ),
                InputForm().renderTimeField(                  
                  fieldName: "Leave Time".tr(),
                  controller: _timeFromController,
                  onChanged: (value) {
                    if (value == null) return;
                    
                    final now = DateTime.now();
                    _timeFromController.text = DateFormat("HH:mm").format(DateTime(now.year, now.month, now.day, value.hour, value.minute));
                    _calculateDuration();
                  },
                  validator: Validation.validateField
                ),
                InputForm().renderTimeField(                  
                  fieldName: "Return Time".tr(),
                  controller: _timeToController,
                  onChanged: (value) {
                    if (value == null) return;
                    
                    final now = DateTime.now();
                    _timeToController.text = DateFormat("HH:mm").format(DateTime(now.year, now.month, now.day, value.hour, value.minute));
                    _calculateDuration();
                  },
                  validator: Validation.validateField
                ),
                InputForm().renderTextField(                  
                  fieldName: "Duration".tr(),
                  controller: _durationController,
                  enabled: false,
                ),
                InputForm().renderTextField(                  
                  fieldName: "Contact Person".tr(),
                  controller: _contactPersonController,
                  validator: Validation.validateField,
                ),
                InputForm().renderTextField(
                  fieldName: "Destination".tr(),
                  controller: _destinationController,
                  maxLines: 5,
                  maxLength: 100,
                  textInputType: TextInputType.multiline,
                  validator: Validation.validateField,
                ),
                InputForm().renderTextField(
                  fieldName: "Description".tr(),
                  controller: _remarkController,
                  maxLines: 5,
                  maxLength: 100,
                  textInputType: TextInputType.multiline,
                ),
                MultipleAttachmentPage(
                  medias: _medias,
                  attachment: _alternateAttachment,
                  editable: true,
                  padding: 0.0,
                  onPickerFile: () {
                    _geolocationProvider.getPermission().then((value) {
                      if (value == LocationPermission.always || value == LocationPermission.whileInUse) {
                        _getCurrentLocation();
                        _onFilePicker();
                      } else if (value == LocationPermission.deniedForever) {
                        AlertProvider.showAlertDialog(title: "Permission Restricted".tr(), message: "Please enable location permission in setting".tr(), actions: actions);
                      } else {
                        _geolocationProvider.reqPermission().then((value) {
                          if (value == LocationPermission.always || value == LocationPermission.whileInUse) {
                            _getCurrentLocation();
                            _onFilePicker();
                          } else if (value == LocationPermission.deniedForever) {
                            AlertProvider.showAlertDialog(title: "Permission Restricted".tr(), message: "Please enable location permission in setting".tr(), actions: actions);
                          }
                        });
                      }
                    });
                  },
                ),
                CustomValuesPage(
                  customValues: customValues,
                  editMode: false,
                ),
                InputForm().renderButton(
                  text: "Submit".tr(),
                  onPressed: () {
                    _submitForm();
                  }
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
