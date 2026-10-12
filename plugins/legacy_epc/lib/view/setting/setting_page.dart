import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/verification_type.dart';
import 'package:epeoplecare/provider/alert_provider.dart';
import 'package:epeoplecare/provider/enum_provider.dart';
import 'package:epeoplecare/provider/preferences_provider.dart';
import 'package:epeoplecare/provider/session_provider.dart';
import 'package:epeoplecare/provider/storage_provider.dart';
import 'package:epeoplecare/provider/string_provider.dart';
import 'package:epeoplecare/repository/auth_repository.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/view/account/profile_page.dart';
import 'package:epeoplecare/view/setting/about_page.dart';
import 'package:epeoplecare/view/auth/login_page.dart';
import 'package:epeoplecare/view/setting/change_password_page.dart';
import 'package:epeoplecare/view/setting/change_pin_page.dart';
import 'package:epeoplecare/view/setting/switch_account_page.dart';
import 'package:epeoplecare/view/setting/verification_type_page.dart';
import 'package:epeoplecare/view/shared/camera_source_page.dart';
import 'package:epeoplecare/view/shared/language_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<StatefulWidget> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  Future<String?>? imageName;
  final AuthRepository _authRepository = Repository().getAuthRepository();

  @override
  void initState() {
    super.initState();

    _setImage();
  }

  _setImage() {
    imageName = getImageFilePath();
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

  _logout() {
    AlertProvider.showConfirmationDialog(
      message: "${"Are you sure want to logout".tr()}?",
    ).then((value) {
      if(value == true) {
        EasyLoading.show(status: "Please Wait".tr());
        _authRepository.logout().then((value) {
          SessionProvider().destroySession("").then((value) {
            SessionProvider().destroySession("${Config.client!.code};${Config.session!.username}");
            setState(() {
              Config.session = null;
            });
            EasyLoading.dismiss();
            Navigator.of(context).popUntil((route) => route.isFirst);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const LoginPage(),
              ),
            );
          });
        });
      }
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
          "Setting".tr(),
          style: TextStyle(
            color: Config.DEFAULT_ACCENT_COLOR,
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildProfile(),
              const SizedBox(height: 30.0,),
              Text(
                "Setting".tr(),
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 15.0,),
              InkWell(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LanguagePage(),
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.language, 
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 20.0,),
                        Text("Language".tr()),
                      ],
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
              Divider(height: 30, color: Colors.grey.shade300),

              // Menambahkan menu untuk mengakses halaman ubah kamera prefereence
              InkWell(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CameraSourcePage(),
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.camera_alt, 
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 20.0,),
                        Text("Camera Preferences".tr()),
                      ],
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
              Divider(height: 30, color: Colors.grey.shade300),
              
              InkWell(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChangePasswordPage(),
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.lock, 
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 20.0,),
                        Text("Change Password".tr()),
                      ],
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
              Divider(height: 30, color: Colors.grey.shade300),
              InkWell(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) => VerificationTypePage(
                      verificationType: Config.verificationType ?? VerificationType.PIN,
                    )).then((value) {
                      if(value == null) return;

                      PreferencesProvider().setSharedPref("verificationType", EnumProvider.convertToString(value) ?? "").then((val) {
                        if(val == true) {
                          setState(() {
                            Config.verificationType = value;
                          });
                        }
                      });
                    });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.phonelink_lock, 
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 20.0,),
                        Text("Verification Type".tr()),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          Config.verificationType != null ? (EnumProvider.convertToString(Config.verificationType, capitalEachWord: Config.verificationType == VerificationType.FINGERPRINT ? true : false) ?? "").tr() : "",
                          style: const TextStyle(
                            fontSize: 12.0,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 5.0),
                        const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                        ),  
                      ],
                    ),
                  ],
                ),
              ),
              Visibility(
                visible: VerificationType.PIN == Config.verificationType,
                child: Column(
                  children: [
                    Divider(height: 30, color: Colors.grey.shade300),
                    InkWell(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChangePINPage(),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.keyboard, 
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 20.0,),
                              Text("Change PIN".tr()),
                            ],
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              ),
              Visibility(
                visible: Config.switchAccount,
                child: Column(
                  children: [
                    Divider(height: 30, color: Colors.grey.shade300),
                    InkWell(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () {
                        showModalBottomSheet(
                          isScrollControlled: true,
                          context: context,
                          builder: (BuildContext bc) {
                            return SwitchAccountPage();
                          },
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.switch_account, 
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 20.0,),
                              Text("Switch Account".tr()),
                            ],
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              ),
              Divider(height: 30, color: Colors.grey.shade300),
              InkWell(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: _logout,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.exit_to_app, 
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 20.0,),
                        Text("Sign Out".tr()),
                      ],
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30.0,),
              Text(
                "About Application".tr(),
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 15.0,),
              InkWell(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AboutPage(),
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline, 
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 20.0,),
                        Text("About".tr()),
                      ],
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Row buildProfile() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            children: [
              FutureBuilder(
                future: imageName,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return ClipRRect(
                      borderRadius: const BorderRadius.all(
                        Radius.circular(100.0),
                      ),
                      child: Image(
                        height: 75.0,
                        width: 75.0,
                        fit: BoxFit.cover,
                        image: FileImage(File("${snapshot.data}")),
                      ),
                    );
                  } else {
                    return ClipRRect(
                      borderRadius: const BorderRadius.all(
                        Radius.circular(100.0),
                      ),
                      child: Container(
                        height: 75.0,
                        width: 75.0,
                        color: Colors.grey,
                        child: Center(
                          child: Text(
                            StringProvider.getInitials(Config.user!.employee != null ? Config.user!.employee!.name : ""),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 28.0,
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(width: 20.0,),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Config.user!.employee != null ? Config.user!.employee!.name : "",
                      style: const TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5.0,),
                    Text(
                      Config.user!.employee != null ? Config.user!.employee!.code : "",
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfilePage(),
              ),
            ).then((value) {
              setState(() {
                _setImage();
              });
            });
          },
          child: Text(
            "View Profile".tr(),
            style: const TextStyle(
              color: Colors.blue,
            ),
          ),
        ),
      ],
    );
  }
}