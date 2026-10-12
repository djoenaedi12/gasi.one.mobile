import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/parameter.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class ParameterRepository extends BaseRepository<Parameter> {
  
  ParameterRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    setUrl("/api/v1/parameter");
  }

  Future<Parameter?> findByName(String name) async {
    Map<String, dynamic> parameters = HashMap();
    parameters["name"] = name;
    return find(parameters: parameters);
  }

  Future<Parameter?> getPwdRulePattern() async {
    Parameter? result = await findByName("PWD_RULE_PATTERN");
    return result;
  }

  Future<Parameter?> getPwdRuleMessage() async {
    Parameter? result = await findByName("PWD_RULE_MESSAGE");
    return result;
  }

  Future<Parameter?> getCurrentYear() async {
    Parameter? result = await findByName("CURRENT_YEAR");
    return result;
  }

  Future<Parameter?> getTimeZone() async {
    Parameter? result = await findByName("TIMEZONE");
    return result;
  }

  Future<Parameter?> getShowDisabledMenu() async {
    Parameter? result = await findByName("SHOW_DISABLED_MENU");
    return result;
  }

  Future<Parameter?> getSessionMobileDevice() async {
    Parameter? result = await findByName("SESSION_MOBILE_DEVICE");
    return result;
  }

  Future<String?> getMobileAppVersion(String accessToken) async {
    Map<String, String> headers = HashMap();
    headers["Authorization"] = "Bearer $accessToken";
    headers["Content-Type"] = "application/json";
    headers["Device"] = "${Platform.operatingSystem}/${Platform.operatingSystemVersion}";
    headers["DeviceId"] = Config.deviceId;
    headers["Version"] = Config.packageInfo.version;

    Map<String, String> parameters = HashMap();
    String platform = "android";
    if(Platform.isIOS) {
      platform = "ios";
    }
    parameters["platform"] = platform;

    String? result;
    var response = await getApiProvider().get(
      url: "${getBaseUrl()}${getUrl()}/getmobileappversion${buildParameter(parameters, true)}",
      headers: headers,
    );

    if(response.statusCode == 200) {
      var json = jsonDecode(response.body);
      if(json['success'] == true) {
        result = json['data'];
      }
    }

    return result;
  }

  Future<Parameter?> getSwitchAccount() async {
    Parameter? result = await findByName("SWITCH_ACCOUNT");
    return result;
  }

  Future<Parameter?> getFirstInstallmentVisibility() async {
    Parameter? result = await findByName("LOAN_INSTALLMENT_VISIBILITY");
    return result;
  }

  @override
  Parameter? fromJson(Map<String, dynamic>? json) {
    return Parameter.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(Parameter entity) {
    return entity.toJson();
  }

}