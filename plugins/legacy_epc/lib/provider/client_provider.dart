import 'package:epeoplecare/model/base_model.dart';
import 'package:epeoplecare/model/client.dart';
import 'package:epeoplecare/provider/encoder_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClientProvider {
  Future<SharedPreferences> prefInstance = SharedPreferences.getInstance();

  Future<String> getUrl() async {
    final SharedPreferences pref = await prefInstance;
    return pref.getString("url") ?? "";
  }

  Future<String> getClientId() async {
    final SharedPreferences pref = await prefInstance;
    return pref.getString("client_id") ?? "";
  }

  Future<String> getClientSecret() async {
    final SharedPreferences pref = await prefInstance;
    return pref.getString("client_secret") ?? "";
  }

  Future<bool> isClient() async {
    final SharedPreferences pref = await prefInstance;
    String isLogin = pref.getString("isClient") ?? "";
    return isLogin == "1" ? true : false;
  }

  Future<bool> setClient(Client? client, String prefix) async {
    if(client != null) {
      final SharedPreferences pref = await prefInstance;
      client.toJson().forEach((key, value) async { 
        if(key == "id" || key == "version") {
          await pref.setInt(prefix + key, value ?? 0);
        } else if(key == "custom_values" || key == "medias") {
          
        } else {
          await pref.setString(prefix + key, value ?? "");
        }
        
      });
      await pref.setString("${prefix}isClient", "1");
    }

    return true;
  }

  Future<Client?> getClient(String prefix) async {
    final SharedPreferences pref = await prefInstance;

    if(!pref.containsKey("${prefix}code")) return null;
    
    return Client(
      pref.getInt("${prefix}id") ?? 0,
      pref.getString("${prefix}creator") ?? "",
      pref.getString("${prefix}creation_time") ?? "",
      pref.getString("${prefix}updater") ?? "",
      pref.getString("${prefix}update_time") ?? "",
      pref.getInt("${prefix}version") ?? 0,
      BaseModel.getCustomValue(null),
      BaseModel.getMedia(null),
      pref.getString("${prefix}code") ?? "",
      pref.getString("${prefix}name") ?? "",
      pref.getString("${prefix}url") ?? "",
      pref.getString("${prefix}image") ?? "",
      pref.getString("${prefix}client_id") ?? "",
      pref.getString("${prefix}client_secret") ?? "",
    );
  }

  Future<bool> destroyClient() async {
    final SharedPreferences pref = await prefInstance;
    pref.remove("id");
    pref.remove("creator");
    pref.remove("creation_time");
    pref.remove("updater");
    pref.remove("update_time");
    pref.remove("version");
    pref.remove("code");
    pref.remove("name");
    pref.remove("url");
    pref.remove("image");
    pref.remove("client_id");
    pref.remove("client_secret");
    pref.remove("isClient");
    return true;
  }

  String safeBase64Decode(String value) {
    try {
      return EncoderProvider().decode(value.split("").reversed.join());
    } catch (_) {
      return value;
    }
  }
}