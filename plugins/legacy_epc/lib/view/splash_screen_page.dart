import 'dart:async';

import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/view/auth/client_page.dart';
import 'package:epeoplecare/view/auth/login_page.dart';
import 'package:epeoplecare/view/verification/verification_setup_page.dart';
import 'package:epeoplecare/view/verification/verification_page.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class SplashScreenPage extends StatefulWidget {
  const SplashScreenPage({super.key});

  @override
  State<StatefulWidget> createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> {
  @override
  void initState() {
    super.initState();
    startSplashScreen();
  }

  Timer startSplashScreen() {
    var duration = const Duration(seconds: 2);
    return Timer(duration, () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => Config.client == null
              ? const ClientPage()
              : Config.session == null || Config.user == null
              ? const LoginPage()
              : Config.verificationType != null
              ? VerificationPage(verificationType: Config.verificationType!)
              : const VerificationSetupPage(isTwoFactorAuthentication: true),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Center(
          child: Column(
            children: [
              Expanded(
                child: Image.asset(
                  "assets/img/logo.png",
                  width: 200.0,
                  height: 200.0,
                ),
              ),
              Text("${"Version".tr()} ${Config.packageInfo.version}"),
            ],
          ),
        ),
      ),
    );
  }
}
