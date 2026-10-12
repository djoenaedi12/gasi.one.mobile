import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseMessagingProvider {

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  init() async {
    requestPermission();
    initLocalNotification();
    listen();
  }

  void listen() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails('your channel id', 'your channel name',
        channelDescription: 'your channel description',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        showProgress: true,
        ticker: 'ticker'
      );
      const DarwinNotificationDetails darwinNotificationDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails, iOS: darwinNotificationDetails);
      flutterLocalNotificationsPlugin.show(id: 0, title: message.notification!.title, body: message.notification!.body, notificationDetails: notificationDetails, payload: jsonEncode(message.data),);
    });
  }

  Future<String?> getToken() async {
    return await FirebaseMessaging.instance.getToken();
  }

  requestPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  initLocalNotification() {
    var initializationSettingsAndroid  = const AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettingsDarwnin = const DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    var initializationSettings = InitializationSettings(android: initializationSettingsAndroid, iOS: initializationSettingsDarwnin);
    flutterLocalNotificationsPlugin.initialize(settings: initializationSettings, onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) {
    });
  }
}