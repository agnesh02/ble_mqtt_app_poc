import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class NotificationHelper {
  NotificationHelper._();

  static final _instance = NotificationHelper._();

  factory NotificationHelper() {
    return _instance;
  }

  void initAwesomeNotifications() {
    AwesomeNotifications().initialize(
      'resource://drawable/notification_icon',
      [
        NotificationChannel(
          channelKey: 'basic_channel',
          channelName: 'Basic Notifications',
          channelDescription: "basic",
          defaultColor: Colors.teal,
          importance: NotificationImportance.High,
          channelShowBadge: true,
        ),
      ],
    );
  }

  void requestPermission() {
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  Future<void> createNewNotification({
    required String title,
    required String message,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: createUniqueId(),
        channelKey: 'basic_channel',
        title: title,
        body: message,
        notificationLayout: NotificationLayout.BigText,
      ),
    );
  }

  int createUniqueId() {
    return DateTime.now().millisecondsSinceEpoch.remainder(100000);
  }
}
