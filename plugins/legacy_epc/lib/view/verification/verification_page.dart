// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/verification_type.dart';
import 'package:epeoplecare/provider/alert_provider.dart';
import 'package:epeoplecare/provider/local_auth_provider.dart';
import 'package:epeoplecare/provider/preferences_provider.dart';
import 'package:epeoplecare/view/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:flutter_svg/flutter_svg.dart';

class VerificationPage extends StatefulWidget {
  final VerificationType verificationType;
  final Function? onVerified;
  const VerificationPage({Key? key, required this.verificationType, this.onVerified}) : super(key: key);
  
  @override
  State<StatefulWidget> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {

  final TextEditingController _pinController = TextEditingController();
  var focusNodePIN = FocusNode();
  bool _isFaceAvailable = false;

  @override
  void initState() {
    super.initState();
    if(widget.verificationType == VerificationType.FINGERPRINT) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fingerVerification();
      });
    }
    LocalAuthProvider().isFaceAvailable().then((value) {
      setState(() {
        _isFaceAvailable = value;
      });
    });
  }

  _fingerVerification() {
    LocalAuthProvider().authenticateUser(
      title: _isFaceAvailable ? "Place Your Finger or Look at the screen" : "Place Your Finger".tr(),
    ).then((value) {
      if(value == false) return;

      if(widget.onVerified != null) {
        widget.onVerified!(value);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomePage(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: widget.verificationType == VerificationType.FINGERPRINT 
            ? fingerprintVerificationPage()
            : pinVerificationPage()
    );
  }

  Widget pinVerificationPage() {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              "Enter Your PIN Code".tr(),
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
              "A PIN code protect your data and is used to unlock application".tr(),
              textAlign: TextAlign.center,
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

                  EasyLoading.show(status: 'Please Wait'.tr());
                  String? pin = await PreferencesProvider().getSharedPref("pin");
                  EasyLoading.dismiss();
                  if(_pinController.text != pin) {
                    AlertProvider.showAlertDialog(
                      message: "PIN code you entered is wrong".tr(),
                    ).then((value) {
                      focusNodePIN.requestFocus();
                    });
                    return;
                  }

                  if(widget.onVerified != null) {
                    widget.onVerified!(true);
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomePage(),
                      ),
                    );
                  }
                },
                textStyle: const TextStyle(
                  fontWeight: FontWeight.normal
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget fingerprintVerificationPage() {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              _isFaceAvailable ? "Place Your Finger or Look at the screen" : "Place Your Finger".tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 18.0,
              ),
            ),
          ),
          const SizedBox(height: 5.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              _isFaceAvailable ? "Lift and rest the edge of your finger on the fingerprint sensor or hold your device steady and look at the screen to scan your face" : "Lift and rest the edge of your finger on the fingerprint sensor".tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14.0,
              ),
            ),
          ),
          const SizedBox(height: 30.0),
          GestureDetector(
            onTap: _fingerVerification,
            child: _isFaceAvailable 
            ? SvgPicture.asset(
                "assets/img/faceid.svg",
                height: 75,
                width: 75,
                colorFilter: ColorFilter.mode(Config.DEFAULT_COLOR, BlendMode.srcIn),
              )
            : Icon(
                Icons.fingerprint,
                size: 75.0,
                color: Config.DEFAULT_COLOR,
              ),
          )
        ],
      ),
    );
  }
}