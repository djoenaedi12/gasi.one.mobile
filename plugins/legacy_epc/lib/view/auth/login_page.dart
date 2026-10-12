// ignore_for_file: use_build_context_synchronously

import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/parameter.dart';
import 'package:epeoplecare/model/system_announcement.dart';
import 'package:epeoplecare/model/user.dart';
import 'package:epeoplecare/provider/alert_provider.dart';
import 'package:epeoplecare/provider/appearance_setting_provider.dart';
import 'package:epeoplecare/provider/client_provider.dart';
import 'package:epeoplecare/provider/firebase_messaging_provider.dart';
import 'package:epeoplecare/provider/license_provider.dart';
import 'package:epeoplecare/provider/preferences_provider.dart';
import 'package:epeoplecare/provider/session_provider.dart';
import 'package:epeoplecare/provider/storage_provider.dart';
import 'package:epeoplecare/repository/auth_repository.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/repository/system_announcement_repository.dart';
import 'package:epeoplecare/view/auth/client_page.dart';
import 'package:epeoplecare/view/auth/forgot_password_page.dart';
import 'package:epeoplecare/view/auth/verify_otp_page.dart';
import 'package:epeoplecare/view/home_page.dart';
import 'package:epeoplecare/view/shared/input_form.dart';
import 'package:epeoplecare/view/shared/message.dart';
import 'package:epeoplecare/view/verification/verification_setup_page.dart';
import 'package:flutter/material.dart';
import 'package:epeoplecare/validation/validation.dart';
import 'package:epeoplecare/model/license.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<StatefulWidget> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isObscureText = true;
  final form = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  AuthRepository _authRepository = Repository().getAuthRepository();
  int lastTap = DateTime.now().millisecondsSinceEpoch;
  int consecutiveTaps = 1;
  final SystemAnnouncementRepository _systemAnnouncementRepository = Repository().getSystemAnnouncementRepository();
  SystemAnnouncement? _systemAnnouncement;
  
  @override
  void initState() {
    super.initState();
    AlertProvider.showUpdateAvailableDialog();
    AlertProvider.showUnSafeDeviceDialog();
    AlertProvider.showSignatureDialog();
    _getSystemAnnouncement();
  }

  _getSystemAnnouncement() {
    _systemAnnouncementRepository.list(headers:  _systemAnnouncementRepository.generateHeaderWithoutToken()).then((value) async {
      List<SystemAnnouncement> systemAnnouncements = value;
      if(systemAnnouncements.isNotEmpty && await PreferencesProvider().getSharedPref("sa${systemAnnouncements[0].id}${systemAnnouncements[0].version}") != "0") {
        setState(() {
          _systemAnnouncement = systemAnnouncements[0];
        });
      }
    });
  }

  void _login() async {
    if (form.currentState!.validate()) {
      EasyLoading.show(status: "Please Wait".tr());
      _authRepository = Repository().getAuthRepository();
      // get device token existing
      var deviceToken = await SessionProvider().getDeviceToken();
      _authRepository.login(Config.client!.clientId, Config.client!.clientSecret, _usernameController.text, _passwordController.text, deviceToken).then((val) {
        Config.session = val;

        SessionProvider().setSession(Config.session, "").then((value) async {
          await Repository().initData();
          Repository().getParameterRepository().getTimeZone().then((value) {
            setState(() {
              if(value != null) {
                Config.serverTimezone = value.value;
              } else {
                Config.serverTimezone = "+07:00";
              }
            });
          });

          Repository().getParameterRepository().getShowDisabledMenu().then((value) {
            setState(() {
              if(value != null && value.value == "0") {
                Config.showDisabledMenu = false;
              } else {
                Config.showDisabledMenu = true;
              }
            });
          });

          Repository().getEmployeeRepository().isManager().then((value) {
            setState(() {
              if(value != null) {
                Config.isManager = value;
              } else {
                Config.isManager = false;
              }
            });
          });

          Repository().getParameterRepository().getSwitchAccount().then((value) {
            setState(() {
                if (value != null && value.value == "1") {
                  Config.switchAccount = true;
                } else {
                  Config.switchAccount = false;
                }
            });
          });
          
          Repository().getUserRepository().findByUsername(Config.session!.username).then((value) async {
            if(value != null) {
              // validate device ID
              Parameter? parameter = await Repository().getParameterRepository().getSessionMobileDevice();
              if(Config.deviceId != "" && parameter != null && parameter.value == "SINGLE") {
                Map<String, dynamic> parameters = HashMap();
                parameters.putIfAbsent("deviceId", () => Config.deviceId);
                parameters.putIfAbsent("id.neq", () => value.id);
                List<User> users = await Repository().getUserRepository().list(parameters: parameters);
                if((value.deviceId != null && value.deviceId != Config.deviceId) || (users.isNotEmpty)) {
                  EasyLoading.dismiss();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MessagePage(
                        icon: const Icon(Icons.error, size: 100, color: Colors.red),
                        title: "Error".tr(),
                        subTitle: "deviceNotSame".tr(),
                      ),
                    ),
                  );

                  SessionProvider().destroySession("");
                  return;
                }
              }
              
              ClientProvider().setClient(Config.client, Config.client!.code);
              SessionProvider().setSession(Config.session, "${Config.client!.code};${_usernameController.text}");

              // Set Device ID
              Repository().getUserRepository().setDeviceId(deviceId: Config.deviceId).then((value) async {
                if(value != null) {
                  Config.user = value.data;
                  FirebaseMessagingProvider().getToken().then((value) {
                    setState(() {
                      Config.fcmToken = value ?? "";
                    });
                    PreferencesProvider().setSharedPref("fcmToken", value ?? "");
                    Repository().getUserRepository().setFcm(token: value ?? "");
                  });

                  License? licenseValue = await Repository().getLicenseRepository().getLicense();
                  if(licenseValue != null) {
                    LicenseProvider().setLicense(licenseValue);
                    setState(() {
                      Config.license = licenseValue;
                    });
                  }

                  EasyLoading.dismiss();
                  if(Config.verificationType != null) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomePage(),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VerificationSetupPage(
                          isTwoFactorAuthentication: false,
                        ),
                      ),
                    );
                  }
                }
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
        });
      }).catchError((onError) {
        // for otp handle
        if(onError.toString().contains("MFA_REQUIRED")) {
          EasyLoading.dismiss();
          var obj = jsonDecode(onError.toString().replaceAll("Exception: ", ""));
          var data = obj["data"];
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerifyOtpPage(
                transactionId: data["transaction_id"] as String,
                email: data["receiver"] as String,
                otpExpiry: data["otp_expiry"],
              )
            ),
          );
        }
        else {
          EasyLoading.dismiss();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MessagePage(
                icon: const Icon(Icons.error, size: 100, color: Colors.red),
                title: "Error".tr(),
                subTitle: (onError.toString().contains("Username not found") || onError.toString().contains("Bad credentials") || onError.toString().contains("Bad client credentials")) ? "Username and password combination is incorrect".tr() : onError.toString(),
              ),
            ),
          );
        }

      });
    }
  }

  void _changeCompany() {
    ClientProvider().destroyClient().then((value) {
      AppearanceSettingProvider().destroyAppearanceSetting();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const ClientPage(),
        ),
      );
    });
  }

  void _forgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ForgotPasswordPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var mediaQuery = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
          height: mediaQuery.size.height,
          padding: const EdgeInsets.all(
            10.0,
          ),
          color: Colors.white,
          child: Form(
            key: form,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: _systemAnnouncement != null ? 10.0 : 30.0, 
                      top: 5.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Config.appearanceSetting != null && Config.appearanceSetting!.appLogo != null && Config.appearanceSetting!.appLogo!.isNotEmpty
                            ? FutureBuilder(
                                future: StorageProvider().getExternalStorage(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    return Image(
                                      height: 40.0,
                                      width: 40.0,
                                      fit: BoxFit.contain,
                                      image: FileImage(
                                        File("${snapshot.data}/logo.jpg"),
                                      ),
                                      errorBuilder: (context, exception, stackTrace) {
                                        return Image.asset(
                                          "assets/img/logo.png",
                                          height: 40.0,
                                          width: 40.0,
                                          fit: BoxFit.contain,
                                        );
                                      },
                                    );
                                  } else {
                                    return Image.asset(
                                      "assets/img/logo.png",
                                      height: 40.0,
                                      width: 40.0,
                                      fit: BoxFit.contain,
                                    );
                                  }
                                },
                              )
                            : Image.asset(
                                "assets/img/logo.png",
                                width: 40.0,
                                height: 40.0,
                              ),
                            const SizedBox(width: 5.0),
                            Text(
                              Config.appearanceSetting != null && Config.appearanceSetting!.appName != null && Config.appearanceSetting!.appName!.isNotEmpty ? Config.appearanceSetting!.appName ?? "" : "e-PeopleCare",
                              style: const TextStyle(
                                color: Color(0xFF015281),
                                fontWeight: FontWeight.w500,
                                fontSize: 20.0,
                              ),
                            ),
                          ],
                        ),
                        InputForm().renderToogleField(
                          option1: "en",
                          option2: "id",
                          value: Config.language,
                          onTap: () {
                            if(Config.language == "en") {
                              Config.language = "id";
                            } else {
                              Config.language = "en";
                            }

                            EasyLoading.show(status: "Please Wait".tr());
                            PreferencesProvider().setSharedPref("language", Config.language).then((value) {
                              context.setLocale(Locale(Config.language));
                              Repository().setLanguange(Config.language);
                              EasyLoading.dismiss();
                            });
                          }
                        ),
                      ],
                    ),
                  ),
                  Visibility(
                    visible: _systemAnnouncement != null,
                    child: buildSystemAnnouncement(),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 5.0,
                      right: 5.0,
                      top: 5.0,
                      bottom: 10.0,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        int now = DateTime.now().millisecondsSinceEpoch;
                        if (now - lastTap < 1000) {
                          consecutiveTaps ++;
                          if (consecutiveTaps > 2){
                            _changeCompany();
                          }
                        } else {
                          consecutiveTaps = 1;
                        }
                        lastTap = now;
                      },
                      child: Text(
                        Config.appearanceSetting != null && Config.appearanceSetting!.welcomePageMobile != null && Config.appearanceSetting!.welcomePageMobile!.isNotEmpty 
                        ? Config.appearanceSetting!.welcomePageMobile ?? ""
                        : "Welcome to".tr(namedArgs: {"companyName": Config.client!.name}),
                        style: const TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  Card(
                    color: Colors.white,
                    elevation: 1.5,
                    child: Container(
                      padding: const EdgeInsets.all(15.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Config.appearanceSetting != null && Config.appearanceSetting!.appLogo != null && Config.appearanceSetting!.appLogo!.isNotEmpty
                                    ? buildImage()
                                    : Image.asset(
                                        "assets/img/logo.png",
                                        width: 150.0,
                                        height: 150.0,
                                      ),
                          ),
                          InputForm().renderTextField(
                            fieldName: "Username".tr(),
                            controller: _usernameController,
                            validator: Validation.validateField,
                            textInputAction: TextInputAction.next,
                          ),
                          InputForm().renderPasswordField(
                            fieldName: Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: Row(
                                children: [
                                  Text(
                                    "Password".tr(),
                                    style: const TextStyle(
                                      color: Colors.grey,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _forgotPassword,
                                    child: Text(
                                      " (${"Forgot Password".tr()} ?)",
                                      style: const TextStyle(
                                        color: Colors.blue,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            controller: _passwordController,
                            validator: Validation.validateField,
                            obscureText: _isObscureText,
                            onTap: () {
                              setState(() {
                                _isObscureText = !_isObscureText;
                              });
                            }
                          ),
                          InputForm().renderButton(
                            text: "Sign In".tr(),
                            onPressed: () {
                              _login();
                            }
                          ),
                        ],
                      ),
                    ),
                  ),                  
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildSystemAnnouncement() {
    var mediaQuery = MediaQuery.of(context);
    return Container(
      padding: const EdgeInsets.only(
        bottom: 10.0,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFfff3cd),
          border: Border.all(color: Colors.orange.shade300, width: 0.5),
          borderRadius: BorderRadius.circular(5.0)
        ),
        width: mediaQuery.size.width,
        padding: const EdgeInsets.only(left: 15, right: 15, top: 10),
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning, color: Colors.red),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _systemAnnouncement != null ? _systemAnnouncement!.subject : "",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Html(
                        data: _systemAnnouncement != null ? _systemAnnouncement!.content : "",
                        style: {
                          "body": Style(
                            fontSize: FontSize(11.0),
                            margin: Margins.zero,
                          )
                        },
                        onLinkTap: (url, attributes, element) {
                          if(url != null) {
                            launchUrl(Uri.parse(url));
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              right: 0,
              child: GestureDetector(
                child: const Icon(Icons.close, size: 12),
                onTap: () {
                  PreferencesProvider().setSharedPref("sa${_systemAnnouncement!.id}${_systemAnnouncement!.version}", "0").then((value) {
                    setState(() {
                      _systemAnnouncement = null;
                    });
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildImage() {
    return FutureBuilder(
      future: StorageProvider().getExternalStorage(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image(
            height: 150.0,
            width: 150.0,
            fit: BoxFit.contain,
            image: FileImage(
              File("${snapshot.data}/logo.jpg"),
            ),
            errorBuilder: (context, exception, stackTrace) {
              return Image.asset(
                "assets/img/logo.png",
                height: 150.0,
                width: 150.0,
                fit: BoxFit.contain,
              );
            },
          );
        } else {
          return Image.asset(
            "assets/img/logo.png",
            height: 150.0,
            width: 150.0,
            fit: BoxFit.contain,
          );
        }
      },
    );
  }
}
