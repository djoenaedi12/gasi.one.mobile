// ignore_for_file: use_build_context_synchronously

import 'dart:collection';
import 'dart:io';

import 'package:datetime_setting/datetime_setting.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/custom_value.dart';
import 'package:epeoplecare/module/customfield/view/custom_value_page.dart';
import 'package:epeoplecare/module/leave/model/whereabout_status.dart';
import 'package:epeoplecare/module/leave/model/whereabout_transaction.dart';
import 'package:epeoplecare/module/leave/view/whereabout/whereabout_reason.dart';
import 'package:epeoplecare/provider/alert_provider.dart';
import 'package:epeoplecare/provider/date_provider.dart';
import 'package:epeoplecare/provider/geolocation_provider.dart';
import 'package:epeoplecare/repository/media_repository.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/module/leave/repository/whereabout_transaction_repository.dart';
import 'package:epeoplecare/view/shared/input_form.dart';
import 'package:epeoplecare/view/shared/message.dart';
import 'package:epeoplecare/view/shared/multiple_attachment_page.dart';
import 'package:epeoplecare/view/shared/picker_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class WhereaboutDetailPage extends StatefulWidget {
  
  final WhereaboutTransaction? whereaboutTransaction;
  const WhereaboutDetailPage({Key? key, this.whereaboutTransaction}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _WhereaboutDetailPageState();
}

class _WhereaboutDetailPageState extends State<WhereaboutDetailPage> {

  final WhereaboutRepository _whereaboutRepository = Repository().getWhereaboutRepository();
  WhereaboutStatus? status;
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
  final List<PopupMenuEntry<String>> _popupMenuEntry = [
    PopupMenuItem<String> (
      value: "return",
      child: Text("Return".tr())
    )
  ];
  
  @override
  void initState() {
    super.initState();
    status = widget.whereaboutTransaction!.whereaboutStatus;
    _medias = widget.whereaboutTransaction!.medias;
    if(isOverdue()) {
      status = WhereaboutStatus.OVERDUE;
    }
    if(widget.whereaboutTransaction!.employee!.id == Config.user!.employee!.id && widget.whereaboutTransaction!.whereaboutStatus == WhereaboutStatus.OPEN && isOverdue() == false) {
      _popupMenuEntry.add(
        PopupMenuItem<String> (
          value: "cancel",
          child: Text("Cancel".tr())
        )
      );
    }
  }

  bool isOverdue() {
    DateTime dateCurr = DateProvider.convertStr2Date(DateProvider.convertDate2Str(DateProvider.getCurrentDate(), "yyyy-MM-dd HH:mm"), "yyyy-MM-dd HH:mm")!;
    DateTime date = DateProvider.convertStr2Date(widget.whereaboutTransaction!.date, "yyyy-MM-dd")!;
    DateTime timeTo = DateProvider.convertStr2Date(widget.whereaboutTransaction!.timeTo, "HH:mm:ss")!;
    DateTime returnTime = DateTime(date.year, date.month, date.day, timeTo.hour, timeTo.minute);
    
    if((widget.whereaboutTransaction!.whereaboutStatus == WhereaboutStatus.OPEN && dateCurr.compareTo(returnTime) > 0) || widget.whereaboutTransaction!.whereaboutStatus == WhereaboutStatus.OVERDUE) {
        return true;
    }
    return false;
  }

  _return() async {
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
    
    String reason = "";
    if(isOverdue()) {
      var value = await showModalBottomSheet(
                    isScrollControlled: true,
                    context: context,
                    builder: (BuildContext bc) {
                      return const WhereaboutReason();
                    }
                  );
      if(value == null) return;

      reason = value['reason'];
    }

    EasyLoading.show(status: "Please Wait".tr());
    _whereaboutRepository.whereaboutReturn(widget.whereaboutTransaction!.id!, reason).then((value) {
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

  _cancel() async {
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

    if(isOverdue()) {
      return;
    }

    EasyLoading.show(status: "Please Wait".tr());
    _whereaboutRepository.whereaboutCancel(widget.whereaboutTransaction!.id!).then((value) {
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

  _update() async {
    EasyLoading.show(status: "Please Wait".tr());
    widget.whereaboutTransaction!.medias = _medias;
    _whereaboutRepository.update(
      id: widget.whereaboutTransaction!.id!, 
      entity: widget.whereaboutTransaction!).then((value) {
      EasyLoading.dismiss();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MessagePage(
            icon: const Icon(Icons.check_circle, size: 100, color: Colors.green),
            title: "Success".tr(),
            subTitle: "Data has been updated".tr(),
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
        child: Column(
          children: [
            InputForm().renderDetailField(
              title: "Status".tr(),
              content: status.toString().tr(),
            ),
            InputForm().renderDetailField(
              title: "Whereabout Category".tr(),
              content: widget.whereaboutTransaction!.whereaboutCategory.toString().tr(),
            ),
            InputForm().renderDetailField(
              title: "Date".tr(),
              content: DateProvider.convertDateStrFormat(widget.whereaboutTransaction!.date, "yyyy-MM-dd", "EEEE, dd MMMM yyyy"),
            ),
            InputForm().renderDetailField(
              title: "Time".tr(),
              content: "${DateProvider.convertDateStrFormat(widget.whereaboutTransaction!.timeFrom, "HH:mm:ss", "HH:mm")} - ${DateProvider.convertDateStrFormat(widget.whereaboutTransaction!.timeTo, "HH:mm:ss", "HH:mm")}",
            ),
            InputForm().renderDetailField(
              title: "Duration".tr(),
              content: DateProvider.convertDateStrFormat(widget.whereaboutTransaction!.duration, "HH:mm:ss", "HH:mm"),
            ),
            InputForm().renderDetailField(
              title: "Contact Person".tr(),
              content: widget.whereaboutTransaction!.contactPerson,
            ),
            InputForm().renderDetailField(
              title: "Destination".tr(),
              content: widget.whereaboutTransaction!.destination,
            ),
            InputForm().renderDetailField(
              title: "Description".tr(),
              content: widget.whereaboutTransaction!.description,
            ),
            InputForm().renderDetailField(
              title: "Actual Return".tr(),
              content: "${widget.whereaboutTransaction!.actualDate != null ? DateProvider.convertDateStrFormat(widget.whereaboutTransaction!.actualDate, "yyyy-MM-dd", "EEEE, dd MMMM yyyy") : ""} ${widget.whereaboutTransaction!.actualTime ?? ""}",
            ),
            InputForm().renderDetailField(
              title: "Reason".tr(),
              content: widget.whereaboutTransaction!.reason ?? "",
            ),
            MultipleAttachmentPage(
              medias: _medias,
              attachment: widget.whereaboutTransaction!.attachment,
              editable: widget.whereaboutTransaction!.employee!.id == Config.user!.employee!.id && (widget.whereaboutTransaction!.whereaboutStatus == WhereaboutStatus.OPEN || widget.whereaboutTransaction!.whereaboutStatus == WhereaboutStatus.OVERDUE),
              padding: 10.0,
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
              customValues: widget.whereaboutTransaction!.customValues,
              viewMode: true,
            ),
            Visibility(
              visible: widget.whereaboutTransaction!.employee!.id == Config.user!.employee!.id && (widget.whereaboutTransaction!.whereaboutStatus == WhereaboutStatus.OPEN || widget.whereaboutTransaction!.whereaboutStatus == WhereaboutStatus.OVERDUE),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Row(
                  children: [
                    InputForm().renderButton(
                      width: MediaQuery.of(context).size.width - 70,
                      text: "Update".tr(),
                      onPressed: () {
                        _update();
                      }
                    ),
                    PopupMenuButton<String>(
                      itemBuilder: (context) => _popupMenuEntry,
                      onSelected: (value) {
                        if(value == "return") {
                          _return();
                        } else {
                          _cancel();
                        }
                      },
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10.0),
          ],
        ),
      ),
    );
  }
}
