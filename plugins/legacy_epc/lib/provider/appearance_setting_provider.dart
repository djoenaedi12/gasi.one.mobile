import 'package:epeoplecare/model/appearance_setting.dart';
import 'package:epeoplecare/model/base_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppearanceSettingProvider {
  Future<SharedPreferences> prefInstanc = SharedPreferences.getInstance();

  Future<String> getWelcomePage() async {
    final SharedPreferences pref = await prefInstanc;
    return pref.getString("welcome_page_mobile") ?? "";
  }

  Future<String> getAppName() async {
    final SharedPreferences pref = await prefInstanc;
    return pref.getString("app_name") ?? "";
  }

  Future<String> getAppLogo() async {
    final SharedPreferences pref = await prefInstanc;
    return pref.getString("app_logo") ?? "";
  }

  Future<String> getColor() async {
    final SharedPreferences pref = await prefInstanc;
    return pref.getString("color_mobile") ?? "";
  }

  Future<String> getAccentColor() async {
    final SharedPreferences pref = await prefInstanc;
    return pref.getString("accent_color_mobile") ?? "";
  }

  Future<bool> setAppearanceSetting(AppearanceSetting? appearanceSetting) async {
    if(appearanceSetting != null) {
      final SharedPreferences pref = await prefInstanc;
      appearanceSetting.toJson().forEach((key, value) async { 
        if(key == "id" || key == "version" || key == "sidebar_elevation") {
          await pref.setInt(key, value ?? 0);
        } else if(key == "navbar_border" || key == "dark_mode") {
          await pref.setBool(key, value ?? false);
        } else if(key == "custom_values" || key == "medias") {
          
        } else {
          await pref.setString(key, value ?? "");
        }
        
      });
    }

    return true;
  }

  Future<AppearanceSetting?> getAppearanceSetting() async {
    final SharedPreferences pref = await prefInstanc;

    if(!pref.containsKey("app_name")) return null;

    return AppearanceSetting(
      pref.getInt("id"),
      pref.getString("creator"),
      pref.getString("creation_time"),
      pref.getString("updater"),
      pref.getString("update_time"),
      pref.getInt("version"),
      BaseModel.getCustomValue(null),
      BaseModel.getMedia(null),
      pref.getString("app_name") ?? "",
      pref.getString("app_logo") ?? "",
      pref.getString("sidebar_theme") ?? "",
      pref.getString("sidebar_variant") ?? "",
      pref.getInt("sidebar_elevation") ?? 0,
      pref.getString("navbar_theme") ?? "",
      pref.getString("navbar_variant") ?? "",
      pref.getBool("navbar_border") ?? false,
      pref.getBool("dark_mode") ?? false,
      pref.getString("custom_style") ?? "",
      pref.getString("welcome_page_web") ?? "",
      pref.getString("welcome_page_mobile") ?? "",
      pref.getString("color_mobile") ?? "",
      pref.getString("accent_color_mobile") ?? "",
    );
  }

  Future<bool> destroyAppearanceSetting() async {
    final SharedPreferences pref = await prefInstanc;
    pref.remove("id");
    pref.remove("creator");
    pref.remove("creation_time");
    pref.remove("updater");
    pref.remove("update_time");
    pref.remove("version");
    pref.remove("app_name");
    pref.remove("app_logo");
    pref.remove("sidebar_theme");
    pref.remove("sidebar_variant");
    pref.remove("sidebar_elevation");
    pref.remove("navbar_theme");
    pref.remove("navbar_variant");
    pref.remove("navbar_border");
    pref.remove("dark_mode");
    pref.remove("custom_style");
    pref.remove("welcome_page_web");
    pref.remove("welcome_page_mobile");
    pref.remove("color_mobile");
    pref.remove("accent_color_mobile");
    return true;
  }
}