import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gasione_core_starter/gasione_core_starter.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _info = AppInfo(
  appName: 'GASI',
  packageName: 'test.gasi',
  version: '1.2.3',
  buildNumber: '4',
);
const _security = DeviceSecurity(unsafeDevice: false, signatureValid: true);

class _Preferences implements PreferencesStorage {
  String? deviceId;
  int writes = 0;
  bool failWrites = false;

  @override
  Future<String?> readString(String key) async => deviceId;
  @override
  Future<void> writeString(String key, String value) async {
    if (failWrites) throw StateError('fixture storage failure');
    writes++;
    deviceId = value;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'retains an installed app device ID and shares concurrent initialization',
    () async {
      final preferences = _Preferences()..deviceId = 'existing-device';
      var checks = 0;
      final pending = Completer<AppInfo>();
      final service = AppRuntimeService(
        preferences,
        loadInfo: () => pending.future,
        checkSecurity: () async {
          checks++;
          return _security;
        },
        createDeviceId: () => throw StateError('ID must be retained'),
      );
      final first = service.load();
      final second = service.load();
      expect(identical(first, second), isTrue);
      pending.complete(_info);
      final runtime = await first;
      expect(runtime.deviceId, 'existing-device');
      expect(runtime.info, _info);
      expect(runtime.security, _security);
      expect(preferences.writes, 0);
      expect(checks, 1);
      expect(await service.load(), same(runtime));
    },
  );

  test('persists a newly generated ID before returning runtime', () async {
    final preferences = _Preferences();
    final service = AppRuntimeService(
      preferences,
      loadInfo: () async => _info,
      checkSecurity: () async => _security,
      createDeviceId: () => 'new-device',
    );
    final runtime = await service.load();
    expect(runtime.deviceId, 'new-device');
    expect(preferences.deviceId, 'new-device');
    expect(preferences.writes, 1);
  });

  test(
    'storage failure fails startup and can be retried without a new service',
    () async {
      final preferences = _Preferences()..failWrites = true;
      final service = AppRuntimeService(
        preferences,
        loadInfo: () async => _info,
        checkSecurity: () async => _security,
        createDeviceId: () => 'new-device',
      );
      await expectLater(service.load(), throwsStateError);
      preferences.failWrites = false;
      expect((await service.load()).deviceId, 'new-device');
    },
  );

  test(
    'security failures are not converted into a successful device check',
    () async {
      final preferences = _Preferences()..deviceId = 'existing-device';
      var fail = true;
      final service = AppRuntimeService(
        preferences,
        loadInfo: () async => _info,
        checkSecurity: () async {
          if (fail) throw StateError('fixture native failure');
          return _security;
        },
      );
      await expectLater(service.load(), throwsStateError);
      fail = false;
      expect((await service.load()).security.signatureValid, isTrue);
    },
  );

  test(
    'cached storage reads and writes the exact keys used by installed EPC',
    () async {
      SharedPreferences.setMockInitialValues({
        'deviceId': 'installed-device',
        'language': 'id',
      });
      final preferences = await SharedPreferences.getInstance();
      final storage = CachedPreferencesStorage(preferences);
      expect(await storage.readString('deviceId'), 'installed-device');
      expect(await storage.readString('language'), 'id');
      await storage.writeString('deviceId', 'updated-device');
      expect(preferences.getString('deviceId'), 'updated-device');
    },
  );
}
