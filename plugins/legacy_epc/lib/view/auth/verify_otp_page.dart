import 'dart:async';
import 'dart:collection';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/license.dart';
import 'package:epeoplecare/model/parameter.dart';
import 'package:epeoplecare/model/user.dart';
import 'package:epeoplecare/provider/client_provider.dart';
import 'package:epeoplecare/provider/firebase_messaging_provider.dart';
import 'package:epeoplecare/provider/license_provider.dart';
import 'package:epeoplecare/provider/preferences_provider.dart';
import 'package:epeoplecare/provider/session_provider.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/view/auth/login_page.dart';
import 'package:epeoplecare/view/home_page.dart';
import 'package:epeoplecare/view/shared/input_form.dart';
import 'package:epeoplecare/view/shared/message.dart';
import 'package:epeoplecare/view/verification/verification_setup_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

/// Halaman verifikasi OTP (One-Time Password) untuk proses autentikasi.
///
/// Page ini digunakan sebagai tahap lanjutan setelah login
/// ketika sistem mengharuskan verifikasi OTP (MFA).
///
/// Pengguna diminta memasukkan kode OTP yang dikirimkan
/// ke email terdaftar, dengan fitur:
/// - Countdown masa berlaku OTP
/// - Resend OTP setelah waktu tertentu
/// - Validasi OTP dan inisialisasi sesi aplikasi
///
/// Parameter:
/// - [transactionId] ID transaksi OTP yang dihasilkan saat login.
/// - [email] Email tujuan pengiriman OTP (ditampilkan ke user).
/// - [otpExpiry] Durasi OTP dalam satuan detik.
class VerifyOtpPage extends StatefulWidget {
  final String transactionId;
  final String email;
  final int otpExpiry;

  /// Membuat halaman verifikasi OTP.
  ///
  /// Default value disediakan untuk mencegah null reference,
  /// namun pada implementasi normal seluruh parameter
  /// seharusnya terisi.
  const VerifyOtpPage({Key? key, this.transactionId = "", this.email = "", this.otpExpiry = 0}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _VerifyOtpPageState();
}

/// State untuk [VerifyOtpPage].
///
/// Bertanggung jawab untuk:
/// - Mengelola input OTP
/// - Mengatur countdown OTP
/// - Menangani resend OTP
/// - Menyelesaikan proses verifikasi OTP
/// - Inisialisasi session, user, device, dan konfigurasi aplikasi
class _VerifyOtpPageState extends State<VerifyOtpPage> {
  /// Controller untuk input PIN / OTP.
  final TextEditingController _pinController = TextEditingController();

  /// Key untuk validasi form OTP.
  final formConfirmPIN = GlobalKey<FormState>();
  
  /// FocusNode untuk field PIN.
  var focusNodePIN = FocusNode();

  /// Nilai OTP yang sedang diketik pengguna.
  String otp = "";

  /// Sisa waktu OTP dalam detik.
  int seconds = 0;

  /// Timer untuk countdown OTP.
  Timer? timer;

  /// Inisialisasi state dan memulai countdown OTP.
  ///
  /// Countdown akan berjalan berdasarkan nilai [widget.otpExpiry].
  @override
  void initState() {
    super.initState();
    seconds = widget.otpExpiry;
    startCountdown();
  }

  /// Memulai atau me-reset countdown OTP.
  ///
  /// Countdown akan berjalan setiap 1 detik hingga
  /// mencapai 0, yang menandakan OTP dapat dikirim ulang.
  void startCountdown() {
    timer?.cancel();
    seconds = widget.otpExpiry;
    timer = Timer.periodic(Duration(seconds: 1), (t) {
      if (seconds == 0) {
        t.cancel();
      }
      else {
        setState(() {
          seconds--;
        });
      }
    });
  }

  /// Mengirim ulang kode OTP berdasarkan [transactionId].
  ///
  /// Proses ini akan:
  /// - Me-reset countdown OTP
  /// - Menampilkan loading indicator
  /// - Menampilkan halaman sukses atau error
  ///
  /// Jika transaksi OTP sudah tidak valid,
  /// user akan diarahkan kembali ke halaman login.
  void resend() {
    startCountdown();
      EasyLoading.show(status: 'Please Wait'.tr());
      Repository().getAuthRepository().resendOtp(widget.transactionId).then((value) {
         EasyLoading.dismiss();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessagePage(
              icon: const Icon(Icons.check_circle, size: 100, color: Colors.green),
              title: "Success".tr(),
              subTitle: "The verification code has been resent successfully".tr(),
            ),
          ),
        );
      }).catchError((onError) {
        EasyLoading.dismiss();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessagePage(
              icon: const Icon(Icons.error, size: 100, color: Colors.red),
              title: "Error".tr(),
              subTitle: "Failed to resend the code. Please try again later".tr(),
            ),
          ),
        ).then((value) {
          if(onError.toString().contains("RESEND_INVALID")) {
            Navigator.pushReplacement(
              Config.navigatorKey.currentContext!,
              MaterialPageRoute(
                builder: (context) => const LoginPage(),
              ),
            );
          }
        });
      });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  /// Melanjutkan proses verifikasi OTP dan login ke aplikasi.
  ///
  /// Flow utama:
  /// 1. Verifikasi OTP ke backend
  /// 2. Inisialisasi session & client
  /// 3. Validasi device (single device policy)
  /// 4. Set deviceId & FCM token
  /// 5. Load konfigurasi & lisensi
  /// 6. Navigasi ke Home atau Verification Setup
  ///
  /// Error handling disesuaikan dengan jenis error OTP:
  /// - OTP_INVALID
  /// - OTP_LOCKED
  /// - OTP_EXPIRED
  void _continue() async {
    EasyLoading.show(status: 'Please Wait'.tr());
    Repository().getAuthRepository().verifyOtp(widget.transactionId, _pinController.text).then((val) {
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
            SessionProvider().setSession(Config.session, "${Config.client!.code};${Config.session!.username}");

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
      EasyLoading.dismiss();
    }).catchError((onError) {
        var message = "", title = "";
        if(onError.toString().contains("OTP_INVALID")) {
            title = "Invalid OTP Code".tr();
            message = "Please check the code you entered and try again".tr();
        }
        else if(onError.toString().contains("OTP_LOCKED")) {
            title = "Too many incorrect OTP attempts".tr();
            message = "For security reason, please login again to request a new OTP code".tr();
        }
        else if(onError.toString().contains("OTP_EXPIRED")) {
            title = "The OTP Code has Expired".tr();
            message = "Please login again / resend to request a new OTP code".tr();
        }
        else {
          message = onError.toString();
          title = "Error".tr();
        }
        EasyLoading.dismiss();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessagePage(
              icon: const Icon(Icons.error, size: 100, color: Colors.red),
              title: title,
              subTitle: message.toString(),
            ),
          ),
        ).then((value) {
          if(onError.toString().contains("OTP_LOCKED")) {
            Navigator.pushReplacement(
              Config.navigatorKey.currentContext!,
              MaterialPageRoute(
                builder: (context) => const LoginPage(),
              ),
            );
          }
        });
    });
  }

  /// Membangun UI utama halaman verifikasi OTP.
  ///
  /// Tombol resend hanya aktif ketika countdown mencapai 0.
  @override
  Widget build(BuildContext context) {
    final isEnable = seconds == 0;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: verifyOTP(isEnable)
    );
  }

  /// Widget utama yang menampilkan form input OTP.
  ///
  /// Menyediakan:
  /// - Input 6 digit OTP
  /// - Countdown resend OTP
  /// - Tombol Continue
  Widget verifyOTP(bool isEnable) {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
              child: Padding(
                padding: const EdgeInsets.all(25.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text(
                        "Verify Account".tr(),
                        textAlign: TextAlign.left,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text(
                        "Enter the 6-digit verification code we sent to".tr(namedArgs: {"email": widget.email}),
                        textAlign: TextAlign.left,
                        style: const TextStyle(
                          fontSize: 14.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30.0),
                    Center(
                      child: SizedBox(
                        width: 300,
                        child: PinCodeTextField(
                          controller: _pinController,
                          keyboardType: TextInputType.number,
                          appContext: context,
                          onChanged: (val) {
                            setState(() {
                              otp = val;
                            });
                          },
                          length: 6,
                          obscureText: false,
                          animationType: AnimationType.scale,
                          animationDuration: const Duration(milliseconds: 200),
                          backgroundColor: Colors.grey[100],
                          autoFocus: true,
                          cursorColor: Config.DEFAULT_COLOR,
                          obscuringWidget: Container(
                            height: 8.0,
                            width: 8.0,
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                          ),
                          cursorHeight: 15.0,
                          enableActiveFill: true,
                          pinTheme: PinTheme(
                            shape: PinCodeFieldShape.box,
                            borderRadius: BorderRadius.circular(7),
                            fieldHeight: 50,
                            fieldWidth: 40,
                            activeColor: Colors.grey[300],
                            selectedColor: Colors.grey[300],
                            inactiveColor: Colors.grey[300],
                            selectedFillColor: Colors.white,
                            activeFillColor: Colors.white,
                            inactiveFillColor: Colors.white,
                          ),
                          focusNode: focusNodePIN,
                          onCompleted: (val) async {
                            setState(() {
                              _pinController.text = val;
                            });
                          },
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.normal
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        children: [
                          Text(
                            "Didn't recieve a code?".tr(),
                            textAlign: TextAlign.left,
                            style: const TextStyle(
                              fontSize: 14.0,
                            ),
                          ),
                          GestureDetector(
                            onTap: isEnable ? resend : null,
                            child: Text(
                              " ${"Resend".tr()} ${ isEnable ? '' : '($seconds)' }",
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14.0,
                                color: isEnable ? Colors.blue : Colors.grey
                              ),
                            ),
                          )
                        ]
                      )
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(25.0),
              child: InputForm().renderButton(
                text: "Continue".tr(),
                onPressed: otp.length >= 6 ? _continue : null,
                enabled: otp.length >= 6
              ),
            ),
          
        ],
      ),
    );
  }
}
