import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class FirebaseMessage {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotification() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
 
      final token = await _firebaseMessaging.getToken();
      debugPrint('📱 FCM Token: $token');

      FirebaseMessaging.instance.getInitialMessage().then(handleNotification);

      FirebaseMessaging.onMessageOpenedApp.listen(handleNotification);

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Foreground notification received');
        debugPrint('Title: ${message.notification?.title}');
        debugPrint('Body: ${message.notification?.body}');
      });
    } else {
      debugPrint('Notification permission not granted');
    }
  }

  void handleNotification(RemoteMessage? message) {
    if (message == null) return;

    debugPrint('Notification opened:');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
  }
}
