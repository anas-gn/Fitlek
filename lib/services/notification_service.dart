import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'apiService.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background,
  // make sure you call Firebase.initializeApp() first.
  if (kDebugMode) {
    print('Handling a background message: ${message.messageId}');
    print('Message data: ${message.data}');
    if (message.notification != null) {
      print('Message notification title: ${message.notification!.title}');
      print('Message notification body: ${message.notification!.body}');
    }
  }
}

class NotificationService {
  NotificationService._privateConstructor();

  static final NotificationService instance = NotificationService._privateConstructor();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Get the current FCM token and save it locally & on server
  Future<String?> getFCMToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', token);
        if (kDebugMode) {
          print('FCM Token retrieved and saved locally: $token');
        }
        
        // Try uploading to server if user is logged in
        final userToken = await ApiService.getToken();
        if (userToken != null && userToken.isNotEmpty) {
          final res = await ApiService.saveFcmTokenToServer(token);
          if (kDebugMode) {
            print('FCM Token upload status: ${res['ok']}');
          }
        }
      }
      return token;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting FCM token: $e');
      }
      return null;
    }
  }

  /// Initialize notification services
  Future<void> init() async {
    if (_isInitialized) return;

    // 1. Request Permission (iOS and Android 13+)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Request permission for local notifications (Android 13+ and iOS)
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    if (kDebugMode) {
      print('User granted notification permission: ${settings.authorizationStatus}');
    }

    // 2. Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Initialize Flutter Local Notifications for foreground notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        _handleNotificationClick(details.payload);
      },
    );

    // 4. Create high importance Android notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'sirvya_high_importance_channel', // id
      'Sirvya Notifications', // title
      description: 'This channel is used for important notifications.', // description
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 5. Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Received a foreground message: ${message.messageId}');
      }

      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      // If Android notification exists, display it using local notifications
      if (notification != null && android != null && !kIsWeb) {
        _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              importance: channel.importance,
              priority: Priority.high,
              icon: android.smallIcon ?? '@mipmap/ic_launcher',
              playSound: true,
              enableVibration: true,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: message.data.toString(),
        );
      }
    });

    // 6. Handle notification click when app is in background but open
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('A new onMessageOpenedApp event was published!');
      }
      _handleNotificationClick(message.data.toString());
    });

    // 7. Check if app was opened from a terminated state via a notification
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      if (kDebugMode) {
        print('App opened from terminated state via notification');
      }
      _handleNotificationClick(initialMessage.data.toString());
    }

    // 8. Log FCM Token for development/testing
    await getFCMToken();

    // Listen for FCM token refreshes
    _messaging.onTokenRefresh.listen((newToken) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', newToken);
      if (kDebugMode) {
        print('FCM Token Refreshed and saved locally: $newToken');
      }
      // Try uploading to server if user is logged in
      final userToken = await ApiService.getToken();
      if (userToken != null && userToken.isNotEmpty) {
        final res = await ApiService.saveFcmTokenToServer(newToken);
        if (kDebugMode) {
          print('Refreshed FCM Token upload status: ${res['ok']}');
        }
      }
    });

    _isInitialized = true;
  }

  /// Handle actions on notification click
  void _handleNotificationClick(String? payload) {
    if (payload == null) return;
    if (kDebugMode) {
      print('Notification Clicked with payload: $payload');
    }
    // TODO: Navigate to specific screen based on payload
  }
}
