import 'dart:async';
import 'dart:io';

import 'package:gasione_core_starter/gasione_core_starter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'application/business_context_loader.dart';
import 'data/datasources/business_context_remote_data_source.dart';
import 'data/repositories/business_context_repository_impl.dart';
import 'data/services/api_device_policy_service.dart';
import 'data/services/backend_push_registration_service.dart';
import 'data/storage/installed_business_context_storage.dart';
import 'domain/entities/business_context.dart';
import 'domain/services/push_registration_service.dart';

final class BusinessContextPlugin implements BusinessContextProvider {
  BusinessContextPlugin({
    required ApiClient api,
    required AppRuntime runtime,
    required this.notifications,
    required SharedPreferences preferences,
    required String Function() baseUrl,
    required String Function() language,
    this.onPushRegistered,
    this.onError,
  }) {
    _preferences = preferences;
    _baseUrl = baseUrl;
    _storage = InstalledBusinessContextStorage(preferences);
    final remote = BusinessContextRemoteDataSource(
      api: api,
      runtime: runtime,
      baseUrl: baseUrl,
      language: language,
      device: '${Platform.operatingSystem}/${Platform.operatingSystemVersion}',
    );
    final repository = BusinessContextRepositoryImpl(remote, _storage);
    _loader = BusinessContextLoader(
      repository,
      ApiDevicePolicyService(remote, runtime),
    );
    _push = BackendPushRegistrationService(remote);
  }

  final PushTokenProvider notifications;
  final void Function(String token)? onPushRegistered;
  final void Function(String operation, Object error, StackTrace stack)?
  onError;
  late final BusinessContextLoader _loader;
  late final PushRegistrationService _push;
  late final InstalledBusinessContextStorage _storage;
  StreamSubscription<String>? _tokenSubscription;
  BusinessContext? _current;
  bool _started = false;
  bool _disposed = false;

  late final SharedPreferences _preferences;
  late final String Function() _baseUrl;
  final _changes = StreamController<ActiveBusinessContext?>.broadcast();
  int _generation = 0;
  @override
  Stream<ActiveBusinessContext?> get contextChanges => _changes.stream;
  @override
  ActiveBusinessContext? get activeContext {
    final context = _current;
    final employee = context?.user.employee;
    if (context == null || employee == null) return null;
    return ActiveBusinessContext(
      company: CompanyIdentity(
        code: _preferences.getString('code') ?? '',
        baseUrl: _baseUrl(),
      ),
      employee: employee,
      username: context.user.username,
      serverTimezone: context.serverTimezone,
      isManager: context.isManager,
      sessionId: 'business-context-$_generation',
      permissions: {
        for (final permission in context.user.permissions)
          BusinessAccess(permission.entity, permission.action),
      },
    );
  }

  BusinessContext? get current => _current;

  Future<BusinessContext> load({
    required String username,
    required bool validateDevice,
  }) async {
    if (_disposed) {
      throw const ApiException(ApiExceptionType.cancelled);
    }
    final generation = ++_generation;
    _current = null;
    _changes.add(null);
    final context = await _loader.load(
      username: username,
      validateDevice: validateDevice,
    );
    if (_disposed || generation != _generation) {
      throw const ApiException(ApiExceptionType.cancelled);
    }
    _current = context;
    _changes.add(activeContext);
    unawaited(_registerCurrentToken());
    return context;
  }

  void clear() {
    _generation++;
    _current = null;
    if (!_disposed) _changes.add(null);
  }

  void start() {
    if (_started || _disposed) return;
    _started = true;
    _tokenSubscription = notifications.tokenRefreshes.listen((token) {
      if (_current != null) {
        unawaited(_register(token));
      }
    });
  }

  Future<void> _registerCurrentToken() async {
    try {
      final token = await notifications.getToken();
      if (token != null && _current != null) {
        await _register(token);
      }
    } catch (error, stack) {
      if (!_disposed) {
        onError?.call('push_registration', error.runtimeType, stack);
      }
    }
  }

  Future<void> _register(String token) async {
    final context = _current;
    if (context == null) return;
    try {
      if (!_disposed) {
        await _push.register(token);
      }
      if (_disposed || !identical(_current, context)) return;
      await _storage.savePushToken(token);
      if (_disposed || !identical(_current, context)) return;
      onPushRegistered?.call(token);
    } catch (error, stack) {
      if (!_disposed) {
        onError?.call('push_registration', error.runtimeType, stack);
      }
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    _current = null;
    await _tokenSubscription?.cancel();
    await _changes.close();
  }
}
