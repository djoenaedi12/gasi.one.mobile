// ignore_for_file: empty_catches

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/parameter.dart';
import 'package:epeoplecare/repository/auth_repository.dart';
import 'package:epeoplecare/repository/parameter_repository.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/validation/validation.dart';
import 'package:epeoplecare/view/shared/input_form.dart';
import 'package:epeoplecare/view/shared/message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<StatefulWidget> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final form = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isObscureTextOld = true;
  bool _isObscureTextNew = true;
  bool _isObscureTextConfirm = true;
  final AuthRepository _authRepository = Repository().getAuthRepository();
  final ParameterRepository _parameterRepository = Repository().getParameterRepository();
  Parameter? _pwdRulePattern;
  Parameter? _pwdRuleMessage;

  @override
  void initState() {
    super.initState();

    _parameterRepository.getPwdRulePattern().then((value) {
      setState(() {
        _pwdRulePattern = value;
      });
    });

    _parameterRepository.getPwdRuleMessage().then((value) {
      setState(() {
        _pwdRuleMessage = value;
      });
    });
  }

  void _submitForm() async {
    if (form.currentState!.validate()) {
      EasyLoading.show(status: "Please Wait".tr());
      _authRepository.changePassword(_oldPasswordController.text, _newPasswordController.text, _confirmPasswordController.text, Config.user!.id ?? 0).then((value) {
        EasyLoading.dismiss();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessagePage(
              icon: const Icon(Icons.check_circle, size: 100, color: Colors.green),
              title: "Success".tr(),
              subTitle: "Password has been changed".tr(),
            ),
          ),
        ).then((value) {
          Navigator.pop(context, true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Config.DEFAULT_COLOR,
        iconTheme: IconThemeData(
          color: Config.DEFAULT_ACCENT_COLOR,
        ),
        title: Text(
          "Change Password".tr(),
          style: TextStyle(
            color: Config.DEFAULT_ACCENT_COLOR,
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(10.0),
          child: Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InputForm().renderPasswordField(
                  fieldName: "Old Password".tr(),
                  controller: _oldPasswordController,
                  obscureText: _isObscureTextOld,
                  onTap: () {
                    setState(() {
                      _isObscureTextOld = !_isObscureTextOld;
                    });
                  },
                  validator: Validation.validateField
                ),
                InputForm().renderPasswordField(
                  fieldName: "New Password".tr(),
                  controller: _newPasswordController,
                  obscureText: _isObscureTextNew,
                  onTap: () {
                    setState(() {
                      _isObscureTextNew = !_isObscureTextNew;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "This field is required".tr();
                    }else if (_pwdRulePattern != null && _pwdRulePattern!.value.isNotEmpty) {
                      String  pattern = _pwdRulePattern!.value;
                      RegExp regExp = RegExp(pattern);
                      try {
                        if(!regExp.hasMatch(value)) {
                          return _pwdRuleMessage != null ? _pwdRuleMessage!.value : "";
                        }                        
                      } catch (e) {
                      }
                    }
                    return null;
                  }
                ),
                InputForm().renderPasswordField(
                  fieldName: "Confirm Password".tr(),
                  controller: _confirmPasswordController,
                  obscureText: _isObscureTextConfirm,
                  onTap: () {
                    setState(() {
                      _isObscureTextConfirm = !_isObscureTextConfirm;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "This field is required".tr();
                    }else if (value != _newPasswordController.text) {
                      return "Confirm password doesn't match".tr();
                    }
                    return null;
                  }
                ),
                InputForm().renderButton(
                  text: "Change Password".tr(),
                  onPressed: () {
                    _submitForm();
                  }
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}