import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gasione_core_api/gasione_core_api.dart';
import 'package:gasione_core_starter/src/utils/notification_utils.dart';

enum AppNotificationPermissionStatus {
  authorized,
  denied,
  deniedPermanently,
  notDetermined,
  provisional,
}

final class AppNotification {
  AppNotification({
    required this.id,
    this.title,
    this.body,
    Map<String, Object?> data = const {},
    this.payload,
  }) : data = Map.unmodifiable(data);

  final int id;
  final String? title;
  final String? body;
  final Map<String, Object?> data;
  final String? payload;
}

final class NotificationInteraction {
  NotificationInteraction({this.payload, Map<String, Object?> data = const {}})
    : data = Map.unmodifiable(data);

  final String? payload;
  final Map<String, Object?> data;
}

abstract interface class NotificationService implements PushTokenProvider {
  bool get isLocalInitialized;

  bool get isPushInitialized;

  Stream<AppNotification> get foregroundMessages;

  Stream<NotificationInteraction> get interactions;

  @override
  Stream<String> get tokenRefreshes;

  Future<void> initializeLocal();

  Future<void> initializePush({FirebaseOptions? options});

  Future<AppNotificationPermissionStatus> checkPermission();

  Future<AppNotificationPermissionStatus> requestPermission();

  @override
  Future<String?> getToken();

  Future<void> deleteToken();

  Future<void> subscribeToTopic(String topic);

  Future<void> unsubscribeFromTopic(String topic);

  Future<void> showLocal(AppNotification notification);

  Future<void> cancel(int id);

  Future<void> cancelAll();

  Future<bool> openNotificationSettings();

  NotificationInteraction? getInitialInteraction();

  Future<void> dispose();
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
}

final class FirebaseNotificationService implements NotificationService {
  FirebaseNotificationService({
    FlutterLocalNotificationsPlugin? localNotifications,
    AndroidNotificationChannel? androidChannel,
  }) : _localNotifications =
           localNotifications ?? FlutterLocalNotificationsPlugin(),
       _androidChannel = androidChannel ?? _channel;

  static const _channelId = 'general_notifications';
  static const _channelName = 'General notifications';
  static const _channelDescription = 'General application notifications.';
  static const _channel = AndroidNotificationChannel(
    _channelId,
    _channelName,
    description: _channelDescription,
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin _localNotifications;
  final AndroidNotificationChannel _androidChannel;
  final StreamController<AppNotification> _foregroundMessages =
      StreamController.broadcast();
  final StreamController<NotificationInteraction> _interactions =
      StreamController.broadcast();
  final StreamController<String> _tokenRefreshes = StreamController.broadcast();

  FirebaseMessaging? _messaging;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<RemoteMessage>? _interactionSubscription;
  StreamSubscription<String>? _tokenSubscription;
  NotificationInteraction? _initialInteraction;
  bool _isLocalInitialized = false;
  bool _isPushInitialized = false;

  @override
  bool get isLocalInitialized => _isLocalInitialized;

  @override
  bool get isPushInitialized => _isPushInitialized;

  @override
  Stream<AppNotification> get foregroundMessages => _foregroundMessages.stream;

  @override
  Stream<NotificationInteraction> get interactions => _interactions.stream;

  @override
  Stream<String> get tokenRefreshes => _tokenRefreshes.stream;

  @override
  Future<void> initializeLocal() async {
    if (_isLocalInitialized) {
      return;
    }

    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      _isLocalInitialized = true;
      return;
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onLocalNotificationResponse,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);

    final launchDetails = await _localNotifications
        .getNotificationAppLaunchDetails();
    final response = launchDetails?.notificationResponse;
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      _initialInteraction = _fromLocalResponse(response);
    }

    _isLocalInitialized = true;
  }

  @override
  Future<void> initializePush({FirebaseOptions? options}) async {
    if (_isPushInitialized) {
      return;
    }

    await initializeLocal();
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: options);
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    final messaging = FirebaseMessaging.instance;
    _messaging = messaging;
    await messaging.setAutoInitEnabled(true);

    await messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );

    _messageSubscription = FirebaseMessaging.onMessage.listen(
      _onForegroundMessage,
    );
    _interactionSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => _interactions.add(_interactionFromRemoteMessage(message)),
    );
    _tokenSubscription = messaging.onTokenRefresh.listen(_tokenRefreshes.add);

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _initialInteraction = _interactionFromRemoteMessage(initialMessage);
    }

    _isPushInitialized = true;
  }

  @override
  Future<AppNotificationPermissionStatus> checkPermission() async {
    final messaging = _messaging;
    if (messaging != null) {
      final settings = await messaging.getNotificationSettings();
      return _fromFirebaseAuthorization(settings.authorizationStatus);
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      final enabled = await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.areNotificationsEnabled();
      return enabled ?? false
          ? AppNotificationPermissionStatus.authorized
          : AppNotificationPermissionStatus.denied;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final status = await _localNotifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.checkPermissions();
      if (status == null) {
        return AppNotificationPermissionStatus.notDetermined;
      }
      if (status.isProvisionalEnabled) {
        return AppNotificationPermissionStatus.provisional;
      }
      return status.isEnabled
          ? AppNotificationPermissionStatus.authorized
          : AppNotificationPermissionStatus.denied;
    }

    return AppNotificationPermissionStatus.authorized;
  }

  @override
  Future<AppNotificationPermissionStatus> requestPermission() async {
    final messaging = _messaging;
    if (messaging != null) {
      final settings = await messaging.requestPermission();
      return _fromFirebaseAuthorization(settings.authorizationStatus);
    }

    bool? granted;
    if (defaultTargetPlatform == TargetPlatform.android) {
      granted = await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      granted = await _localNotifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    return granted ?? true
        ? AppNotificationPermissionStatus.authorized
        : AppNotificationPermissionStatus.denied;
  }

  @override
  Future<String?> getToken() => _messaging?.getToken() ?? Future.value();

  @override
  Future<void> deleteToken() async {
    await _messaging?.deleteToken();
  }

  @override
  Future<void> subscribeToTopic(String topic) {
    return _requireMessaging().subscribeToTopic(topic);
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) {
    return _requireMessaging().unsubscribeFromTopic(topic);
  }

  @override
  Future<void> showLocal(AppNotification notification) async {
    await initializeLocal();
    final payload =
        notification.payload ??
        NotificationUtils.encodePayload(notification.data);

    await _localNotifications.show(
      id: notification.id,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: _androidChannel.importance,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  @override
  Future<void> cancel(int id) => _localNotifications.cancel(id: id);

  @override
  Future<void> cancelAll() => _localNotifications.cancelAll();

  @override
  Future<bool> openNotificationSettings() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _localNotifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.openAppNotificationSettings() ??
          false;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return await _localNotifications
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.openAppNotificationSettings() ??
          false;
    }
    return false;
  }

  @override
  NotificationInteraction? getInitialInteraction() => _initialInteraction;

  @override
  Future<void> dispose() async {
    await Future.wait([
      if (_messageSubscription case final subscription?) subscription.cancel(),
      if (_interactionSubscription case final subscription?)
        subscription.cancel(),
      if (_tokenSubscription case final subscription?) subscription.cancel(),
    ]);
    await Future.wait([
      _foregroundMessages.close(),
      _interactions.close(),
      _tokenRefreshes.close(),
    ]);
  }

  void _onForegroundMessage(RemoteMessage message) {
    final notification = _fromRemoteMessage(message);
    _foregroundMessages.add(notification);
    if (notification.title != null || notification.body != null) {
      unawaited(showLocal(notification));
    }
  }

  void _onLocalNotificationResponse(NotificationResponse response) {
    _interactions.add(_fromLocalResponse(response));
  }

  FirebaseMessaging _requireMessaging() {
    final messaging = _messaging;
    if (messaging == null) {
      throw StateError('Push notifications have not been initialized.');
    }
    return messaging;
  }

  AppNotification _fromRemoteMessage(RemoteMessage message) {
    final data = Map<String, Object?>.from(message.data);
    final seed =
        message.messageId ??
        '${message.sentTime?.millisecondsSinceEpoch ?? 0}:${message.data}';
    return AppNotification(
      id: NotificationUtils.stableId(seed),
      title: message.notification?.title,
      body: message.notification?.body,
      data: data,
      payload:
          data['payload']?.toString() ?? NotificationUtils.encodePayload(data),
    );
  }

  NotificationInteraction _interactionFromRemoteMessage(RemoteMessage message) {
    final data = Map<String, Object?>.from(message.data);
    return NotificationInteraction(
      payload:
          data['payload']?.toString() ?? NotificationUtils.encodePayload(data),
      data: data,
    );
  }

  NotificationInteraction _fromLocalResponse(NotificationResponse? response) {
    final payload = response?.payload;
    return NotificationInteraction(
      payload: payload,
      data: NotificationUtils.decodePayload(payload),
    );
  }

  AppNotificationPermissionStatus _fromFirebaseAuthorization(
    AuthorizationStatus status,
  ) {
    return switch (status) {
      AuthorizationStatus.authorized =>
        AppNotificationPermissionStatus.authorized,
      AuthorizationStatus.denied => AppNotificationPermissionStatus.denied,
      AuthorizationStatus.deniedPermanently =>
        AppNotificationPermissionStatus.deniedPermanently,
      AuthorizationStatus.notDetermined =>
        AppNotificationPermissionStatus.notDetermined,
      AuthorizationStatus.provisional =>
        AppNotificationPermissionStatus.provisional,
    };
  }
}
