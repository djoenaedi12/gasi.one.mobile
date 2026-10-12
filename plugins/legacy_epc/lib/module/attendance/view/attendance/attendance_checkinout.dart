// ignore_for_file: use_build_context_synchronously

import 'dart:collection';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:datetime_setting/datetime_setting.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/company/working_location.dart';
import 'package:epeoplecare/model/dropdown.dart';
import 'package:epeoplecare/model/verification_type.dart';
import 'package:epeoplecare/module/attendance/model/attendance_status.dart';
import 'package:epeoplecare/module/attendance/model/attendance_transaction.dart';
import 'package:epeoplecare/model/company/shift.dart';
import 'package:epeoplecare/module/attendance/model/flex_hour.dart';
import 'package:epeoplecare/module/attendance/repository/flex_hour_repository.dart';
import 'package:epeoplecare/module/attendance/repository/work_from_home_repository.dart';
import 'package:epeoplecare/module/attendance/view/attendance/mandatory_photo_consent.dart';
import 'package:epeoplecare/module/workflow/model/workflow_status.dart';
import 'package:epeoplecare/provider/alert_provider.dart';
import 'package:epeoplecare/provider/date_provider.dart';
import 'package:epeoplecare/provider/enum_provider.dart';
import 'package:epeoplecare/provider/geolocation_provider.dart';
import 'package:epeoplecare/module/attendance/repository/attendance_transaction_repository.dart';
import 'package:epeoplecare/provider/local_auth_provider.dart';
import 'package:epeoplecare/provider/preferences_provider.dart';
import 'package:epeoplecare/repository/employee/employee_working_location_repository.dart';
import 'package:epeoplecare/repository/file_repository.dart';
import 'package:epeoplecare/repository/employee/employee_schedule_repository.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/view/shared/in_app_camera.dart';
import 'package:epeoplecare/view/shared/input_form.dart';
import 'package:epeoplecare/view/shared/message.dart';
import 'package:epeoplecare/view/verification/verification_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class AttendanceCheckInOut extends StatefulWidget {
  final AttendanceTransaction? attendanceTransaction;
  final DateTime? attendanceDate;
  final bool isCurrentDate;
  const AttendanceCheckInOut({Key? key, this.attendanceTransaction, required this.attendanceDate, this.isCurrentDate = false}): super(key: key);
  @override
  State<StatefulWidget>  createState() => _AttendanceCheckInOutState();
}

class _AttendanceCheckInOutState extends State<AttendanceCheckInOut> {
  final _remarkController = TextEditingController();
  final _shiftController = TextEditingController();
  Position? _currentCoordinate;
  String _currentLocation = "";
  final GeolocationProvider _geolocationProvider = GeolocationProvider();
  final AttendanceTransactionRepository _attendanceTransactionRepository = Repository().getAttendanceTransactionRepository();
  final EmployeeScheduleRepository _employeeScheduleRepository = Repository().getEmployeeScheduleRepository();
  final FlexHourRepository _flexHourRepository = Repository().getFlexHourRepository();
  final FileRepository _fileRepository = Repository().getFileRepository();
  File? _attachmentFile;
  String? _alternateAttachment;
  bool errorAttachmentMandtory = false;
  Shift? _shift;
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
  WorkingLocation? _workingLocation;
  List<Dropdown> workingLocations = [];
  final EmployeeWorkingLocationRepository _employeeWorkingLocationRepository = Repository().getEmployeeWorkingLocationRepository();
  final WorkFromHomeRepository _workFromHomeRepository = Repository().getWorkFromHomeRepository();
  final _imagePicker = ImagePicker();
  bool _getCurrentLocationState = false;
  bool _getWorkingLocationState = false;

  @override
  void initState() {
    super.initState();

    _geolocationProvider.getPermission().then((value) {
      if (value == LocationPermission.always || value == LocationPermission.whileInUse) {
        _getCurrentLocation();
      } else if (value == LocationPermission.deniedForever) {
        AlertProvider.showAlertDialog(title: "Permission Restricted".tr(), message: "Please enable location permission in setting".tr(), actions: actions);
      } else {
        _geolocationProvider.reqPermission().then((value) {
          if (value == LocationPermission.always || value == LocationPermission.whileInUse) {
            _getCurrentLocation();
          } else if (value == LocationPermission.deniedForever) {
            AlertProvider.showAlertDialog(title: "Permission Restricted".tr(), message: "Please enable location permission in setting".tr(), actions: actions);
          }
        });
      }
    });

    _getWorkingLocation();
  }

  _getWorkingLocation() async {
    DateTime currentDate = widget.isCurrentDate || widget.attendanceDate == null ? DateProvider.getCurrentDate() : widget.attendanceDate!;
    Dropdown dropdown = Dropdown(value: null, label: "Select Working Location".tr());
    workingLocations.add(dropdown);
    Map<String, dynamic> parameters = HashMap();
    parameters["employee.id"] = Config.user!.employee!.id;
    parameters["dateFrom.lte"] = DateProvider.convertDate2Str(currentDate, "yyyy-MM-dd");
    parameters["dateTo.gte"] = DateProvider.convertDate2Str(currentDate, "yyyy-MM-dd");
    parameters["workflowStatus"] = EnumProvider.convertToString(WorkflowStatus.APPROVED)!;

    await _workFromHomeRepository.list(parameters: parameters).then((value) {
      if(value.isEmpty) return;

      setState(() {
        for (var i = 0; i < value.length; i++) {
          bool exists = false;
          for(var j = 0; j < workingLocations.length; j++) {
            if(workingLocations[j].value != null) {
              WorkingLocation workingLocation = workingLocations[j].value;
              if(value[i].workingLocation != null && workingLocation.id == value[i].workingLocation!.id) {
                exists = true;
                break;
              }
            }
          }

          if(!exists && value[i].workingLocation != null) {
            Dropdown dropdown = Dropdown(value: value[i].workingLocation, label: value[i].workingLocation!.name);
            workingLocations.add(dropdown);
          }
        }

        if(_workingLocation == null && workingLocations.length > 1) {
          _workingLocation = workingLocations[1].value;
        }
      });
    });

    await _getCurrentShift();

    if(_shift != null && _shift!.workingLocation != null) {
      bool exists = false;
      for(var j = 0; j < workingLocations.length; j++) {
        if(workingLocations[j].value != null) {
          WorkingLocation workingLocation = workingLocations[j].value;
          if(workingLocation.id == _shift!.workingLocation!.id) {
            exists = true;
            break;
          }
        }
      }

      if(!exists) {
        Dropdown dropdown = Dropdown(value: _shift!.workingLocation, label: _shift!.workingLocation!.name);
        workingLocations.add(dropdown);
      }
      
      if(_workingLocation == null && workingLocations.length > 1) {
        _workingLocation = workingLocations[1].value;
      }
    }

    await _employeeWorkingLocationRepository.listByEmployeeAndDate(Config.user!.employee!, currentDate, currentDate).then((value) async {
      if(value.isEmpty) return;

      setState(() {
        for (var i = 0; i < value.length; i++) {
          bool exists = false;
          for(var j = 0; j < workingLocations.length; j++) {
            if(workingLocations[j].value != null) {
              WorkingLocation workingLocation = workingLocations[j].value;
              if(workingLocation.id == value[i].workingLocation!.id) {
                exists = true;
                break;
              }
            }
          }

          if(!exists) {
            Dropdown dropdown = Dropdown(value: value[i].workingLocation, label: value[i].workingLocation!.name);
            workingLocations.add(dropdown);
          }
        }

        if(_workingLocation == null && workingLocations.length > 1) {
          _workingLocation = workingLocations[1].value;
        }
      });
    });
    
    // Set state true untuk flag proses selesai dilakukan
    setState(() {
      _getWorkingLocationState = true;
    });

    // working location by radius
    _getWorkingLocationByRadius();
  }

  /// get working location by radius
  /// dengan membandingkan jarak dari (currentCoordinate.latitude, longitude)
  /// dan (workingLocation.latitude, longitude) ke workingLocation.radius
  _getWorkingLocationByRadius() async {
    // Cek masing-masing state apakah sudah selesai dilakukan atau belum
    if(!_getCurrentLocationState || !_getWorkingLocationState || _currentCoordinate == null) {
      return;
    }

    for(var j = 0; j < workingLocations.length; j++) {
      if (workingLocations[j].value == null) {
        continue;
      }
      WorkingLocation workingLocation = workingLocations[j].value;
      final isInside = _getInsideRadius(workingLocation);
      if(isInside == true) {
        setState(() {
          _workingLocation = workingLocation;
        });
        break;
      }
    }
  }

  bool _getInsideRadius(WorkingLocation workingLocation) {
    final distance = Geolocator.distanceBetween(
      _currentCoordinate!.latitude, _currentCoordinate!.longitude, // koordinat 1 (user location)
      workingLocation.latitude, workingLocation.longitude // koordinat 2 (working location)
    );

    if (distance <= workingLocation.radius) {
      return true; // di dalam radius working location
    }

    return false; // di luar radius working location
  }

  _getCurrentLocation() {
    EasyLoading.show(status: "Please Wait".tr());
    _geolocationProvider.getCurrentLocation().then((val) {
      setState(() {
        _currentCoordinate = val;
        // Set state true untuk flag proses selesai dilakukan
        _getCurrentLocationState = true;
      });

      // working location by radius
      _getWorkingLocationByRadius();
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

  _getCurrentShift() async {
    if (Config.user!.employee == null) return;
    DateTime currentDate = widget.isCurrentDate || widget.attendanceDate == null ? DateProvider.getCurrentDate() : widget.attendanceDate!;
    await _employeeScheduleRepository.getShift(Config.user!.employee!, currentDate).then((value) {
      setState(() {
        _shift = value;
        _shiftController.text = value!.name;
      });
    });

    List<String> status = [
      EnumProvider.convertToString(WorkflowStatus.APPROVED)!,
    ];
    await _flexHourRepository.listByEmployeeWorkflowStatusAndDate(Config.user!.employee!, status, currentDate, currentDate).then((value) {
      setState(() {
        for (FlexHour flexHour in value) {
          _shift = flexHour.shift;
          _shiftController.text = _shift!.name;
          break;
        }
      });
    });

    if(widget.attendanceTransaction != null && widget.attendanceTransaction!.attendanceStatus == AttendanceStatus.CHECK_IN) {
      setState(() {
        _shift = widget.attendanceTransaction!.shift;
        _shiftController.text = _shift!.name;
      });
    }
  }

  _checkInOut({bool forceCheckOut= false}) async {
    if (Platform.isAndroid) {
      bool timeIsAuto = await DatetimeSetting.timeIsAuto();
      bool timeZoneIsAuto = await DatetimeSetting.timeZoneIsAuto();
      if (!timeIsAuto || !timeZoneIsAuto) {
        AlertProvider.showAlertDialog(
          title: "Enable Automatic Date & Time".tr(),
          message: "Please enable automatic date & time configuration to continue using the application".tr(),
        );
        return;
      }
    }

    if(_workingLocation != null && _workingLocation!.validateBiometric && await LocalAuthProvider().isFaceAvailable()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerificationPage(
            verificationType: VerificationType.FINGERPRINT,
            onVerified: (value) {
              Navigator.of(context).pop(value);
            },
          )
        ),
      ).then((value) {
        if(value != null && value == true) {
          _checkInOutProcess(forceCheckOut);
        }
      });
    } else {
      _checkInOutProcess(forceCheckOut);
    }
  }

  // Fungsi untuk ambil foto menggunakan camera system
  Future<File?> _tekePhotoUsingImagePicker() async {
    File? file;
    try {
      final pickedFile = await _imagePicker.pickImage(source: ImageSource.camera, imageQuality: 25, preferredCameraDevice: CameraDevice.front);
      if (pickedFile != null) {
        file = File(pickedFile.path);
      }
    // Bagian ini untuk sementara dibuat kosong terlebih dahulu, karena
    // Harapannya program tetap jalan & return null jika ada exception (tidak buble up / naik ke atas)
    // print() tidak disarankan untuk production
    // log() tidak berguna juga untuk production karena tidak bisa akses log nya
    // Harus menggunakan plugin tambahan untuk error analysis `FirebaseCrashlytics`
    } catch (_) {
    }

    return file;
  }

  // Fungsi untuk ambil foto menggunakan in app camera
  Future<File?> _tekePhotoUsingInAppCamera() async {
    File? file = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InAppCameraPage(
          preferredLensDirection: CameraLensDirection.front,
        ),
      ),
    );

    return file;
  }

  _checkInOutProcess(bool forceCheckOut) async {
    // Interceptor
    // Jika lampiran mandatory tapi belum dilampirkan
    // Buka camera untuk ambil gambar terlebih dahulu
    if(forceCheckOut == false && _workingLocation != null && _workingLocation!.requireAttachment == true && _attachmentFile == null) {
      // Ambil flag consent
      int? mandatoryPhotoConsent = await PreferencesProvider().getSharedPrefInt("mandatoryPhotoConsent");
      // Jika belum notice terkait consent ini mandatoryPhotoConsent = null atau mandatoryPhotoConsent != 1
      // Tampilkan message terlebih dahulu
      if(mandatoryPhotoConsent == null || mandatoryPhotoConsent != 1) {
        var result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MandatoryPhotoConsent(),
          ),
        );

        if(result == null) {
          return;
        }
        
        // Simpan flag notice consent
        // Agar di proses selanjutnya tidak perlu muncul lagi
        PreferencesProvider().setSharedPrefInt("mandatoryPhotoConsent", 1);
      }

      File? file =  Config.cameraPreference == "system" ? await _tekePhotoUsingImagePicker() : await _tekePhotoUsingInAppCamera();
      if(file == null) {
        return;
      }
      setState(() {
        _attachmentFile = file;
      });
    }

    EasyLoading.show(status: "Please Wait".tr());
    Map<String, dynamic> parameters = HashMap();
    if (_currentCoordinate != null) {
      parameters["location"] = "${_currentCoordinate!.latitude},${_currentCoordinate!.longitude}";
    }
    parameters["location_str"] = _currentLocation;
    parameters["employee"] = Config.user!.employee;
    parameters["remark"] = _remarkController.text;
    parameters["force_check_out"] = forceCheckOut;
    parameters["attendance_date"] = DateProvider.convertDate2Str(widget.isCurrentDate ? DateProvider.getCurrentDate() : widget.attendanceDate, "yyyy-MM-dd");
    if (_shift != null) {
      parameters["shift"] = _shift;
    }
    if (_workingLocation != null) {
      parameters["working_location"] = _workingLocation;
    }

    if (_attachmentFile != null) {
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

    parameters["attachment"] = _alternateAttachment;

    _attendanceTransactionRepository.checkInOut(parameters).then((value) {
      EasyLoading.dismiss();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MessagePage(
            icon: const Icon(Icons.check_circle, size: 100, color: Colors.green),
            title: "Success".tr(),
            subTitle: value.message,
          ),
        ),
      ).then((value) {
        Navigator.pop(context, true);
      });
    }).catchError((onError) async {
      EasyLoading.dismiss();
      if (onError.toString().contains("It is not time to check out") || onError.toString().contains("Ini bukan waktunya untuk check out")) {
        String msg = "${"It's not time to check out".tr()}\n${"Do you want to continue".tr()}?";
        bool result = await AlertProvider.showConfirmationDialog(message: msg);
        if (result) {
          _checkInOut(forceCheckOut: true);
        }
        return;
      }

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

  @override
  Widget build(BuildContext context) {
    var mediaQuery = MediaQuery.of(context);
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Wrap(
        children: [
          Container(
            padding: const EdgeInsets.all(10.0),
            color: Colors.grey[100],
            height: 45.0,
            width: mediaQuery.size.width,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  (widget.attendanceTransaction == null || widget.attendanceTransaction!.attendanceStatus == AttendanceStatus.CHECK_OUT ? "Check in" : "Check out").tr(),
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Close".tr(),
                    style: const TextStyle(
                      color: Colors.blue,
                    ),
                  ),
                )
              ],
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Visibility(
                  visible: _currentLocation.isNotEmpty,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10.0,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 30.0,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(
                          width: 10.0,
                        ),
                        Expanded(
                          child: Text(
                            _currentLocation,
                            style: const TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: InputForm().renderDropdownField(
                    fieldName: "Working Location".tr(),
                    value: _workingLocation,
                    listItem: workingLocations,
                    onChanged: (val) {
                      setState(() {
                        _workingLocation = val as WorkingLocation?;
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
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Text(
                    "Shift".tr(),
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ),
                TextFormField(
                  enabled: false,
                  controller: _shiftController,
                  decoration: const InputDecoration(
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        width: 0.5,
                        color: Colors.grey,
                      ),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        width: 0.5,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Text(
                    "${"Remark".tr()} (${"Optional".tr()})",
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ),
                TextFormField(
                  maxLength: 100,
                  controller: _remarkController,
                  decoration: InputDecoration(
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(
                        width: 0.5,
                        color: Colors.grey,
                      ),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        width: 0.5,
                        color: Config.DEFAULT_COLOR,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.zero,
                  child: InputForm().renderAttachmentField(
                    fieldName: "Supporting Document".tr(),
                    attachment: _attachmentFile,
                    alternateAttachment: _alternateAttachment != null ? "${Repository().getBaseUrl()}/api/v1/file/download/$_alternateAttachment" : null,
                    onRemoveAttachment: () {
                      setState(() {
                        _attachmentFile = null;
                        _alternateAttachment = null;
                      });
                    },
                    onChanged: (value) {
                      setState(() {
                        _attachmentFile = value as File?;
                      });
                    },
                    isError: errorAttachmentMandtory,
                    galleryPicker: false,
                    preferredCameraDevice: CameraDevice.front,
                  ),
                ),
                const SizedBox(
                  height: 10.0,
                ),
                SizedBox(
                  width: mediaQuery.size.width,
                  height: 40.0,
                  child: ElevatedButton(
                    onPressed: _currentCoordinate != null && _currentCoordinate!.isMocked ? null : _checkInOut,
                    child: Text(
                      "Save".tr(),
                      style: TextStyle(
                        color: Config.DEFAULT_ACCENT_COLOR,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
