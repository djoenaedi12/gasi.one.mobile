import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class LocalAuthProvider {

  final LocalAuthentication _localAuthentication = LocalAuthentication();

  Future<bool> isBiometricAvailable() async {
    late bool isAvailable;
    try {
      isAvailable = await _localAuthentication.canCheckBiometrics;
    } on PlatformException {
      isAvailable = false;
    }

    return isAvailable;
  }

  Future<bool> isFaceAvailable() async {
    late bool isAvailable;
    try {
      List<BiometricType> listOfBiometrics = await getListOfBiometricTypes();
      isAvailable = false;
      for (var element in listOfBiometrics) {
        if(element == BiometricType.face) {
          isAvailable = true;
          break;
        }
      }
    } on PlatformException {
      isAvailable = false;
    }

    return isAvailable;
  }

  Future<List<BiometricType>> getListOfBiometricTypes() async {
    late List<BiometricType> listOfBiometrics;
    try {
      listOfBiometrics = await _localAuthentication.getAvailableBiometrics();
    } on PlatformException {
      listOfBiometrics = <BiometricType>[];
    }

    return listOfBiometrics;
  }

  Future<bool> authenticateUser({required String title}) async {
    late bool isAuthenticated;
    try {
      isAuthenticated = await _localAuthentication.authenticate(
        localizedReason: title,
        options: const AuthenticationOptions(
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch(e) {
      isAuthenticated = false;
    }
    return isAuthenticated;
  }
  
}