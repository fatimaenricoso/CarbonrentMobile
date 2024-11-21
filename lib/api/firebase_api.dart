import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotification() async {
    await _firebaseMessaging.requestPermission();
    String? token = await _firebaseMessaging.getToken();
    print('Token: $token');

    await _firebaseMessaging.subscribeToTopic('announcements');

    initPushNotifications();
  }

  void handleMessage(RemoteMessage? message, dynamic navigatorKey) {
    if (message == null) return;

    navigatorKey.currentState?.pushNamed(
      '/announcement_screen',
      arguments: message,
    );
  }

  Future initPushNotifications() async {
    FirebaseMessaging.instance
        .getInitialMessage()
        .then(handleMessage as FutureOr Function(RemoteMessage? value));
    FirebaseMessaging.onMessageOpenedApp
        .listen(handleMessage as void Function(RemoteMessage event)?);
  }
}
