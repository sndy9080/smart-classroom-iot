import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static FirebaseMessaging? _firebaseMessaging;

  static Future<void> initialize() async {
    try {
      // Initialize Firebase Messaging
      _firebaseMessaging = FirebaseMessaging.instance;
      
      // Request permissions
      await _requestPermissions();
      
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Setup Firebase messaging
      await _setupFirebaseMessaging();
      
      print('✅ Notification service initialized successfully');
    } catch (e) {
      print('❌ Error initializing notification service: $e');
    }
  }

  static Future<void> _requestPermissions() async {
    // Request notification permission for Android 13+
    await Permission.notification.request();
    
    // Request Firebase messaging permission
    if (_firebaseMessaging != null) {
      NotificationSettings settings = await _firebaseMessaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ Notification permissions granted');
      } else {
        print('⚠️ Notification permissions denied');
      }
    }
  }

  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tap
        print('Notification tapped: ${response.payload}');
      },
    );
  }

  static Future<void> _setupFirebaseMessaging() async {
    if (_firebaseMessaging == null) return;

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        _showLocalNotification(message);
      }
    });

    // Get FCM token
    String? token = await _firebaseMessaging!.getToken();
    print('FCM Token: $token');
  }

  @pragma('vm:entry-point')
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print("Handling a background message: ${message.messageId}");
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'smart_classroom_channel',
      'Smart Classroom Notifications',
      channelDescription: 'Notifications for Smart Classroom IoT events',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title ?? 'Smart Classroom',
      message.notification?.body ?? 'IoT Event Notification',
      platformChannelSpecifics,
      payload: message.data.toString(),
    );
  }

  static Future<void> showCustomNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'smart_classroom_channel',
      'Smart Classroom Notifications',
      channelDescription: 'Notifications for Smart Classroom IoT events',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }
}