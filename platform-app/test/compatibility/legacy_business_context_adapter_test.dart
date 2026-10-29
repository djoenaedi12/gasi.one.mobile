import 'package:epeoplecare/config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasione/app/compatibility/legacy_business_context_adapter.dart';
import 'package:gasione_plugin_business_context/gasione_plugin_business_context.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'restores installed shell then maps the new context into legacy Config',
    () async {
      SharedPreferences.setMockInitialValues({
        'isClient': '1',
        'code': 'ACME',
        'name': 'Acme',
        'url': 'https://tenant.test',
        'client_id': 'client',
        'client_secret': 'secret',
        'isLogin': '1',
        'access_token': 'access',
        'refresh_token': 'refresh',
        'token_type': 'bearer',
        'scope': '',
        'username': 'employee',
        'verificationType': 'PIN',
      });
      final preferences = await SharedPreferences.getInstance();
      var changes = 0;
      final adapter = LegacyBusinessContextAdapter(
        preferences,
        () => changes++,
      );

      final installed = await adapter.restoreInstalledState();
      expect(installed.hasCompany, isTrue);
      expect(installed.username, 'employee');
      expect(installed.verificationConfigured, isTrue);

      adapter.install(
        BusinessContext(
          user: BusinessUser(
            id: 7,
            username: 'employee',
            name: 'Employee',
            deviceId: 'device-1',
            menus: const [],
            permissions: const {},
            compatibilityPayload: const {
              'id': 7,
              'username': 'employee',
              'name': 'Employee',
              'roles': <Object>[],
              'login_failure': 0,
              'enabled': true,
            },
          ),
          license: BusinessLicense(
            value: 'licensed',
            expiryDate: '2030-01-01',
            modules: const ['attendance'],
            companyCode: 'ACME',
            hostName: 'tenant.test',
          ),
          serverTimezone: '+08:00',
          showDisabledMenu: false,
          switchAccountEnabled: true,
          isManager: true,
        ),
      );

      expect(Config.client?.code, 'ACME');
      expect(Config.session?.username, 'employee');
      expect(Config.user?.name, 'Employee');
      expect(Config.license?.modules, ['attendance']);
      expect(Config.serverTimezone, '+08:00');
      expect(Config.showDisabledMenu, isFalse);
      expect(Config.switchAccount, isTrue);
      expect(Config.isManager, isTrue);
      expect(changes, 2);
    },
  );
}
