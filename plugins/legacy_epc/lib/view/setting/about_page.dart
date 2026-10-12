import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:flutter/material.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<StatefulWidget> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Config.DEFAULT_COLOR,
        iconTheme: IconThemeData(
          color: Config.DEFAULT_ACCENT_COLOR,
        ),
        title: Text(
          "About".tr(),
          style: TextStyle(
            color: Config.DEFAULT_ACCENT_COLOR,
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: const ScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              const SizedBox(height: 15.0),
              ClipRRect(
                borderRadius: const BorderRadius.all(
                  Radius.circular(100.0),
                ),
                child: Image.asset(
                  "assets/img/logo.png",
                  height: 150.0,
                  width: 150.0,
                  fit: BoxFit.cover,
                ),
              ),
              const Text(
                "e-PeopleCare",
                style: TextStyle(
                  color: Color(0xFF015281),
                  fontWeight: FontWeight.w500,
                  fontSize: 20.0,
                ),
              ),
              const SizedBox(height: 50.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Application Name".tr(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(Config.packageInfo.appName),
                ],
              ),
              Divider(
                height: 30.0,
                color: Colors.grey.shade300
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Version".tr(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text("${Config.packageInfo.version} (${Config.packageInfo.buildNumber})"),
                ],
              ),
              Divider(
                height: 30.0,
                color: Colors.grey.shade300
              ),
            ],
          ),
        ),
      ),
    );
  }
}
