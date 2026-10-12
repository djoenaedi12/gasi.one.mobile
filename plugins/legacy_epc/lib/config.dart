// ignore_for_file: non_constant_identifier_names

import 'package:epeoplecare/model/client.dart';
import 'package:epeoplecare/model/appearance_setting.dart';
import 'package:epeoplecare/model/custom_value.dart';
import 'package:epeoplecare/model/menu_type.dart';
import 'package:epeoplecare/model/module.dart';
import 'package:epeoplecare/model/screen_argument.dart';
import 'package:epeoplecare/model/session.dart';
import 'package:epeoplecare/model/user.dart';
import 'package:epeoplecare/model/verification_type.dart';
import 'package:epeoplecare/model/license.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';

class Config {
  static String baseUrl = "https://YmFzZS1hcGkucGVvcGxlY2FyZS5pZC9ld2YtYmFzZQ==";
  static String baseClientId = "RVdGLU1vYmlsZQ==";
  static String baseClientSecret = "Y2FiN2M2OTlhNDM1NGJkYzQyOWRiNDc1";
  static String baseUsername = "bW9iaWxl";
  static String basePassword = "ZTJkMWQ1ZDg0YTMzNGQ0N2Y2YTFlZGU3";
  static String androidAppId = "com.gasi.ewf";
  static String iOSAppId = "1568281618";
  static Session? session;
  static Client? client;
  static AppearanceSetting? appearanceSetting;
  static User? user;
  static VerificationType? verificationType;
  static License? license;
  static String serverTimezone = "+07:00";
  static bool updateAvailable = false;
  static String version = "";
  static String deviceId = "";
  static bool showDisabledMenu = true;
  static String language = "en";
  static String fcmToken = "";
  static PackageInfo packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
    buildSignature: 'Unknown',
  );
  static bool switchAccount = false;
  static bool showRateLimitPopup = false;

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static Color DEFAULT_COLOR = const Color(0xFF1E88E5);
  static Color DEFAULT_ACCENT_COLOR = Colors.white;
  static Color SEMANTIC_COLOR_SUCCESS = const Color(0xFF2FD071);
  static Color SEMANTIC_COLOR_DANGER = const Color(0xFFF1460D);
  static bool isManager = false;
  static bool unsafeDevice = false;
  static bool isSignatureValid = true;
  // Konfigurasi untuk menyimpan informasi kamera yang digunakan
  // By default system / kamera bawaan
  static String cameraPreference = "system";

  static List<Module> getMenuOthers(String route, BuildContext context) {
    List<Module> menuModules = [];
    for (var role in Config.user!.roles) {
      for (var menu in role.menus) {
        if(menu.visible == true && menu.url == route) {
          for (var child in menu.childs) {
            if(child.visible == true && hasMenuAccess(child.id) == true) {
              String module = menu.module ?? "";
              var title = child.title.startsWith("tr(") ? child.title.substring(3, child.title.length - 1).tr() : child.title;
              var icon = IconData(int.parse("${child.classStr}"), fontFamily: "MaterialIcons");
              menuModules.add(Module(
                title,
                false,
                icon,
                () {
                  Navigator.pushNamed(
                    context,
                    child.url,
                    arguments: ScreenArgument(title, icon, null),
                  ).then((value) {
                  });
                },
                module,
                menu.sequence,
              ));
            }
          }
        }
      }
    }

    menuModules.sort((a, b) {
      return a.sequence.compareTo(b.sequence);
    });

    return menuModules;
  }
  
  static bool hasMenuAccess(int? menuId) {
    for (var role in Config.user!.roles) {
      for (var menu in role.menus) {
        if(menu.visible == true && menu.menuType == MenuType.MOBILE && menu.id == menuId) {
          return true;
        }
      }
    }

    return false;
  }

  static String? oldAttachment(String? oldAttachment, List<Media> medias) {
    for (var media in medias) {
      if(media.oldAttachment) {
        return oldAttachment;
      }
    }

    return null;
  }

  static List<Media> excludeOldAttachment(List<Media> medias) {
    List<Media> _medias = [];
    for (var media in medias) {
      if(!media.oldAttachment) {
        _medias.add(media);
      }
    }

    return _medias;
  }

  static bool hasPermission(String entity, String action) {
    if(user != null) {
      String permission = "${entity.toLowerCase().trim()}_${action.toLowerCase().trim()}";
      for (var role in user!.roles) {
        for (var accessRight in role.accessRights) {
          if(accessRight.entity != null && accessRight.action != null) {
            String key = "${accessRight.entity!.name.toLowerCase().trim()}_${accessRight.action!.name.toLowerCase().trim()}";
            if(key == permission) {
              return true;
            }
          }
        }
      }
    }

    return false;
  }
}