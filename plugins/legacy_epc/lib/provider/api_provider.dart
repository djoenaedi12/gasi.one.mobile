// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/provider/alert_provider.dart';
import 'package:epeoplecare/provider/session_provider.dart';
import 'package:epeoplecare/view/auth/login_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:easy_localization/easy_localization.dart';

class ApiProvider {

  Future<dynamic> post({
    required String url,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    int timeout = 60,
    bool isJson= true,
  }) async {
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: isJson ? jsonEncode(body) : body,
    ).timeout(Duration(seconds: timeout));

    // handler for specific response status
    responseHandler(response);

    return response;
  }

  Future<dynamic> get({
    required String url,
    Map<String, String>? headers,
    int timeout = 60,
  }) async {
    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    ).timeout(Duration(seconds: timeout));

    // handler for specific response status
    responseHandler(response);

    return response;
  }

  Future<dynamic> delete({
    required String url,
    Map<String, String>? headers,
    int timeout = 60,
  }) async {
    final response = await http.delete(
      Uri.parse(url),
      headers: headers,
    ).timeout(Duration(seconds: timeout));

    // handler for specific response status
    responseHandler(response);

    return response;
  }

  Future<dynamic> put({
    required String url,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    int timeout = 60,
    bool isJson= true,
  }) async {
    final response = await http.put(
      Uri.parse(url),
      headers: headers,
      body: isJson ? jsonEncode(body) : body,
    ).timeout(Duration(seconds: timeout));

    // handler for specific response status
    responseHandler(response);

    return response;
  }

  Future<dynamic> postMultipart({
    required String url,
    Map<String, String>? headers,
    Map<String, String>? parameters,
    File? fileParam,
    String fileParamName = "file",
    int timeout = 60,
  }) async {
    final multipartRequest = http.MultipartRequest(
      'POST', 
      Uri.parse(url),
    );

    if(headers != null) {
      multipartRequest.headers.addAll(headers);
    }

    if(parameters != null) {
      multipartRequest.fields.addAll(parameters);
    }

    if (fileParam != null) {
      final mimeTypeData = lookupMimeType(
        fileParam.path,
        headerBytes: [0xFF, 0xD8],
      )?.split('/');
      final file = await http.MultipartFile.fromPath(
        fileParamName,
        fileParam.path,
        contentType: MediaType(
          mimeTypeData![0],
          mimeTypeData[1],
        ),
      );
      multipartRequest.fields['ext'] = mimeTypeData[1];
      multipartRequest.files.add(file);
    }

    final streamedResponse = await multipartRequest.send();
    final response = await http.Response.fromStream(streamedResponse).timeout(Duration(seconds: timeout));

    // handler for specific response status
    responseHandler(response);

    return response;
  }

  Future<dynamic> putMultipart({
    required String url,
    Map<String, String>? headers,
    Map<String, String>? parameters,
    File? fileParam,
    String fileParamName = "file",
    int timeout = 60,
  }) async {
    final multipartRequest = http.MultipartRequest(
      'PUT', 
      Uri.parse(url),
    );

    if(headers != null) {
      multipartRequest.headers.addAll(headers);
    }

    if(parameters != null) {
      multipartRequest.fields.addAll(parameters);
    }

    if (fileParam != null) {
      final mimeTypeData = lookupMimeType(
        fileParam.path,
        headerBytes: [0xFF, 0xD8],
      )?.split('/');
      final file = await http.MultipartFile.fromPath(
        fileParamName,
        fileParam.path,
        contentType: MediaType(
          mimeTypeData![0],
          mimeTypeData[1],
        ),
      );
      multipartRequest.fields['ext'] = mimeTypeData[1];
      multipartRequest.files.add(file);
    }

    final streamedResponse = await multipartRequest.send();
    final response = await http.Response.fromStream(streamedResponse).timeout(Duration(seconds: timeout));

    // handler for specific response status
    responseHandler(response);
    
    return response;
  }

  void _sessionExpired(dynamic response) {
    var json = jsonDecode(response.body);
    String message = "Your session has been expired".tr();
    if(json['message'].toString().contains("Module")) {
      return;
    }
    else if(json['message'].toString().contains("License")) {
      message = "License not valid".tr();
    }
    if(Config.navigatorKey.currentContext != null) 
    {
      AlertProvider.showAlertDialog(
        message: message
      ).then((value) {
        Navigator.of(Config.navigatorKey.currentContext!).popUntil((route) => route.isFirst);
        SessionProvider().destroySession("").then((value) {
          Navigator.pushReplacement(
            Config.navigatorKey.currentContext!,
            MaterialPageRoute(
              builder: (context) => const LoginPage(),
            ),
          );
        });
      });
    }
  }

  // Fungsi untuk menghandle ketika ada response status tertentu
  // 503 => Under Maintenance
  // 429 => Too Many Request
  // 401 => Unauthorized / session expired
  void responseHandler(dynamic response) {
    if(response.statusCode == 503) {
      throw Exception("Under Maintenance");
    } else if(response.statusCode == 429) {
      // Handle untuk error 429
      // Throw exception dengan message 429: ${MESSAGE}
      // 429: sebagai flag
      var json = jsonDecode(response.body);
      throw Exception("429: ${json['message']}");
    } else if(response.statusCode == 401) {
      _sessionExpired(response);
    }
  }

}
