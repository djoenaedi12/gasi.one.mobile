import 'package:epeoplecare/model/session.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionProvider {

  Future<SharedPreferences> prefInstance = SharedPreferences.getInstance();

  Future<String> getUsername() async {
    final SharedPreferences pref = await prefInstance;
    return pref.getString("username") ?? "";
  }

  Future<bool> setUsername(String username) async {
    final SharedPreferences pref = await prefInstance;
    return pref.setString("username", username);
  }

  Future<String> getAccessToken() async {
    final SharedPreferences pref = await prefInstance;
    return pref.getString("access_token") ?? "";
  }

  Future<bool> setAccessToken(String accessToken) async {
    final SharedPreferences pref = await prefInstance;
    return pref.setString("access_token", accessToken);
  }

  Future<String> getRefreshToken() async {
    final SharedPreferences pref = await prefInstance;
    return pref.getString("refresh_token") ?? "";
  }

  Future<bool> setRefreshToken(String refreshToken) async {
    final SharedPreferences pref = await prefInstance;
    return pref.setString("refresh_token", refreshToken);
  }

  Future<bool> setSession(Session? session, String prefix) async {
    if(session != null) {
      final SharedPreferences pref = await prefInstance;
      session.toJson().forEach((key, value) async { 
        await pref.setString(prefix + key, value ?? "");
      });
      await pref.setString("${prefix}isLogin", "1");
    }

    if(prefix != "") {
      final SharedPreferences pref = await prefInstance;
      List<String>? accounts = pref.getStringList("accounts");
      accounts ??= [];
      if(!accounts.contains(prefix)) {
        accounts.add(prefix);
        await pref.setStringList("accounts", accounts);
      }
    }

    return true;
  }

  Future<bool> isLogin() async {
    final SharedPreferences pref = await prefInstance;
    String isLogin = pref.getString("isLogin") ?? "";
    return isLogin == "1" ? true : false;
  }

  Future<Session?> getSession(String prefix) async {
    final SharedPreferences pref = await prefInstance;

    if(!pref.containsKey("${prefix}access_token")) return null;
    
    return Session(
      pref.getString("${prefix}access_token") ?? "",
      pref.getString("${prefix}refresh_token") ?? "",
      pref.getString("${prefix}token_type") ?? "",
      pref.getString("${prefix}scope") ?? "",
      pref.getString("${prefix}jti") ?? "",
      pref.getString("${prefix}username") ?? "",
      pref.getString("${prefix}device_token") ?? "",
    );
  }

  Future<bool> destroySession(String prefix) async {
    final SharedPreferences pref = await prefInstance;
    pref.remove("${prefix}access_token");
    pref.remove("${prefix}refresh_token");
    pref.remove("${prefix}token_type");
    pref.remove("${prefix}scope");
    pref.remove("${prefix}jti");
    pref.remove("${prefix}username");
    pref.remove("${prefix}isLogin");

    if(prefix != "") {
      final SharedPreferences pref = await prefInstance;
      List<String>? accounts = pref.getStringList("accounts");
      accounts ??= [];
      List<String>? accountsTmp = [];
      for (var account in accounts) {
        if(account != prefix) {
          accountsTmp.add(account);
        }  
      }
      await pref.setStringList("accounts", accountsTmp);
    }
    return true;
  }

  Future<String> getDeviceToken() async {
    final SharedPreferences pref = await prefInstance;
    return pref.getString("device_token") ?? "";
  }
}
