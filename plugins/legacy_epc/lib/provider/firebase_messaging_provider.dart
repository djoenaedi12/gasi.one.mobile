import 'package:epeoplecare/config.dart';

/// TRANSITION[LEGACY-PUSH]: token access for old login/OTP consumers.
/// The platform owns initialization, permission, listeners, and disposal.
class FirebaseMessagingProvider {
  Future<String?> getToken() => Config.notifications.getToken();
}
