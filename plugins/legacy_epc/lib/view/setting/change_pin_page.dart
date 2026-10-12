import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/provider/alert_provider.dart';
import 'package:epeoplecare/provider/preferences_provider.dart';
import 'package:epeoplecare/view/shared/message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class ChangePINPage extends StatefulWidget {
  const ChangePINPage({super.key});

  @override
  State<StatefulWidget> createState() => _ChangePINPageState();
}

class _ChangePINPageState extends State<ChangePINPage> {

  final TextEditingController _oldPINController = TextEditingController();
  final TextEditingController _newPINController = TextEditingController();
  final TextEditingController _confirmPINController = TextEditingController();
  final formOldPIN = GlobalKey<FormState>();
  final formNewPIN = GlobalKey<FormState>();
  final formConfirmPIN = GlobalKey<FormState>();
  var focusNodeOldPIN = FocusNode();
  var focusNodeConfirmPIN = FocusNode();
  int _index = 0;

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
          "Change PIN".tr(),
          style: TextStyle(
            color: Config.DEFAULT_ACCENT_COLOR,
          ),
        ),
      ),
      body: _index == 0 
            ? oldPIN() 
            : _index == 1
              ? newPIN()
              : confirmPIN(),
    );
  }

  Widget oldPIN() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Enter Your Old PIN Code".tr(),
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16.0,
          ),
        ),
        const SizedBox(height: 30.0),
        Center(
          child: SizedBox(
            width: 300,
            child: PinCodeTextField(
              key: formOldPIN,
              controller: _oldPINController,
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
              focusNode: focusNodeOldPIN,
              onCompleted: (val) async {
                setState(() {
                  _oldPINController.text = val;
                });
                EasyLoading.show(status: "Please Wait".tr());
                String pin = await PreferencesProvider().getSharedPref("pin") ?? "";
                EasyLoading.dismiss();
                if(_oldPINController.text != pin) {
                  AlertProvider.showAlertDialog(
                    message: "Old PIN code you entered is wrong".tr()
                  ).then((value) {
                    focusNodeOldPIN.requestFocus();
                  });
                  return;
                }

                setState(() {
                  _index = 1;
                });
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

                EasyLoading.show(status: "Please Wait".tr());
                EasyLoading.dismiss();
                setState(() {
                  _index = 2;
                });
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

                EasyLoading.show(status: "Please Wait".tr());
                EasyLoading.dismiss();
                if(_confirmPINController.text != _newPINController.text) {
                  AlertProvider.showAlertDialog(
                    message: "Confirm PIN code you entered does not match".tr()
                  ).then((value) {
                    focusNodeConfirmPIN.requestFocus();
                  });
                  return;
                }

                PreferencesProvider().setSharedPref("pin", _confirmPINController.text).then((value) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MessagePage(
                        icon: const Icon(Icons.check_circle, size: 100, color: Colors.green),
                        title: "Success".tr(),
                        subTitle: "PIN has been changed".tr(),
                      ),
                    ),
                  ).then((value) {
                    Navigator.pop(context, true);
                  });
                });
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
}