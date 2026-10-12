import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/response.dart';
import 'package:epeoplecare/model/session.dart';
import 'package:epeoplecare/provider/encoder_provider.dart';
import 'package:epeoplecare/repository/base_repository.dart';

class AuthRepository  extends BaseRepository<Session> {
  AuthRepository(String url, String accessToken, String refreshToken, String language) : super(url, accessToken, refreshToken, language) {
    //
  }

  /// Melakukan proses login menggunakan kredensial pengguna.
  ///
  /// Method ini akan memvalidasi kombinasi [clientId], [clientSecret],
  /// [username], dan [password] ke sistem autentikasi.
  /// Jika autentikasi berhasil dan tidak memerlukan MFA,
  /// method ini akan mengembalikan objek [Session].
  ///
  /// Apabila akun pengguna mengaktifkan MFA (Multi-Factor Authentication),
  /// sistem dapat menginisiasi proses OTP dan mengharuskan pemanggilan
  /// method [verifyOtp] untuk menyelesaikan proses login.
  ///
  /// Parameter:
  /// - [clientId] ID client aplikasi yang digunakan untuk autentikasi.
  /// - [clientSecret] Secret key client aplikasi.
  /// - [username] Username atau identifier pengguna.
  /// - [password] Password pengguna.
  /// - [deviceToken] Token unik perangkat untuk keperluan MFA dan trusted device.
  ///
  /// Return:
  /// - Mengembalikan objek [Session] jika login berhasil.
  /// - Mengembalikan Exception jika login gagal atau memerlukan verifikasi OTP.
  ///
  /// Throws:
  /// - [Exception] jika kredensial tidak valid, kegagalan komunikasi dengan server, dan memerlukan verifikasi OTP.
  Future<Session?> login(String clientId, String clientSecret, String username, String password, String deviceToken) async {
    Session? result;
    Map<String, String> headers = HashMap();
    headers["Authorization"] = "Basic ${EncoderProvider().encode("$clientId:$clientSecret")}";
    headers["Device"] = "${Platform.operatingSystem}/${Platform.operatingSystemVersion}";
    headers["Version"] = Config.packageInfo.version;
    headers["X-Device-Token"] = deviceToken;

    Map<String, dynamic> parameters = HashMap();
    parameters["grant_type"] = "password";
    parameters["username"] = username;
    parameters["password"] = password;

    var response = await getApiProvider().post(
      url: "${getBaseUrl()}/oauth/token",
      headers: headers,
      body: parameters,
      isJson: false,
      // isValidate: false,
    );

    var data = jsonDecode(response.body);
    if(response.statusCode == 200) {
      result = Session.fromJson(data);
    } else if(response.statusCode == 409) {
      var message = data['message'];
      if(message != null && message.toString() == "MFA_REQUIRED") {
        throw Exception(response.body); // for OTP
      }
    } else {
      var message = "";
      if(data['message'] != null) {
        message = (response.statusCode == 200) ? "${response.statusCode}${data['message']}" : data['message'].toString();
      } else if (data['error_description'] != null) {
        message = (response.statusCode == 200) ? "${response.statusCode}${data['error_description']}" : data['error_description'].toString();
      }
      throw Exception(message);
    }
 
    return result;
  }

  Future<Response> logout() async {
    Response<String> result = Response();
    var response = await getApiProvider().post(
      url: "${getBaseUrl()}/oauth/logout",
      headers: generateHeader(),
      // isValidate: false,
    );

    var data = jsonDecode(response.body);
    if(response.statusCode == 200 && data['success'] == true) {
      result.fromJson(data, "");
    } else {
      var message = "";
      if(data['message'] != null) {
        message = (response.statusCode == 200) ? "${response.statusCode}${data['message']}" : data['message'].toString();
      } else if (data['error_description'] != null) {
        message = (response.statusCode == 200) ? "${response.statusCode}${data['error_description']}" : data['error_description'].toString();
      }
      throw Exception(message);
    }
    return result;
  }

  Future<Response> changePassword(String oldPassword, String newPassword, String confirmPassword, int id) async {
    Response<String> result = Response();
    Map<String, dynamic> parameters = HashMap();
    parameters["old_password"] = oldPassword;
    parameters["password"] = newPassword;
    parameters["confirm_password"] = confirmPassword;
    
    var response = await getApiProvider().put(
      url: "${getBaseUrl()}/api/v1/user/change-password/$id",
      headers: generateHeader(),
      body: parameters,
    );


    var data = jsonDecode(response.body);
    if(response.statusCode == 200 && data['success'] == true) {
      result.fromJson(data, "");
    } else {
      var message = "";
      if(data['message'] != null) {
        message = (response.statusCode == 200) ? "${response.statusCode}${data['message']}" : data['message'].toString();
      } else if (data['error_description'] != null) {
        message = (response.statusCode == 200) ? "${response.statusCode}${data['error_description']}" : data['error_description'].toString();
      }
      throw Exception(message);
    }
 
    return result;
  }

  Future<Response> forgotPassword(String username) async {
    Response<String> result = Response();
    var response = await getApiProvider().get(
      url: "${getBaseUrl()}/password/forgot?username=$username",
      // isValidate: false,
    );

    var data = jsonDecode(response.body);
    if(response.statusCode == 200 && data['success'] == true) {
      result.fromJson(data, "");
    } else {
      var message = "";
      if(data['message'] != null) {
        message = (response.statusCode == 200) ? "${response.statusCode}${data['message']}" : data['message'].toString();
      } else if (data['error_description'] != null) {
        message = (response.statusCode == 200) ? "${response.statusCode}${data['error_description']}" : data['error_description'].toString();
      }
      throw Exception(message);
    }
    return result;
  }

  Future<Session?> refreshToken(String clientId, String clientSecret, String refreshToken) async {
    Session? result;
    Map<String, String> headers = HashMap();
    headers["Authorization"] = "Basic ${EncoderProvider().encode("$clientId:$clientSecret")}";
    headers["Device"] = "${Platform.operatingSystem}/${Platform.operatingSystemVersion}";
    headers["Version"] = Config.packageInfo.version;

    Map<String, dynamic> parameters = HashMap();
    parameters["grant_type"] = "password";
    parameters["refresh_token"] = refreshToken;

    var response = await getApiProvider().post(
      url: "${getBaseUrl()}/oauth/token",
      headers: headers,
      body: parameters,
      isJson: false,
      // isValidate: false,
    );

    var data = jsonDecode(response.body);
    if(response.statusCode == 200) {
      result = Session.fromJson(data);
    } else {
      var message = "";
      if(data['message'] != null) {
        message = (response.statusCode == 200) ? "${response.statusCode}${data['message']}" : data['message'].toString();
      } else if (data['error_description'] != null) {
        message = (response.statusCode == 200) ? "${response.statusCode}${data['error_description']}" : data['error_description'].toString();
      }
      throw Exception(message);
    }
 
    return result;
  }

  /// Memverifikasi kode OTP (One-Time Password) untuk menyelesaikan proses login.
  ///
  /// Method ini digunakan setelah login awal berhasil tetapi
  /// memerlukan verifikasi tambahan melalui OTP (MFA).
  ///
  /// Parameter:
  /// - [transactionId] ID transaksi OTP yang dihasilkan saat proses login.
  /// - [otp] Kode OTP yang dimasukkan oleh pengguna.
  ///
  /// Return:
  /// - Mengembalikan objek [Session] jika OTP valid dan verifikasi berhasil.
  /// - Mengembalikan `null` jika OTP tidak valid atau telah kedaluwarsa.
  ///
  /// Throws:
  /// - [Exception] jika OTP salah, OTP sudah kedaluwarsa, OTP locked, terjadi kegagalan komunikasi dengan server.
  Future<Session?> verifyOtp(String transactionId, String otp) async {
    Session? result;
    String clientId = Config.client!.clientId;
    String clientSecret = Config.client!.clientSecret;
    Map<String, String> headers = HashMap();
    headers["Authorization"] = "Basic ${EncoderProvider().encode("$clientId:$clientSecret")}";

    Map<String, dynamic> parameters = HashMap();
    parameters["transaction_id"] = transactionId;
    parameters["otp"] = otp;

    var response = await getApiProvider().post(
      url: "${getBaseUrl()}/oauth/verify-otp",
      headers: headers,
      body: parameters,
      isJson: false,
    );
    
    var data = jsonDecode(response.body);
    if(response.statusCode == 200) {
      if(data['message'] != null) {
        throw Exception(response.body);
      }
      else {
        result = fromJson(data);
      }
    } else {
      var message = "";
      if(data['message'] != null) {
        message = (response.statusCode == 200) ? "${response.statusCode}${data['message']}" : data['message'].toString();
      } else if (data['error_description'] != null) {
        message = (response.statusCode == 200) ? "${response.statusCode}${data['error_description']}" : data['error_description'].toString();
      }
      throw Exception(message);
    }
    return result;
  }

  /// Mengirim ulang kode OTP berdasarkan transaksi yang masih aktif.
  ///
  /// Method ini digunakan ketika pengguna tidak menerima OTP
  /// atau OTP sebelumnya telah kedaluwarsa tetapi transaksi
  /// masih valid.
  ///
  /// Parameter:
  /// - [transactionId] ID transaksi OTP yang sebelumnya dibuat.
  ///
  /// Return:
  /// - Mengembalikan objek [Response<String>] dengan status sukses
  ///   dan pesan konfirmasi jika OTP berhasil dikirim ulang.
  /// - Response berisi pesan error jika transaksi tidak valid.
  ///
  /// Throws:
  /// - [Exception] jika transactionId tidak ditemukan, OTP masih active, OTP locked, terjadi kegagalan komunikasi dengan server.
  Future<Response<String>> resendOtp(String transactionId) async {
    Response<String> result = Response();
    String clientId = Config.client!.clientId;
    String clientSecret = Config.client!.clientSecret;
    Map<String, String> headers = HashMap();
    headers["Authorization"] = "Basic ${EncoderProvider().encode("$clientId:$clientSecret")}";

    Map<String, dynamic> parameters = HashMap();
    parameters["transaction_id"] = transactionId;

    var response = await getApiProvider().post(
      url: "${getBaseUrl()}/oauth/resend-otp",
      headers: headers,
      body: parameters,
      isJson: false,
      // isValidate: false,
    );

    var data = jsonDecode(response.body);
    if(response.statusCode == 200 && data['success'] == true) {
      result.fromJson(data, "");
    } else {
      var message = "";
      if(data['message'] != null) {
        message = (response.statusCode == 200) ? "${response.statusCode}${data['message']}" : data['message'].toString();
      } else if (data['error_description'] != null) {
        message = (response.statusCode == 200) ? "${response.statusCode}${data['error_description']}" : data['error_description'].toString();
      }
      throw Exception(message);
    }
    return result;
  }

  @override
  Session? fromJson(Map<String, dynamic>? json) {
    return Session.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(Session entity) {
    return entity.toJson();
  }

}