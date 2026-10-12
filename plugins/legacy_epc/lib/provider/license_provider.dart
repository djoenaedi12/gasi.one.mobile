import 'package:epeoplecare/model/license.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LicenseProvider {
  Future<SharedPreferences> prefInstanc = SharedPreferences.getInstance();

  Future<String> getLicense() async {
    final SharedPreferences pref = await prefInstanc;
    return pref.getString("license") ?? "";
  }

  Future<String> getExpiryDate() async {
    final SharedPreferences pref = await prefInstanc;
    return pref.getString("expiry_date") ?? "";
  }

  Future<String> getHostName() async {
    final SharedPreferences pref = await prefInstanc;
    return pref.getString("host_name") ?? "";
  }

  Future<String> getCompanyCode() async {
    final SharedPreferences pref = await prefInstanc;
    return pref.getString("company_code") ?? "";
  }

  Future<List<String>> getModules() async {
    final SharedPreferences pref = await prefInstanc;
    String modulesStr = pref.getString("modules") ?? "";
    return modulesStr.split(";");
  }

  Future<bool> setLicense(License? license) async {
    if(license != null) {
      final SharedPreferences pref = await prefInstanc;
      license.toJson().forEach((key, value) async { 
        if(key == "modules") {
          String modulesStr = "";
          for (String module in license.modules) {
            modulesStr += "$module;";
          }
          await pref.setString(key, modulesStr);
        } else {
          await pref.setString(key, value ?? "");
        }
        
      });
    }

    return true;
  }

  Future<License?> getLicenseModel() async {
    final SharedPreferences pref = await prefInstanc;

    if(!pref.containsKey("license")) return null;

    return License(
      pref.getString("license") ?? "",
      pref.getString("expiry_date") ?? "",
      await getModules(),
      pref.getString("company_code") ?? "",
      pref.getString("host_name") ?? "",
    );
  }

  Future<bool> destroyLicense() async {
    final SharedPreferences pref = await prefInstanc;
    pref.remove("license");
    pref.remove("expiry_date");
    pref.remove("modules");
    pref.remove("company_code");
    pref.remove("host_name");
    return true;
  }
}