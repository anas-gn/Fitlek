import 'campaign_service.dart';
import 'socketService.dart';
import 'notification_delivery_gate.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'apiService.dart';
import 'dart:convert';
import 'dart:async';
import '../globals.dart';
import 'notification_navigation.dart';

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

  static final NotificationService instance =
      NotificationService._privateConstructor();

  late final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool _navigationReady = false;
  String? _pendingPayload;
  final _deliveryGate = NotificationDeliveryGate();
  late final _sound = AudioPlayer();
  Timer? _apnsRetry;
  int _apnsAttempts = 0;

  void resetSession() {
    _navigationReady = false;
    _pendingPayload = null;
    _deliveryGate.clear();
    _apnsRetry?.cancel();
    _apnsAttempts = 0;
  }

  void navigationReady() {
    _navigationReady = true;
    SocketService().connect();
    getFCMToken();
    final payload = _pendingPayload;
    _pendingPayload = null;
    if (payload != null) _handleNotificationClick(payload);
  }

  /// Get the current FCM token and save it locally & on server
  Future<String?> getFCMToken() async {
    try {
      if (!kIsWeb &&
          defaultTargetPlatform == TargetPlatform.iOS &&
          await _messaging.getAPNSToken() == null) {
        if (_apnsAttempts++ < 10 && _apnsRetry?.isActive != true) {
          _apnsRetry = Timer(const Duration(seconds: 3), () => getFCMToken());
        }
        return null;
      }
      _apnsRetry?.cancel();
      _apnsAttempts = 0;
      final token = await _messaging.getToken();
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', token);
        if (kDebugMode) {
          print('FCM token saved locally');
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
        if (e.toString().contains('permission-blocked')) {
          print(
              ' FCM Token ignored: Notification permission was blocked by the browser.');
        } else {
          print('Error getting FCM token: $e');
        }
      }
      return null;
    }
  }

  /// Initialize notification services
  Future<void> init() async {
    if (_isInitialized) return;
    if (kIsWeb) _pendingPayload = Uri.base.queryParameters['notification'];

    // 1. Request Permission (iOS and Android 13+)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    await _messaging.setForegroundNotificationPresentationOptions(
        alert: false, badge: false, sound: false);

    // Request permission for local notifications (Android 13+ and iOS)
    if (!kIsWeb) {
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
    }

    if (kDebugMode) {
      print(
          'User granted notification permission: ${settings.authorizationStatus}');
    }

    // 4. Create high importance Android notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'sirvya_high_importance_channel', // id
      'Sirvya Notifications', // title
      description:
          'This channel is used for important notifications.', // description
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    if (!kIsWeb) {
      // 2. Set up background message handler
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // 3. Initialize Flutter Local Notifications for foreground notifications
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await _localNotifications.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          _handleNotificationClick(details.payload);
        },
      );
      final launch =
          await _localNotifications.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp == true) {
        _handleNotificationClick(launch?.notificationResponse?.payload);
      }

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    // One presenter for socket and Firebase delivery; the notification ID deduplicates both.
    SocketService().notifications.listen(presentIncoming);
    FirebaseMessaging.onMessage.listen((message) {
      presentIncoming({
        ...message.data,
        'title': message.notification?.title ?? message.data['title'],
        'body': message.notification?.body ?? message.data['body'],
        'messageID': message.messageId
      });
    });

    // 6. Handle notification click when app is in background but open
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('A new onMessageOpenedApp event was published!');
      }
      _handleNotificationClick(jsonEncode(message.data));
    });

    // 7. Check if app was opened from a terminated state via a notification
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      if (kDebugMode) {
        print('App opened from terminated state via notification');
      }
      _handleNotificationClick(jsonEncode(initialMessage.data));
    }

    // 8. Log FCM Token for development/testing
    await getFCMToken();

    // Listen for FCM token refreshes
    _messaging.onTokenRefresh.listen((newToken) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', newToken);
      if (kDebugMode) {
        print('FCM token refreshed');
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

  Future<void> presentIncoming(Map<String, dynamic> item) async {
    if (!_navigationReady ||
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed)
      return;
    final user = await ApiService.getUserData();
    if (user == null ||
        (item['recipientUserID'] != null &&
            '${item['recipientUserID']}' != '${user['id']}')) return;
    final id = '${item['notificationID'] ?? item['messageID'] ?? ''}';
    if (!_deliveryGate.accept(item)) return;
    SocketService().invalidate('notifications');
    if (item['type'] == 'new_message') SocketService().invalidate('messages');
    if (item['type'] == 'app_campaign') CampaignService.check();
    if (item['silent'] == true) return;
    final title = '${item['title'] ?? 'Sirvya'}';
    final body = '${item['body'] ?? ''}';
    if (kIsWeb) {
      // Browsers may require an earlier user gesture before allowing audio.
      try {
        await _sound.play(AssetSource('sounds/notification.wav'));
      } catch (_) {}
      final context = globalNavigatorKey.currentContext;
      if (context != null && context.mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
            content: Text('$title: $body'),
            action: SnackBarAction(
                label: 'Open',
                onPressed: () => _handleNotificationClick(jsonEncode(item)))));
      }
      return;
    }
    await _localNotifications.show(
        id: int.tryParse(id) ??
            DateTime.now().millisecondsSinceEpoch.remainder(2147483647),
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
                'sirvya_high_importance_channel', 'Sirvya Notifications',
                channelDescription:
                    'This channel is used for important notifications.',
                importance: Importance.max,
                priority: Priority.high,
                playSound: true,
                enableVibration: true,
                icon: '@mipmap/ic_launcher'),
            iOS: DarwinNotificationDetails(
                presentAlert: true, presentBadge: true, presentSound: true)),
        payload: jsonEncode(item));
  }

  /// Handle actions on notification click
  Future<void> _handleNotificationClick(String? payload) async {
    if (payload == null) return;
    final context = globalNavigatorKey.currentContext;
    if (!_navigationReady ||
        context == null ||
        await ApiService.getToken() == null) {
      _pendingPayload = payload;
      return;
    }
    try {
      final item = Map<String, dynamic>.from(jsonDecode(payload));
      final user = await ApiService.getUserData();
      if (user == null ||
          (item['recipientUserID'] != null &&
              '${item['recipientUserID']}' != '${user['id']}')) return;
      if (item['notificationID'] != null) {
        await ApiService.patch(
            '/reservations/notifications/${item['notificationID']}/read');
      }
      if (context.mounted) await NotificationNavigation.open(context, item);
    } catch (error) {
      debugPrint('Unable to open notification: $error');
    }
  }
}
