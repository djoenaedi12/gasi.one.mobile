import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/repository/auth_repository.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/validation/validation.dart';
import 'package:epeoplecare/view/shared/input_form.dart';
import 'package:epeoplecare/view/shared/message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<StatefulWidget> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  
  final form = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final AuthRepository _authRepository = Repository().getAuthRepository();

  _recoveryPassword() async {
    if (form.currentState!.validate()) {
      EasyLoading.show(status: "Please Wait".tr());
      _authRepository.forgotPassword(_usernameController.text).then((value) {
        EasyLoading.dismiss();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessagePage(
              icon: const Icon(Icons.check_circle, size: 100, color: Colors.green),
              title: "Success".tr(),
              subTitle: "Password reset email sent".tr(),
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
              title: "Error",
              subTitle: onError.toString(),
            ),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var mediaQuery = MediaQuery.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Config.DEFAULT_COLOR,
        iconTheme: IconThemeData(
          color: Config.DEFAULT_ACCENT_COLOR,
        ),
        title: Text(
          "Forgot Password".tr(),
          style: TextStyle(
            color: Config.DEFAULT_ACCENT_COLOR,
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: Container(
        height: mediaQuery.size.height,
        padding: const EdgeInsets.all(
          20.0,
        ),
        color: Colors.white,
        child: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              children: [
                InputForm().renderTextField(
                  fieldName: "Enter your username and we'll send to your email the instructions for resetting password".tr(),
                  controller: _usernameController,
                  validator: Validation.validateField,
                ),
                InputForm().renderButton(
                  text: "Submit".tr(),
                  onPressed: () {
                    _recoveryPassword();
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
