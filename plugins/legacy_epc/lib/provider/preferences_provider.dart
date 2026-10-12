import 'package:shared_preferences/shared_preferences.dart';

class PreferencesProvider {
  
  Future<bool> setSharedPref(String key, String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(key, value);
    return true;
  }

  Future<bool> setSharedPrefInt(String key, int value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt(key, value);
    return true;
  }

  Future<String?> getSharedPref(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  Future<int?> getSharedPrefInt(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key);
  }

  Future<bool> removeSharedPref(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove(key);
    return true;
  }
}
