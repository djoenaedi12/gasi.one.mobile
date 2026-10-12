import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/pagination.dart';
import 'package:epeoplecare/model/response.dart';
import 'package:epeoplecare/model/sort.dart';
import 'package:epeoplecare/provider/api_provider.dart';
import 'package:epeoplecare/provider/enum_provider.dart';
abstract class BaseRepository<T> {
  
  ApiProvider _apiProvider = ApiProvider();
  String _baseUrl;
  late String _url;
  String _accessToken;
  String _refreshToken;
  String _language;

  BaseRepository(this._baseUrl, this._accessToken, this._refreshToken, this._language);

  String getUrl() {
    return this._url;
  }

  void setUrl(String url) {
    this._url = url;
  }

  String getBaseUrl() {
    return this._baseUrl;
  }

  void setBaseUrl(String baseUrl) {
    this._baseUrl = baseUrl;
  }

  ApiProvider getApiProvider() {
    return this._apiProvider;
  }

  void setApiProvider(ApiProvider apiProvider) {
    this._apiProvider = apiProvider;
  }

  void setAccessToken(String accessToken) {
    this._accessToken = accessToken;
  }

  String getAccessToken() {
    return this._accessToken;
  }

  void setRefreshToken(String refreshToken) {
    this._refreshToken = refreshToken;
  }

  String getRefreshToken() {
    return this._refreshToken;
  }

  void setLanguage(String language) {
    this._language = language;
  }

  String getLanguage() {
    return this._language;
  }

  Map<String, String> generateHeader() {
    Map<String, String> headers =  HashMap();
    headers["Authorization"] = "Bearer $_accessToken";
    headers["Content-Type"] = "application/json";
    headers["Accept-Language"] = _language;
    headers["Device"] = "${Platform.operatingSystem}/${Platform.operatingSystemVersion}";
    headers["DeviceId"] = Config.deviceId;
    headers["Version"] = Config.packageInfo.version;
    return headers;
  }

  Map<String, String> generateHeaderWithoutToken() {
    Map<String, String> headers =  HashMap();
    headers["Content-Type"] = "application/json";
    headers["Accept-Language"] = _language;
    headers["Device"] = "${Platform.operatingSystem}/${Platform.operatingSystemVersion}";
    headers["DeviceId"] = Config.deviceId;
    headers["Version"] = Config.packageInfo.version;
    return headers;
  }

  // ================================= GENERIC API =====================================
  Future<List<T>> list({
    Map<String, String>? headers,
    Map<String, dynamic>? parameters,
    List<Sort>? sorts,
    int page = 0,
    int size = -1,
  }) async {
    List<T> result = [];
    var response = await _apiProvider.get(
      url: "$_baseUrl$_url?page=$page&size=$size${buildParameter(parameters, false)}${buildSort(sorts, false)}",
      headers: headers ?? generateHeader(),
    );

    if(response.statusCode == 200) {
      var json = jsonDecode(response.body);
      if(json['success'] == true) {
        for (var i = 0; i < json['data']['content'].length; i++) {
          T? item = fromJson(json['data']['content'][i]);
          if(item != null) {
            result.add(item);
          }
        }
      }
    }

    return result;
  }

  Future<Pagination<T>> listPagination({
    Map<String, String>? headers,
    Map<String, dynamic>? parameters,
    List<Sort>? sorts,
    int page = 0,
    int size = 10,
  }) async {
    Pagination<T> result = Pagination();
    var response = await _apiProvider.get(
      url: "$_baseUrl$_url?page=$page&size=$size${buildParameter(parameters, false)}${buildSort(sorts, false)}",
      headers: headers ?? generateHeader(),
    );

    if(response.statusCode == 200) {
      var json = jsonDecode(response.body);
      if(json['success'] == true) {
        result.fromJson(json['data']);
        for (var i = 0; i < json['data']['content'].length; i++) {
          T? item = fromJson(json['data']['content'][i]);
          if(item != null) {
            result.add(item);
          }
        }
      }
    }

    return result;
  }

  /// listPaginationReference sama seperti listPagination, 
  /// Bedanya hanya akses end point ini di API tidak dicek hak akses nya dan data yang dikembalikan minimalis.
  /// 
  /// Gunakan `listPaginationReference` jika butuh data untuk referensi tapi user ybs tidak mempunyai akses ke data tersebut
  Future<Pagination<T>> listPaginationReference({
    Map<String, String>? headers,
    Map<String, dynamic>? parameters,
    List<Sort>? sorts,
    int page = 0,
    int size = 10,
  }) async {
    Pagination<T> result = Pagination();
    var response = await _apiProvider.get(
      url: "$_baseUrl$_url/reference?page=$page&size=$size${buildParameter(parameters, false)}${buildSort(sorts, false)}",
      headers: headers ?? generateHeader(),
    );

    if(response.statusCode == 200) {
      var json = jsonDecode(response.body);
      if(json['success'] == true) {
        result.fromJson(json['data']);
        for (var i = 0; i < json['data']['content'].length; i++) {
          T? item = fromJson(json['data']['content'][i]);
          if(item != null) {
            result.add(item);
          }
        }
      }
    }

    return result;
  }

  Future<T?> findById({
    int? id,
    Map<String, String>? headers,
  }) async {
    T? result;
    var response = await _apiProvider.get(
      url: "$_baseUrl$_url/$id",
      headers: headers ?? generateHeader(),
    );

    if(response.statusCode == 200) {
      var json = jsonDecode(response.body);
      if(json['success'] == true) {
        result = fromJson(json['data']);
      }
    }

    return result;
  }

  Future<T?> find({
    required Map<String, dynamic>? parameters,
    Map<String, String>? headers,
  }) async {
    T? result;
    var response = await _apiProvider.get(
      url: "$_baseUrl$_url/get${buildParameter(parameters, true)}",
      headers: headers ?? generateHeader(),
    );

    if(response.statusCode == 200) {
      var json = jsonDecode(response.body);
      if(json['success'] == true) {
        result = fromJson(json['data']);
      }
    }

    return result;
  }

  Future<Response> save({
    required T entity,
    Map<String, String>? headers,
  }) async {
    Response<T?> result = Response();
    var response = await _apiProvider.post(
      url: "$_baseUrl$_url",
      headers: headers ?? generateHeader(),
      body: toJson(entity),
    );

    var json = jsonDecode(response.body);
    if(response.statusCode == 200 && json['success'] != null && json['success'] == true) {
      result.fromJson(json, fromJson(json['data']));
    } else {
      var message = "";
      if(json['message'] != null) {
        message = (response.statusCode == 200) ? "${response.statusCode}${json['message']}" : json['message'].toString();
      } else if (json['error_description'] != null) {
        message = (response.statusCode == 200) ? "${response.statusCode}${json['error_description']}" : json['error_description'].toString();
      }
      throw Exception(message);
    }
    
    return result;
  }

  Future<Response> update({
    required int id, 
    required T entity,
    Map<String, String>? headers,
  }) async {
    Response<T?> result = Response();
    var response = await _apiProvider.put(
      url: "$_baseUrl$_url/$id",
      headers: headers ?? generateHeader(),
      body: toJson(entity),
    );

    var json = jsonDecode(response.body);
    if(response.statusCode == 200 && json['success'] != null && json['success'] == true) {
      result.fromJson(json, fromJson(json['data']));
    } else {
      var message = "";
      if(json['message'] != null) {
        message = (response.statusCode == 200) ? "${response.statusCode}${json['message']}" : json['message'].toString();
      } else if (json['error_description'] != null) {
        message = (response.statusCode == 200) ? "${response.statusCode}${json['error_description']}" : json['error_description'].toString();
      }
      throw Exception(message);
    }

    return result;
  }

  Future<Response> delete({
    required int id,
    Map<String, String>? headers,
  }) async {
    Response<T?> result = Response();
    var response = await _apiProvider.delete(
      url: "$_baseUrl$_url/$id",
      headers: headers ?? generateHeader(),
    );

    var json = jsonDecode(response.body);
    if(response.statusCode == 200 && json['success'] != null && json['success'] == true) {
      result.fromJson(json, fromJson(json['data']));
    } else {
      var message = "";
      if(json['message'] != null) {
        message = (response.statusCode == 200) ? "${response.statusCode}${json['message']}" : json['message'].toString();
      } else if (json['error_description'] != null) {
        message = (response.statusCode == 200) ? "${response.statusCode}${json['error_description']}" : json['error_description'].toString();
      }
      throw Exception(message);
    }

    return result;
  }

  String buildParameter(Map<String, dynamic>? parameters, bool firstParam) {
    if(parameters == null) return "";

    String result = "";
    parameters.forEach((key, value) { 
      if (firstParam) {
        result += "?";
        firstParam = false;
      } else {
        result += "&";
      }

      result += "$key=";
      if(value.runtimeType.toString().contains("List")) {
        List<dynamic> list = value;
        for (var i = 0; i < list.length; i++) {
          if(i==0) {
            result += list[i].toString();
          } else {
            result += "&$key=${list[i].toString()}";
          }
        }
      } else {
         result += value.toString();
      }
    });

    return result;
  }

  String buildSort(List<Sort>? sorts, bool firstParam) {
    if(sorts == null) return "";

    String result = "";
    for (var value in sorts) { 
      if (firstParam) {
        result += "?";
        firstParam = false;
      } else {
        result += "&";
      }

      result += "sort=${value.getSort()},${EnumProvider.convertToString(value.getSortDirection())}";
    }

    return result;
  }

  T? fromJson(Map<String, dynamic>? json);
  Map<String, dynamic> toJson(T entity);

}