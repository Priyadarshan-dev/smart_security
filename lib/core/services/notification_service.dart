import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../storage/storage_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;
  NotificationService._internal();

  final StorageService _storage = StorageService();

  bool _initialized = false; // ✅ prevents multiple listeners
  String? _lastMessageId; // ✅ prevents duplicate delivery

  Future<void> initializeNotifications() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    await AwesomeNotifications().initialize(null, [
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
    ], debug: true);

    final messaging = FirebaseMessaging.instance;

    /// prevent Firebase auto UI
    await messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      /// ✅ prevent duplicate delivery of same push
      if (_lastMessageId == message.messageId) {
        return;
      }
      _lastMessageId = message.messageId;

      _showNotification(message);
    });
  }

  Future<void> requestFullPermissions() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _showNotification(RemoteMessage message) async {
    final token = await _storage.getToken();

    if (token == null) {
      return;
    }

    final title =
        message.notification?.title ?? message.data['title'] ?? "No Title";

    final body =
        message.notification?.body ?? message.data['body'] ?? "No Body";

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'basic_channel',
        title: title,
        body: body,
        payload: Map<String, String>.from(message.data),
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }
}
