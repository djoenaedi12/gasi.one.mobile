import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/business_license.dart';
import '../models/business_context_models.dart';

final class InstalledBusinessContextStorage {
  InstalledBusinessContextStorage(this._preferences);

  final SharedPreferences _preferences;

  /// COMPAT[INSTALLED-DATA]: retain the license keys used by installed EPC
  /// versions and account switching until an explicit data migration exists.
  BusinessLicense? readLicense() {
    if (!_preferences.containsKey('license')) return null;
    return BusinessContextModels.license({
      'license': _preferences.getString('license') ?? '',
      'expiry_date': _preferences.getString('expiry_date') ?? '',
      'modules': (_preferences.getString('modules') ?? '')
          .split(';')
          .where((item) => item.isNotEmpty)
          .toList(growable: false),
      'company_code': _preferences.getString('company_code') ?? '',
      'host_name': _preferences.getString('host_name') ?? '',
    });
  }

  Future<void> savePushToken(String token) async {
    if (!await _preferences.setString('fcmToken', token)) {
      throw StateError('Could not persist the push token.');
    }
  }
}
