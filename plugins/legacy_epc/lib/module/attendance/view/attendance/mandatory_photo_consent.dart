import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/view/shared/input_form.dart';
import 'package:flutter/material.dart';

/// Class `MandatoryPhotoConsent` use for show the consent about mandatory photo when does not an attachment files
/// This page will be show once when user not notice about this (regulation)
/// Flag notice save to shared prefrence for next case this page not show
class MandatoryPhotoConsent extends StatefulWidget {

  const MandatoryPhotoConsent({super.key});

  @override
  State<StatefulWidget> createState() => _MandatoryPhotoConsentState();
}

class _MandatoryPhotoConsentState extends State<MandatoryPhotoConsent> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,          
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(25.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_camera_outlined,
                      color: Config.DEFAULT_COLOR,
                      size: 100.0,
                    ),
                    const SizedBox(height: 20.0),
                    Text(
                      "Mandatory Photo".tr(),
                      style: const TextStyle(
                        fontSize: 26.0,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    Text(
                      "As per regulation, please take a photo to complete this process".tr(),
                      style: const TextStyle(
                        fontSize: 14.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(25.0),
              child: InputForm().renderButton(
                text: "Take Photo".tr(),
                onPressed: () {
                  Navigator.pop(context, true);
                }
              ),
            ),
          ],
        ),
      ),
    );
  }
}