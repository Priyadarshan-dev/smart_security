import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../storage/storage_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();
  final StorageService _storage = StorageService();

  Future<void> initializeNotifications() async {
    // Initialize Awesome Notifications
    await AwesomeNotifications().initialize(
      null, // default icon
      [
        NotificationChannel(
          channelKey: 'basic_channel',
          channelName: 'Basic notifications',
          channelDescription: 'Notification channel for basic tests',
          defaultColor: const Color(0xFF9D50BB),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          onlyAlertOnce: true,
          playSound: true,
          criticalAlerts: true,
        ),
      ],
      debug: true,
    );

    // Initialize Firebase Messaging
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Listen to foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Got a message whilst in the foreground!");
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        _showNotification(message);
      }
    });

    // Listen to background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Get FCM Token (for server-side integration)
    String? token = await messaging.getToken();
    print("FCM Token: $token");
  }

  Future<void> requestFullPermissions() async {
    // Request Awesome Notifications permissions
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }

    // Request Firebase Messaging permissions
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
  }

  static Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    print("Handling a background message: ${message.messageId}");
    // Check if user is logged in even in background
    final storage = StorageService();
    final token = await storage.getToken();
    if (token != null) {
      // You can trigger a notification here if needed,
      // but usually FCM shows notifications automatically in background unless data-only.
      print("User is logged in (Background), processing notification...");
    } else {
      print("User is logged out (Background), skipping notification.");
    }
  }

  Future<void> _showNotification(RemoteMessage message) async {
    // Check if user is logged in before showing notification
    final token = await _storage.getToken();
    if (token == null) {
      print("DEBUG: Notification suppressed. User is not logged in.");
      return;
    }

    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'basic_channel',
        title: message.notification?.title ?? "No Title",
        body: message.notification?.body ?? "No Body",
        payload: Map<String, String>.from(message.data),
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }
}
