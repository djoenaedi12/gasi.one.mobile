import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/view/shared/message_unsafe.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:launch_review/launch_review.dart';

class AlertProvider {

  static Future<bool> showAlertDialog({
    String? title,
    String? message,
    bool isDismissable = true,
    List<Widget>? actions,
  }) async {
    BuildContext context = Config.navigatorKey.currentContext!;
    AlertDialog alert = AlertDialog(
      title: Text(title ?? "Information".tr()),
      content: Text("$message"),
      actions: actions ?? [
        TextButton(
          child: Text("Ok".tr()),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ],
    );

    await showDialog(
      barrierDismissible: isDismissable,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );

    return true;
  }

  static Future<bool> showConfirmationDialog({
    String? title,
    String? message,
    bool isDismissable= true,
  }) async {
    BuildContext context = Config.navigatorKey.currentContext!;
    AlertDialog alert = AlertDialog(
      title: Text(title ?? "Confirmation".tr()),
      content: Text("$message"),
      actions: [
        TextButton(
          child: Text("Cancel".tr()),
          onPressed: () {
            Navigator.pop(context, false);
          },
        ),
        TextButton(
          child: Text("Yes".tr()),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
      ],
    );

    return await showDialog(
      barrierDismissible: isDismissable,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  static Future<bool> showUpdateAvailableDialog() async {
    if(Config.isSignatureValid && !Config.unsafeDevice) {
      if(Config.showRateLimitPopup) {
        BuildContext context = Config.navigatorKey.currentContext!;
        Future.delayed(const Duration(seconds: 1)).then((value) async {
          AlertDialog alert = AlertDialog(
            content: Text("TooManyRequestMessage".tr()),
            actions: [
              TextButton(
                child: Text("Try Again".tr()),
                onPressed: () async {
                  Phoenix.rebirth(context);
                },
              ),
            ],
          );

          await showDialog(
            barrierDismissible: false,
            context: context,
            builder: (BuildContext context) {
              return PopScope(
                canPop: false,
                child: alert
              );
            },
          );
        });
      }
      else if(Config.updateAvailable) {
        BuildContext context = Config.navigatorKey.currentContext!;
        Future.delayed(const Duration(seconds: 1)).then((value) async {
          AlertDialog alert = AlertDialog(
            title: Text("Update Available".tr()),
            content: Text("UpdateAvailableMessage".tr(namedArgs: {"version": Config.version})),
            actions: [
              TextButton(
                child: Text("Cancel".tr()),
                onPressed: () {
                  exit(0);
                },
              ),
              TextButton(
                child: Text("Update Now".tr()),
                onPressed: () async {
                  final Uri url = Uri.parse(Platform.isIOS ? "https://apps.apple.com/app/id${Config.iOSAppId}" : "https://play.google.com/store/apps/details?id=${Config.androidAppId}");
                  if(await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ],
          );

          await showDialog(
            barrierDismissible: false,
            context: context,
            builder: (BuildContext context) {
              return PopScope(
                canPop: false,
                child: alert
              );
            },
          );
        });
      }
    }

    return true;
  }

  static Future<bool> showUnSafeDeviceDialog() async {
    if(Config.isSignatureValid && Config.unsafeDevice) {
      BuildContext context = Config.navigatorKey.currentContext!;
      Future.delayed(const Duration(seconds: 1)).then((value) async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MessageUnsafePage(
            ),
          ),
        );
      });
    }

    return true;
  }

  static Future<bool> showSignatureDialog() async {
    if(!Config.isSignatureValid) {
      BuildContext context = Config.navigatorKey.currentContext!;
      Future.delayed(const Duration(seconds: 1)).then((value) async {
        AlertDialog alert = AlertDialog(
          title: Text("Invalid Application".tr()),
          content: Text("InvalidApplicationMessage".tr()),
          actions: [
            TextButton(
              child: Text("Exit".tr()),
              onPressed: () {
                exit(0);
              },
            ),
          ],
        );

        await showDialog(
          barrierDismissible: false,
          context: context,
          builder: (BuildContext context) {
            return PopScope(
              canPop: false,
              child: alert
            );
          },
        );
      });
    }

    return true;
  }
}
