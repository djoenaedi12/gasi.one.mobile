import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/module/attendance/model/attendance_status.dart';
import 'package:epeoplecare/module/attendance/model/attendance_transaction.dart';
import 'package:epeoplecare/provider/date_provider.dart';
import 'package:epeoplecare/provider/geolocation_provider.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:flutter/material.dart';

class AttendanceDetailPage extends StatefulWidget {
  final AttendanceTransaction? attendanceTransaction;
  const AttendanceDetailPage({Key? key, this.attendanceTransaction}) : super(key: key);
  @override
  State<StatefulWidget>  createState() => _AttendanceDetailPageState();
}

class _AttendanceDetailPageState extends State<AttendanceDetailPage> {
  String _currentLocation = "";

  @override
  void initState() {
    super.initState();
    _initData();
  }

  _initData() {
    if (widget.attendanceTransaction != null && widget.attendanceTransaction!.location != null) {
      try {
        double latitude = double.parse(widget.attendanceTransaction!.location!.split(",")[0]);
        double longitude = double.parse(widget.attendanceTransaction!.location!.split(",")[1]);
        GeolocationProvider().getAddressFromCoordinate(latitude, longitude).then((value) {
          setState(() {
            _currentLocation =
                "${value[0].name}, ${value[0].thoroughfare} ${value[0].subThoroughfare}, ${value[0].subLocality} ${value[0].locality} ${value[0].subAdministrativeArea} ${value[0].country}, ${value[0].postalCode}";
          });
        });
      } catch (e) {
        //
      }
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
          (widget.attendanceTransaction!.attendanceStatus == AttendanceStatus.CHECK_IN ? "Check In" : "Check Out").tr(),
          style: TextStyle(
            color: Config.DEFAULT_ACCENT_COLOR,
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: const ScrollPhysics(),
        child: Container(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              buildItem("Shift".tr(), widget.attendanceTransaction!.shift != null ? widget.attendanceTransaction!.shift!.name : ""),
              buildItem("Attendance Date".tr(),
                  DateProvider.convertDateStrFormat(widget.attendanceTransaction!.attendanceDate, "yyyy-MM-dd", "EEEE, dd MMMM yyyy")),
              buildItem(
                  (widget.attendanceTransaction!.attendanceStatus == AttendanceStatus.CHECK_IN ? "Check In" : "Check Out").tr(),
                  "${DateProvider.convertDateStrFormat(widget.attendanceTransaction!.attendanceRecord, "yyyy-MM-dd HH:mm:ss", "HH:mm:ss")} ${diffDays() < 0
                          ? "(${diffDays()} ${"Days".tr()})"
                          : (diffDays() > 0)
                              ? "(+${diffDays()} ${"Days".tr()})"
                              : ""}"),
              buildItem("Working Location".tr(), widget.attendanceTransaction!.workingLocation != null ? widget.attendanceTransaction!.workingLocation!.name : ""),
              buildItem("Location".tr(), _currentLocation),
              buildItem("Remark".tr(), widget.attendanceTransaction!.remark),
              buildItem("Supporting Document".tr(), widget.attendanceTransaction!.attachment, divider: false),
            ],
          ),
        ),
      ),
    );
  }

  int diffDays() {
    DateTime attendanceDate = DateProvider.convertStr2Date(widget.attendanceTransaction!.attendanceDate, "yyyy-MM-dd")!;
    DateTime attendanceRecord = DateProvider.convertStr2Date(widget.attendanceTransaction!.attendanceRecord, "yyyy-MM-dd HH:mm:ss")!;
    attendanceRecord = DateProvider.convertDateFormat(attendanceRecord, "yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd")!;

    return attendanceRecord.difference(attendanceDate).inDays;
  }

  Widget buildItem(
    String header,
    String? content, {
    bool divider = true,
  }) {
    return (header == "Supporting Document" || header == "Dokumen Pendukung"
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                header,
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(
                height: 10.0,
              ),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child:
                      content != null ? Image.network("${Repository().getBaseUrl()}/api/v1/file/download/$content", headers: Repository().generateHeader()) : Image.asset("assets/img/no-image-available.png")),
              divider ? Divider(color: Colors.grey.shade300) : Container(),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                header,
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(
                height: 5.0,
              ),
              Text(
                content ?? "",
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(
                height: 5.0,
              ),
              divider ? Divider(color: Colors.grey.shade300) : Container(),
            ],
          ));
  }
}
