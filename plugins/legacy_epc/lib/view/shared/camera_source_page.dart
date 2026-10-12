import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/language.dart';
import 'package:epeoplecare/provider/preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

// CameraSourcePage
// Digunakan untuk menampilkan list kamera preference
// - System Camera
// - In-App Camera
class CameraSourcePage extends StatefulWidget {
  const CameraSourcePage({super.key});

  @override
  State<StatefulWidget> createState() => _CameraSourcePageState();
}

class _CameraSourcePageState extends State<CameraSourcePage> {

  final List<Language> _cameraPreferences = [
    Language("system", "System Camera".tr()),
    Language("inapp", "In-App Camera".tr()),
  ];

  @override
  void initState() {
    super.initState();
  }

  // Set cameraPreference yang dipilih
  // Update ke konfigurasi tanpa harus restart aplikasi
  void _changeCameraSource(Language cameraPreference) {
    EasyLoading.show(status: "Please Wait".tr());
    PreferencesProvider().setSharedPref("cameraPreference", cameraPreference.code).then((value) {
      setState(() {
        Config.cameraPreference = cameraPreference.code;
      });
      EasyLoading.dismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    var mediaQuery = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Config.DEFAULT_COLOR,
        iconTheme: IconThemeData(
          color: Config.DEFAULT_ACCENT_COLOR,
        ),
        title: Text(
          "Camera Preferences".tr(),
          style: TextStyle(
            color: Config.DEFAULT_ACCENT_COLOR,
          ),
        ),
      ),
      body: SizedBox(
        height: mediaQuery.size.height,
        child: ListView.separated(
          itemCount: _cameraPreferences.length,
          separatorBuilder: (BuildContext bc, int index){
            return Divider(color: Colors.grey.shade300);
          },
          itemBuilder: (BuildContext bc, int index){
            Language cameraSource = _cameraPreferences[index];
            return ListTile(
              title: Text(cameraSource.name),
              trailing: Icon(
                Icons.check,
                color: Config.cameraPreference == cameraSource.code ? Config.DEFAULT_COLOR : Colors.white,
              ),
              onTap: () {
                _changeCameraSource(cameraSource);
              },
            );
          },
        ),
      ),
    );
  }
}