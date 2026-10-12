import 'package:epeoplecare/model/base_model.dart';

class AppearanceSetting extends BaseModel{

  String? appName;
  String? appLogo;
  String? sidebarTheme;
  String? sidebarVariant;
  int sidebarElevation = 0;
  String? navbarTheme;
  String? navbarVariant;
  bool navbarBorder = true;
  bool darkMode = false;
  String? customStyle;
  String? welcomePageWeb;
  String? welcomePageMobile;
  String? colorMobile;
  String? accentColorMobile;

  AppearanceSetting(
    id,
    creator,
    creationTime,
    updater,
    updateTime,
    version,
    customValues,
    medias,
    this.appName,
    this.appLogo,
    this.sidebarTheme,
    this.sidebarVariant,
    this.sidebarElevation,
    this.navbarTheme,
    this.navbarVariant,
    this.navbarBorder,
    this.darkMode,
    this.customStyle,
    this.welcomePageWeb,
    this.welcomePageMobile,
    this.colorMobile,
    this.accentColorMobile,
  ): super(id, creator, creationTime, updater, updateTime, version, customValues, medias);

  static AppearanceSetting? fromJson(dynamic json) {
    if (json == null) return null;

    return AppearanceSetting(
      json['id'],
      json['creator'],
      json['creation_time'],
      json['updater'],
      json['update_time'],
      json['version'],
      BaseModel.getCustomValue(json),
      BaseModel.getMedia(json),
      json['app_name'],
      json['app_logo'],
      json['sidebar_theme'],
      json['sidebar_variant'],
      json['sidebar_elevation'],
      json['navbar_theme'],
      json['navbar_variant'],
      json['navbar_border'],
      json['dark_mode'],
      json['custom_style'],
      json['welcome_page_web'],
      json['welcome_page_mobile'],
      json['color_mobile'],
      json['accent_color_mobile'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "creator": creator,
      "creation_time": creationTime,
      "updater": updater,
      "update_time": updateTime,
      "version": version,
      "custom_values": customValues,
      "medias": medias,
      "app_name": appName,
      "app_logo": appLogo,
      "sidebar_theme": sidebarTheme,
      "sidebar_variant": sidebarVariant,
      "sidebar_elevation": sidebarElevation,
      "navbar_theme": navbarTheme,
      "navbar_variant": navbarVariant,
      "navbar_border": navbarBorder,
      "dark_mode": darkMode,
      "custom_style": customStyle,
      "welcome_page_web": welcomePageWeb,
      "welcome_page_mobile": welcomePageMobile,
      "color_mobile": colorMobile,
      "accent_color_mobile": accentColorMobile,
    };
  }

}