// ignore_for_file: must_be_immutable

// import 'dart:io';

// import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/client.dart';
import 'package:epeoplecare/model/license.dart';
import 'package:epeoplecare/model/screen_argument.dart';
import 'package:epeoplecare/model/session.dart';
import 'package:epeoplecare/model/verification_type.dart';
import 'package:epeoplecare/module/attendance/view/attendance/attendance_page.dart';
import 'package:epeoplecare/module/attendance/view/correction/attendance_correction_page.dart';
import 'package:epeoplecare/module/attendance/view/flex_hour/flex_hour_page.dart';
import 'package:epeoplecare/module/attendance/view/wfh/work_from_home_page.dart';
import 'package:epeoplecare/module/benefit/view/benefit_page.dart';
import 'package:epeoplecare/module/businesstrip/view/business_trip_page.dart';
import 'package:epeoplecare/module/cashadvance/view/ca_page.dart';
import 'package:epeoplecare/module/cashadvance/view/settlement/ca_settlement_page.dart';
import 'package:epeoplecare/module/leave/view/calendar/calendar_page.dart';
import 'package:epeoplecare/module/leave/view/leave/leave_page.dart';
import 'package:epeoplecare/module/leave/view/whereabout/whereabout_page.dart';
import 'package:epeoplecare/module/letter/view/letter_page.dart';
import 'package:epeoplecare/module/loan/view/change/loan_change_page.dart';
import 'package:epeoplecare/module/loan/view/loan_page.dart';
import 'package:epeoplecare/module/overtime/view/overtime/overtime_page.dart';
import 'package:epeoplecare/module/payroll/view/payroll/payroll_page.dart';
import 'package:epeoplecare/module/task/view/task_page.dart';
import 'package:epeoplecare/provider/appearance_setting_provider.dart';
import 'package:epeoplecare/provider/client_provider.dart';
import 'package:epeoplecare/provider/encoder_provider.dart';
import 'package:epeoplecare/provider/enum_provider.dart';
import 'package:epeoplecare/provider/firebase_messaging_provider.dart';
import 'package:epeoplecare/provider/license_provider.dart';
import 'package:epeoplecare/provider/preferences_provider.dart';
import 'package:epeoplecare/provider/session_provider.dart';
import 'package:epeoplecare/provider/string_provider.dart';
import 'package:epeoplecare/repository/auth_repository.dart';
import 'package:epeoplecare/repository/client_repository.dart';
import 'package:epeoplecare/repository/parameter_repository.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/view/splash_screen_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:safe_device/safe_device.dart';
import 'package:uuid/uuid.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseMessaging.instance.setAutoInitEnabled(true);
  await EasyLocalization.ensureInitialized();
  final savedThemeMode = await AdaptiveTheme.getThemeMode();

  // Set default certificate untuk verifikasi SSL
  // Android 7 tidak selalu memiliki root CA terbaru, misalnya ISRG Root X1 untuk Let's Encrypt certificate dan certificate itu yang kita gunakan saat ini
  // Sehingga sertifikat yang bagi device modern valid dianngap tidak trusted di android 7
  final context = SecurityContext.defaultContext;
  ByteData data = await rootBundle.load("assets/ca/isrgrootx1.pem");
  context.setTrustedCertificatesBytes(data.buffer.asUint8List());

  runApp(Phoenix(child: EasyLocalization(supportedLocales: const [Locale('en'), Locale('id')], path: 'assets/i18n', child: EWorkflowApp(savedThemeMode: savedThemeMode))));
}

class EWorkflowApp extends StatefulWidget {
  AdaptiveThemeMode? savedThemeMode;

  EWorkflowApp({Key? key, AdaptiveThemeMode? savedThemeMode}) : super(key: key);

  @override
  State<EWorkflowApp> createState() => _EWorkflowAppState();
}

class _EWorkflowAppState extends State<EWorkflowApp> {
  @override
  void initState() {
    super.initState();
    configLoading();
    initData();
    initPackageInfo();
    initDeviceInfo();
    initUnsafeDevice();
    initSignature();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FirebaseMessagingProvider().init();
    });
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  void configLoading() {
    EasyLoading.instance
      ..indicatorType = EasyLoadingIndicatorType.fadingCircle
      ..loadingStyle = EasyLoadingStyle.light
      ..maskType = EasyLoadingMaskType.black
      ..userInteractions = false
      ..dismissOnTap = false;
  }

  initData() {
    PreferencesProvider().getSharedPref("verificationType").then((value) {
      if (value == null || value == "") return;

      setState(() {
        Config.verificationType = EnumProvider.fromString(VerificationType.values, value);
      });
    });

    PreferencesProvider().getSharedPref("language").then((value) {
      if (value == null || value == "") return;

      setState(() {
        Config.language = value;
      });
    });

    // Blok ini dijalankan ketika aplikasi pertama kali dijalankan
    // Ambil infromasi cameraPreference setting yang tersimpan di shared preferrence
    PreferencesProvider().getSharedPref("cameraPreference").then((value) {
      // Jika value nulll / blank / belum setting sama sekali
      // Dan device adalah iOS maka by default cameraPreference = inapp
      // Karena hampir semua iOS terjadi masalah ketika membuka system kamera
      if (value == null || value == "")  {
        if(Platform.isIOS) {
          Config.cameraPreference = "inapp";
        }
        return;
      }

      // Set konfigurasi cameraPreference dengan setting yang sudah disimpan sebelumnya 
      setState(() {
        Config.cameraPreference = value;
      });
    });

    ClientProvider().isClient().then((value) {
      if (value != true) return;

      AppearanceSettingProvider().getAppearanceSetting().then((value) {
        if (value != null) {
          setState(() {
            Config.appearanceSetting = value;

            if (Config.appearanceSetting != null && Config.appearanceSetting!.colorMobile != null && Config.appearanceSetting!.colorMobile != "") {
              Config.DEFAULT_COLOR = StringProvider.hexToColor(Config.appearanceSetting!.colorMobile ?? "") ?? Config.DEFAULT_COLOR;
            }
            if (Config.appearanceSetting != null && Config.appearanceSetting!.accentColorMobile != null && Config.appearanceSetting!.accentColorMobile != "") {
              Config.DEFAULT_ACCENT_COLOR = StringProvider.hexToColor(Config.appearanceSetting!.accentColorMobile ?? "") ?? Config.DEFAULT_COLOR;
            }
          });
        }
      });

      ClientProvider().getClient("").then((value) async {
        if (value != null) {

          // Intercept untuk ambil ulang informasi client (terutama url)
          // Ambil ulang jika client.url masih mengandung `ewf-client`
          // Kemudian simpan ke SharedPreferences
          _reFetchClientInfo(value).then((client) {
            // Cek apakah nilai sebelumnya client.url mengandung `ewf-client` dan nilai yang baru `client` tidak null
            // Kemudian override nilai sebelumnya dengan nilai baru dan simpan ke SharedPreferences
            if(value.url.contains("ewf-client") && client != null) {
              ClientProvider().setClient(client, "");
            }
          });

          Repository().initData();
          setState(() {
            Config.client = value;
          });

          SessionProvider().isLogin().then((value) {
            if (value != true) return;

            SessionProvider().getSession("").then((value) async {
              if (value != null) {
                await Repository().initData();
                Repository().getUserRepository().findByUsername(value.username).then((val) async {
                  if (val != null) {
                    setState(() {
                      Config.user = val;
                      Config.session = value;
                    });

                    if (Config.deviceId.isNotEmpty) {
                      await Repository().getUserRepository().setDeviceId(deviceId: Config.deviceId);
                    }

                    PreferencesProvider().getSharedPref("fcmToken").then((value) {
                      setState(() {
                        Config.fcmToken = value ?? "";
                      });
                    });

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      FirebaseMessagingProvider().getToken().then((value) {
                        Repository().getUserRepository().setFcm(token: value ?? "");
                        PreferencesProvider().setSharedPref("fcmToken", value ?? "");

                        setState(() {
                          Config.fcmToken = value ?? "";
                        });
                      });
                    });
                  }
                });

                LicenseProvider().getLicenseModel().then((licenseValue) async {
                  if (licenseValue == null) {
                    License? licenseLocal = await Repository().getLicenseRepository().getLicense();
                    if (licenseLocal != null) {
                      setState(() {
                        licenseValue = licenseLocal;
                      });
                    }
                  }

                  setState(() {
                    Config.license = licenseValue;
                  });
                });

                Repository().getParameterRepository().getTimeZone().then((value) {
                  if (value == null) return;

                  setState(() {
                    Config.serverTimezone = value.value;
                  });
                });

                Repository().getParameterRepository().getShowDisabledMenu().then((value) {
                  if (value == null) return;

                  setState(() {
                    if (value.value == "0") {
                      Config.showDisabledMenu = false;
                    }
                  });
                });

                Repository().getParameterRepository().getSwitchAccount().then((value) {
                  if (value == null) return;

                  setState(() {
                      if (value.value == "1") {
                        Config.switchAccount = true;
                      }
                  });
                });

                Repository().getEmployeeRepository().isManager().then((value) {
                  if (value == null) return;

                  setState(() {
                    Config.isManager = value;
                  });
                });
              }
            });
          });
        }
      });
    });
  }

  // Fungsi untuk ambil ulang informasi client based on code dari client saat ini
  // Fungsi ini digunakan ketika user sudah melewati step input company code, ketika proses dari step awal (input company code) menggunakan flow normal
  // Fungsi ini digunakan hanya untuk proses migrasi atas perubahan url 
  // dari https://client-api.peoplecare.id/ewf-client menjadi https://client-api.peoplecare.id/{UNIQUE_ID}
  Future<Client?> _reFetchClientInfo(Client client) async {
    Client? newClient;
    // Cek apakah nilai client.url masih mengandung `ewf-client` atau tidak
    // Jika tidak ada, langsung return null
    // Jika masih mengandung maka coba ambil ulang informasi client
    if(!client.url.contains("ewf-client")) {
      return newClient;
    }

    ClientRepository clientRepository = Repository().getClientRepository();
    AuthRepository authRepository = Repository().getAuthRepository();
    authRepository.setBaseUrl("https://${EncoderProvider().decode(Config.baseUrl.replaceAll("https://", ""))}");
    clientRepository.setBaseUrl("https://${EncoderProvider().decode(Config.baseUrl.replaceAll("https://", ""))}");
    try {
      // Proses login terlebih dahulu
      Session? val = await authRepository.login(EncoderProvider().decode(Config.baseClientId), EncoderProvider().decode(Config.baseClientSecret), EncoderProvider().decode(Config.baseUsername), EncoderProvider().decode(Config.basePassword), "");
      if(val != null) {
        // Jika proses login berhasil
        // Lanjut ambil ulang informasi client menggunakan client code yang sekarang
        newClient = await clientRepository.getClient(client.code, val.accessToken);
        if(newClient != null) {
          newClient.url = ClientProvider().safeBase64Decode(newClient.url);
          newClient.clientId = ClientProvider().safeBase64Decode(newClient.clientId);
          newClient.clientSecret = ClientProvider().safeBase64Decode(newClient.clientSecret);
          return newClient;
        }
      }
    // Bagian ini untuk sementara dibuat kosong terlebih dahulu, karena
    // Harapannya program tetap jalan & return null jika ada exception (tidak buble up / naik ke atas)
    // print() tidak disarankan untuk production
    // log() tidak berguna juga untuk production karena tidak bisa akses log nya
    // Harus menggunakan plugin tambahan untuk error analysis `FirebaseCrashlytics`
    } catch (_) {
    }

    return newClient;
  }

  initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      Config.packageInfo = info;
    });

    ParameterRepository parameterRepository = Repository().getParameterRepository();
    AuthRepository authRepository = Repository().getAuthRepository();
    parameterRepository.setBaseUrl("https://${EncoderProvider().decode(Config.baseUrl.replaceAll("https://", ""))}");
    authRepository.setBaseUrl("https://${EncoderProvider().decode(Config.baseUrl.replaceAll("https://", ""))}");
    authRepository
        .login(
          EncoderProvider().decode(Config.baseClientId),
          EncoderProvider().decode(Config.baseClientSecret),
          EncoderProvider().decode(Config.baseUsername),
          EncoderProvider().decode(Config.basePassword),""
        )
        .then((val) {
          if (val == null) return;

          parameterRepository.getMobileAppVersion(val.accessToken).then((value) {
            if (value == null || value == "") return;

            Config.version = value.toString();
            List<String> versionArr = Config.version.split(".");
            List<String> currentVersionArr = Config.packageInfo.version.split(".");

            if (int.parse(versionArr[0]) > int.parse(currentVersionArr[0]) ||
                (int.parse(versionArr[0]) == int.parse(currentVersionArr[0]) && int.parse(versionArr[1]) > int.parse(currentVersionArr[1])) ||
                (int.parse(versionArr[0]) == int.parse(currentVersionArr[0]) &&
                    int.parse(versionArr[1]) == int.parse(currentVersionArr[1]) &&
                    int.parse(versionArr[2]) > int.parse(currentVersionArr[2]))) {
              Config.updateAvailable = true;
            } else {
              Config.updateAvailable = false;
            }
          }).catchError((e) {
            // Catch erorr
            // Jika mengandung 429: kemudian set showRateLimitPopup = true
            // Sebagai trigger untuk keluarkan popup message
            // Dan ketika tekan try again aplikasi restart
            if(e != null && e.toString().contains("429: ")) {
              Config.showRateLimitPopup = true;
            }
          });
        }).catchError((e) {
          // Catch erorr
          // Jika mengandung 429: kemudian set showRateLimitPopup = true
          // Sebagai trigger untuk keluarkan popup message
          // Dan ketika tekan try again aplikasi restart
          if(e != null && e.toString().contains("429: ")) {
            Config.showRateLimitPopup = true;
          }
        });
  }

  initDeviceInfo() async {
    PreferencesProvider().getSharedPref("deviceId").then((value) {
      String deviceId = "";
      if (value != null) {
        deviceId = value;
        setState(() {
          Config.deviceId = deviceId;
        });
      } else {
        deviceId = const Uuid().v1();
        PreferencesProvider().setSharedPref("deviceId", deviceId).then((value) {
          setState(() {
            Config.deviceId = deviceId;
          });
        });
      }
    });
    // if(Platform.isAndroid) {
    //   AndroidDeviceInfo deviceInfo = await DeviceInfoPlugin().androidInfo;
    //   setState(() {
    //     Config.deviceId = deviceInfo.id;
    //   });
    // } else if(Platform.isIOS) {
    //   IosDeviceInfo deviceInfo = await DeviceInfoPlugin().iosInfo;
    //   setState(() {
    //     Config.deviceId = deviceInfo.identifierForVendor ?? "";
    //   });
    // }
  }

  initUnsafeDevice() async {
    bool isJailBroken = await SafeDevice.isJailBroken;
    bool isMockLocation = await SafeDevice.isMockLocation;
    bool isRealDevice = await SafeDevice.isRealDevice;
    bool isSafeDevice = await SafeDevice.isSafeDevice;
    bool isDevelopmentModeEnable = await SafeDevice.isDevelopmentModeEnable;
    bool isOnExternalStorage = await SafeDevice.isOnExternalStorage;
    if(isJailBroken || !isRealDevice || isDevelopmentModeEnable || isOnExternalStorage) {
      setState(() {
        Config.unsafeDevice = true;
      });
    }
  }

  initSignature() async {
    if(Platform.isAndroid) {
      const channel = MethodChannel("app_integrity");
      final isValid = await channel.invokeMethod<bool>("verifySignature") ?? false;
      setState(() {
        Config.isSignatureValid = isValid;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    return AdaptiveTheme(
      light: ThemeData(
        brightness: Brightness.light,
        primaryColor: Config.DEFAULT_COLOR,
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(backgroundColor: Config.DEFAULT_COLOR, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0))),
        ),
        buttonTheme: ButtonThemeData(buttonColor: Config.DEFAULT_COLOR),
        appBarTheme: AppBarTheme(backgroundColor: Config.DEFAULT_COLOR),
        textSelectionTheme: TextSelectionThemeData(cursorColor: Config.DEFAULT_COLOR),
        datePickerTheme: DatePickerThemeData(
          headerBackgroundColor: Config.DEFAULT_COLOR,
          headerForegroundColor: Config.DEFAULT_ACCENT_COLOR,
          dividerColor: Colors.grey.shade300,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
        ),
        timePickerTheme: TimePickerThemeData(
          backgroundColor: Colors.white,
          dialHandColor: Config.DEFAULT_COLOR,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
        ),
        colorScheme: ColorScheme.fromSeed(seedColor: Config.DEFAULT_COLOR),
        cardTheme: CardThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0))),
        drawerTheme: DrawerThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0))),
        dialogTheme: DialogThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0))),
        textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)))),
      ),
      initial: AdaptiveThemeMode.light,
      builder: (theme, darkTheme) => MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: Config.navigatorKey,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        theme: theme,
        darkTheme: darkTheme,
        home: const SplashScreenPage(),
        builder: (context, child) {
          Widget easyLoading = EasyLoading.init() (context, child);
          return SafeArea(bottom: true, top: false, child: easyLoading);
        },
        onGenerateRoute: (settings) {
          var screenArg = ScreenArgument("", null, null);
          if (settings.arguments != null) {
            screenArg = settings.arguments as ScreenArgument;
          }
          switch (settings.name) {
            case "/module/attendance":
              return MaterialPageRoute(
                builder: (context) => AttendancePage(title: screenArg.title, icon: screenArg.icon, attendanceTransaction: screenArg.attendanceTransaction),
              );
            case "/module/attendance/correction":
              return MaterialPageRoute(builder: (context) => AttendanceCorrectionPage(title: screenArg.title, icon: screenArg.icon));
            case "/module/attendance/flex-hour":
              return MaterialPageRoute(builder: (context) => FlexHourPage(title: screenArg.title, icon: screenArg.icon));
            case "/module/attendance/wfh":
              return MaterialPageRoute(builder: (context) => WorkFromHomePage(title: screenArg.title, icon: screenArg.icon));
            case "/module/leave":
              return MaterialPageRoute(builder: (context) => LeavePage(title: screenArg.title, icon: screenArg.icon));
            case "/module/leave/whereabout":
              return MaterialPageRoute(builder: (context) => WhereaboutPage(title: screenArg.title, icon: screenArg.icon));
            case "/module/leave/calendar":
              return MaterialPageRoute(builder: (context) => CalendarPage(title: screenArg.title, icon: screenArg.icon));
            case "/module/overtime":
              return MaterialPageRoute(builder: (context) => OvertimePage(title: screenArg.title, icon: screenArg.icon));
            case "/module/payroll":
              return MaterialPageRoute(builder: (context) => PayrollPage(title: screenArg.title, icon: screenArg.icon));
            case "/module/businesstrip":
              return MaterialPageRoute(builder: (context) => BusinessTripPage(title: screenArg.title, icon: screenArg.icon));
            case "/module/loan":
              return MaterialPageRoute(builder: (context) => LoanPage(title: screenArg.title, icon: screenArg.icon));
            case "/module/loan/change":
              return MaterialPageRoute(builder: (context) => LoanChangePage(title: screenArg.title, icon: screenArg.icon));
            case "/module/letter":
              return MaterialPageRoute(builder: (context) => LetterPage(title: screenArg.title, icon: screenArg.icon));
            case "/module/benefit":
              return MaterialPageRoute(builder: (context) => BenefitPage(title: screenArg.title, icon: screenArg.icon));
            case "/module/cashadvance":
              return MaterialPageRoute(builder: (context) => CAPage(title: screenArg.title, icon: screenArg.icon));
            case "/module/cashadvance/settlement":
              return MaterialPageRoute(builder: (context) => CASettlementPage(title: screenArg.title, icon: screenArg.icon));
            case "/module/task":
              return MaterialPageRoute(builder: (context) => TaskPage(title: screenArg.title, icon: screenArg.icon));
            default:
              return null;
          }
        },
      ),
    );
  }
}
