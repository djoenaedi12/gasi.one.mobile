import 'package:flutter_test/flutter_test.dart';
import 'package:gasione_core_starter/gasione_core_starter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'active token adapter shares installed keys and preserves saved accounts',
    () async {
      SharedPreferences.setMockInitialValues({
        'access_token': 'old',
        'refresh_token': 'refresh',
        'isLogin': '1',
        'accounts': <String>['saved'],
        'savedaccess_token': 'saved-token',
      });
      final preferences = await SharedPreferences.getInstance();
      final store = InstalledTokenStorage(preferences);
      expect(await store.readAccessToken(), 'old');
      await store.saveTokens(accessToken: 'new', refreshToken: 'new-refresh');
      expect(preferences.getString('access_token'), 'new');
      await store.clearTokens();
      expect(await store.readAccessToken(), isNull);
      expect(preferences.getString('isLogin'), isNull);
      expect(preferences.getStringList('accounts'), ['saved']);
      expect(preferences.getString('savedaccess_token'), 'saved-token');
    },
  );
}
