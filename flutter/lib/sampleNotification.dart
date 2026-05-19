import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class LocalNotificationTestPage extends StatefulWidget {
  const LocalNotificationTestPage({super.key});

  @override
  State<LocalNotificationTestPage> createState() =>
      _LocalNotificationTestPageState();
}

class _LocalNotificationTestPageState
    extends State<LocalNotificationTestPage> {
  final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    // 🔐 Android 13+ permission
    await Permission.notification.request();

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
    InitializationSettings(android: androidSettings);

    await _notifications.initialize(settings);
  }

  Future<void> _showNotification() async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Local notification testing',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails details =
    NotificationDetails(android: androidDetails);

    await _notifications.show(
      0,
      '🚨 Local Notification Test',
      'This is a local push notification',
      details,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Notification Test'),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(
              horizontal: 40,
              vertical: 15,
            ),
          ),
          onPressed: _showNotification,
          child: const Text(
            'SHOW NOTIFICATION',
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
