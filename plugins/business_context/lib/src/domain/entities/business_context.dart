import 'business_license.dart';
import 'business_user.dart';

final class BusinessContext {
  const BusinessContext({
    required this.user,
    required this.license,
    required this.serverTimezone,
    required this.showDisabledMenu,
    required this.switchAccountEnabled,
    required this.isManager,
  });

  final BusinessUser user;
  final BusinessLicense? license;
  final String serverTimezone;
  final bool showDisabledMenu;
  final bool switchAccountEnabled;
  final bool isManager;
}
