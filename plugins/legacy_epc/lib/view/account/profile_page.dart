import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/module/customfield/view/custom_value_page.dart';
import 'package:epeoplecare/provider/preferences_provider.dart';
import 'package:epeoplecare/provider/storage_provider.dart';
import 'package:epeoplecare/provider/string_provider.dart';
import 'package:epeoplecare/repository/employee/employee_repository.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/view/account/acting_person_page.dart';
import 'package:epeoplecare/view/account/notification_setting_page.dart';
import 'package:epeoplecare/view/account/profile_edit_page.dart';
import 'package:epeoplecare/view/shared/input_form.dart';
import 'package:epeoplecare/view/shared/picker_file.dart';
import 'package:flutter/material.dart';

import '../../provider/date_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<StatefulWidget> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Employee? _employee;
  File? _imageFile;
  bool _isRemoveable = false;
  final EmployeeRepository _employeeRepository = Repository().getEmployeeRepository();

  @override
  void initState() {
    super.initState();
    _employee = Config.user!.employee;
    _getEmployee();
  }

  _getEmployee() {
    if(Config.user!.employee == null) return;
    _employeeRepository.findById(id: Config.user!.employee!.id!).then((value) {
      setState(() {
        _employee = value;
      });
    });
  }

  void _selectImageSource(context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return PickerFile(
          isRemoveable: _isRemoveable,
        );
      },
    ).then((value) async {
      if (value == null) return;

      if(value.runtimeType == bool) {
        setState(() {
          _isRemoveable = false;
          PreferencesProvider().removeSharedPref("image");
          _imageFile = null;
        });
      } else {
        String dir = await StorageProvider().getExternalStorage();
        String fileName = "${DateTime.now().millisecondsSinceEpoch}_${Config.session!.username}.jpg";
        String newPath = "$dir/$fileName";
        value.copy(newPath);
        setState(() {
          _isRemoveable = true;
          PreferencesProvider().setSharedPref("image", fileName);
          _imageFile = value;
        });
      }
    });
  }

  Future<String?> getImageFilePath() async {
    String path = await StorageProvider().getExternalStorage();
    String fileName = await PreferencesProvider().getSharedPref("image") ?? "";
    if (await File("$path/$fileName").exists()) {
      return "$path/$fileName";
    } else {
      return null;
    }
  }

  void _onTapActingPerson() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ActingPersonPage(),
      ),
    );
  }

  void _onTapNotification() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationSettingPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Config.DEFAULT_COLOR,
        iconTheme: IconThemeData(
          color: Config.DEFAULT_ACCENT_COLOR,
        ),
        elevation: 0.0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Profile".tr(),
              style: TextStyle(
                color: Config.DEFAULT_ACCENT_COLOR,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileEditPage(
                      employee: _employee!,
                    ),
                  ),
                ).then((value) {
                  if(value == null) return;

                  setState(() {
                    _employee = value;
                  });
                });
              },
              child: Icon(
                Icons.edit, 
                size: 20.0,
                color: Config.DEFAULT_ACCENT_COLOR,
              ),
            )
          ],
        ),
      ),
      backgroundColor: Colors.white,
      body: buildAccount(),
    );
  }

  Widget buildAccount() {
    var mediaQuery = MediaQuery.of(context);
    return SingleChildScrollView(
      physics: const ScrollPhysics(),
      child: Stack(
        children: [
          Container(
            color: Config.DEFAULT_COLOR,
            width: mediaQuery.size.width,
            height: 320.0,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(
                height: 10.0,
              ),
              buildImage(),
              const SizedBox(
                height: 15.0,
              ),
              Container(
                width: mediaQuery.size.width,
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InputForm().renderDetailField(
                      title: "Employee ID".tr(),
                      content: _employee != null ? _employee!.code : ""
                    ),
                    InputForm().renderDetailField(
                      title: "Employee Name".tr(),
                      content: _employee != null ? _employee!.name : ""
                    ),
                    InputForm().renderDetailField(
                      title: "DOB".tr(),
                      content: _employee != null ? DateProvider.convertDateStrFormat(_employee!.birthDate, "yyyy-MM-dd", "dd MMM yyyy") : ""
                    ),
                    InputForm().renderDetailField(
                      title: "Email".tr(),
                      content: _employee != null ? _employee!.email : ""
                    ),
                    InputForm().renderDetailField(
                      title: "Phone Number".tr(),
                      content: _employee != null ? _employee!.phoneNumber : ""
                    ),
                    InputForm().renderDetailField(
                      title: "Gender.".tr(),
                      content: (_employee != null ? _employee!.gender.toString() : "").tr()
                    ),
                    InputForm().renderDetailField(
                      title: "Marital Status".tr(),
                      content: (_employee != null ? _employee!.marital.toString() : "").tr()
                    ),
                    CustomValuesPage(
                      customValues: _employee!.customValues,
                      viewMode: true,
                    ),
                    Visibility(
                      visible: Config.hasPermission("EmployeeActingPerson", "CREATE") || Config.hasPermission("EmployeeActingPerson", "READ") 
                      || Config.hasPermission("EmployeeActingPerson", "UPDATE") || Config.hasPermission("EmployeeActingPerson", "DELETE"),
                      child: renderFieldButton("Acting Person".tr(), _onTapActingPerson),
                    ),
                    renderFieldButton("Notification Setting".tr(), _onTapNotification),
                  ],
                ),
              )
            ],
          ),
          buildImagePicker(),
        ],
      ),
    );
  }

  Widget buildImagePicker() {
    return Positioned(
      top: 110.0,
      right: 110.0,
      child: GestureDetector(
        onTap: () {
          _selectImageSource(context);
        },
        child: Container(
          height: 50.0,
          width: 50.0,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.all(Radius.circular(50)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.5),
                spreadRadius: 2,
                blurRadius: 2,
              ),
            ],
          ),
          child: Icon(
            Icons.camera_alt,
            color: Config.DEFAULT_COLOR,
          ),
        ),
      ),
    );
  }

  Widget buildImage() {
    if (_imageFile != null) {
      return ClipRRect(
        borderRadius: const BorderRadius.all(
          Radius.circular(100.0),
        ),
        child: Image(
          height: 150.0,
          width: 150.0,
          fit: BoxFit.cover,
          image: FileImage(
            _imageFile!,
          ),
        ),
      );
    } else {
      return FutureBuilder(
        future: getImageFilePath(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            _isRemoveable = true;
            return ClipRRect(
              borderRadius: const BorderRadius.all(
                Radius.circular(100.0),
              ),
              child: Image(
                height: 150.0,
                width: 150.0,
                fit: BoxFit.cover,
                image: FileImage(
                  File("${snapshot.data}"),
                ),
              ),
            );
          } else {
            _isRemoveable = false;
            return ClipRRect(
              borderRadius: const BorderRadius.all(
                Radius.circular(100.0),
              ),
              child: Container(
                height: 150.0,
                width: 150.0,
                color: Colors.grey,
                child: Center(
                  child: Text(
                    StringProvider.getInitials(_employee != null ? _employee!.name : ""),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 40.0,
                    ),
                  ),
                ),
              ),
            );
          }
        },
      );
    }
  }

  Widget renderFieldButton(String title, onTapEvent) {
    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: onTapEvent,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16.0,
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                ),
              ],
            ),
            Divider(color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }
}
