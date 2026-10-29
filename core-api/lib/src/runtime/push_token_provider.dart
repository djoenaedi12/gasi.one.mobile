/// The small push capability needed by features that register device tokens.
/// FOUNDATION: shared feature contract, retained after legacy migration.
abstract interface class PushTokenProvider {
  Future<String?> getToken();
  Stream<String> get tokenRefreshes;
}
