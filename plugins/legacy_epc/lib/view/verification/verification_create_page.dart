import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/verification_type.dart';
import 'package:epeoplecare/provider/alert_provider.dart';
import 'package:epeoplecare/provider/enum_provider.dart';
import 'package:epeoplecare/provider/local_auth_provider.dart';
import 'package:epeoplecare/provider/preferences_provider.dart';
import 'package:epeoplecare/repository/auth_repository.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/validation/validation.dart';
import 'package:epeoplecare/view/home_page.dart';
import 'package:epeoplecare/view/shared/input_form.dart';
import 'package:epeoplecare/view/shared/message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class VerificationCreatePage extends StatefulWidget {
  final bool isTwoFactorAuthentication;
  final VerificationType verificationType;
  final bool isRedirect;
  const VerificationCreatePage({Key? key, this.isTwoFactorAuthentication= false, required this.verificationType, this.isRedirect= true}) : super(key: key);
  
  @override
  State<StatefulWidget> createState() => _VerificationCreatePageState();
}

class _VerificationCreatePageState extends State<VerificationCreatePage> {

  final TextEditingController _newPINController = TextEditingController();
  final TextEditingController _confirmPINController = TextEditingController();
  final formNewPIN = GlobalKey<FormState>();
  final formConfirmPIN = GlobalKey<FormState>();
  var focusNodeConfirmPIN = FocusNode();
  int _index = 0;
  bool _isObscureText = true;
  final form = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthRepository _authRepository = Repository().getAuthRepository();
  bool _isFaceAvailable = false;

  @override
  void initState() {
    super.initState();
    if(widget.verificationType == VerificationType.FINGERPRINT) {
      _index = 2;
      LocalAuthProvider().isFaceAvailable().then((value) {
        setState(() {
          _isFaceAvailable = value;
        });
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fingerVerification();
      });
    } else {
      _index = 0;
    }
  }

  void _verify() async {
    if (form.currentState!.validate()) {
      EasyLoading.show(status: "Please Wait".tr());
      _authRepository.login(Config.client!.clientId, Config.client!.clientSecret, _usernameController.text, _passwordController.text, "").then((val) {
        EasyLoading.dismiss();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessagePage(
              icon: const Icon(Icons.check_circle, size: 100, color: Colors.green),
              title: "Success".tr(),
              subTitle: (widget.verificationType == VerificationType.FINGERPRINT ? "Fingerprint has been created" : "PIN has been created").tr(),
            ),
          ),
        ).then((value) {
          PreferencesProvider().setSharedPref("pin", _confirmPINController.text);

          if(widget.isRedirect) {
            PreferencesProvider().setSharedPref("verificationType", EnumProvider.convertToString(widget.verificationType) ?? "");
            Navigator.of(context).popUntil((route) => route.isFirst);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const HomePage(),
              ),
            );
          } else {
            Navigator.pop(context, true);
          }
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
  }

  _fingerVerification() {
    LocalAuthProvider().authenticateUser(
      title: _isFaceAvailable ? "Place Your Finger or Look at the screen" : "Place Your Finger".tr(),
    ).then((value) {
      if(value == false) return;

      if(widget.isTwoFactorAuthentication) {
        setState(() {
          _index = 3;
        });
      } else {
        if(widget.isRedirect) {
          PreferencesProvider().setSharedPref("verificationType", EnumProvider.convertToString(widget.verificationType) ?? "");
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MessagePage(
                icon: const Icon(Icons.check_circle, size: 100, color: Colors.green),
                title: "Success".tr(),
                subTitle: "Fingerprint has been created".tr(),
              ),
            ),
          ).then((value) {
            Navigator.of(context).popUntil((route) => route.isFirst);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const HomePage(),
              ),
            );
          });
        } else {
          Navigator.pop(context, true);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Config.DEFAULT_COLOR,
        iconTheme: IconThemeData(
          color: Config.DEFAULT_ACCENT_COLOR,
        ),
        title: Text(
          widget.verificationType == VerificationType.FINGERPRINT
          ? _isFaceAvailable ? "Setup Fingerprint / Face ID".tr() : "Setup Fingerprint".tr()
          : "Setup PIN Code".tr(),
          style: TextStyle(
            color: Config.DEFAULT_ACCENT_COLOR,
          ),
        ),
      ),
      body: _index == 0 
            ? newPIN()
            : _index == 1
            ? confirmPIN()
            : _index == 2
            ? fingerprintConfirm()
            : twoFactor()
    );
  }

  Widget newPIN() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Create New PIN Code".tr(),
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16.0,
          ),
        ),
        const SizedBox(height: 20.0),
        Center(
          child: SizedBox(
            width: 300,
            child: PinCodeTextField(
              key: formNewPIN,
              controller: _newPINController,
              keyboardType: TextInputType.number,
              appContext: context,
              length: 6,
              obscureText: true,
              obscuringWidget: Container(
                height: 8.0,
                width: 8.0,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
              ),
              animationType: AnimationType.scale,
              animationDuration: const Duration(milliseconds: 200),
              backgroundColor: Colors.grey[100],
              autoFocus: true,
              cursorColor: Config.DEFAULT_COLOR,
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
              onCompleted: (val) {
                setState(() {
                  _newPINController.text = val;
                });
                EasyLoading.show(status: 'Please Wait'.tr());
                setState(() {
                  _index = 1;
                });
                EasyLoading.dismiss();                
              },
              onChanged: (val) {
              },
              textStyle: const TextStyle(
                fontWeight: FontWeight.normal
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget confirmPIN() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Enter Confirm PIN Code".tr(),
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16.0,
          ),
        ),
        const SizedBox(height: 5.0),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            "A PIN code you enter must be the same as the one you entered before".tr(),
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
              key: formConfirmPIN,
              controller: _confirmPINController,
              keyboardType: TextInputType.number,
              appContext: context,
              length: 6,
              obscureText: true,
              obscuringWidget: Container(
                height: 8.0,
                width: 8.0,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
              ),
              animationType: AnimationType.scale,
              animationDuration: const Duration(milliseconds: 200),
              backgroundColor: Colors.grey[100],
              autoFocus: true,
              cursorColor: Config.DEFAULT_COLOR,
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
              focusNode: focusNodeConfirmPIN,
              onCompleted: (val) {
                setState(() {
                  _confirmPINController.text = val;
                });

                if(_confirmPINController.text != _newPINController.text) {
                  AlertProvider.showAlertDialog(
                    message: "Confirm PIN code you entered does not match".tr()
                  ).then((value) {
                    focusNodeConfirmPIN.requestFocus();
                  });
                  return;
                }

                if(widget.isTwoFactorAuthentication) {
                  setState(() {
                    _index = 3;
                  });
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MessagePage(
                        icon: const Icon(Icons.check_circle, size: 100, color: Colors.green),
                        title: "Success".tr(),
                        subTitle: "PIN has been created".tr(),
                      ),
                    ),
                  ).then((value) {
                    PreferencesProvider().setSharedPref("pin", _confirmPINController.text);
                    
                    if(widget.isRedirect) {
                      PreferencesProvider().setSharedPref("verificationType", EnumProvider.convertToString(widget.verificationType) ?? "");
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomePage(),
                        ),
                      );
                    } else {
                      Navigator.pop(context, true);
                    }
                  });
                }
              },
              onChanged: (val) {
              },
              textStyle: const TextStyle(
                fontWeight: FontWeight.normal
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget fingerprintConfirm() {
    return Column(
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
    );
  }

  Widget twoFactor() {
    return Form(
      key: form,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 30.0),
            Icon(
              Icons.admin_panel_settings,
              size: 100.0,
              color: Config.DEFAULT_COLOR,
            ),
            Text(
              "Two Factor Authentication".tr(),
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16.0,
              ),
            ),
            const SizedBox(height: 5.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                "${"Please enter username and password for verify your account".tr()}. ${"Two factor authentication adds an extra layer of security".tr()}",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14.0,
                ),
              ),
            ),
            const SizedBox(height: 30.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 23.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(7.0),
                ),
                child: TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Username".tr(),
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                    ),
                  ),
                  validator: Validation.validateField,
                ),
              ),
            ),
            const SizedBox(height: 5.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 23.0),
              child: Container(
                padding: const EdgeInsets.only(
                  left: 15.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(7.0),
                ),
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: _isObscureText,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Password".tr(),
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                    ),
                    suffixIcon: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isObscureText = !_isObscureText;
                        });
                      },
                      child: Icon(
                        _isObscureText
                        ? Icons.visibility_off
                        : Icons.visibility,
                      ),
                    ),
                  ),
                  validator: Validation.validateField,
                ),
              ),
            ),
            const SizedBox(height: 15.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 23.0),
              child: InputForm().renderButton(
                text: "Verify".tr(),
                buttonColor: Config.DEFAULT_COLOR,
                textColor: Config.DEFAULT_ACCENT_COLOR,
                onPressed: () {
                  _verify();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}