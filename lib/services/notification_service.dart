import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'apiService.dart';
import 'dart:convert';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:flutter/material.dart';
import '../screens/ENG/workout/active_workout.dart';
import '../screens/ENG/workout/workout_home.dart';
import '../screens/ENG/workout/workout_ui.dart';
import 'locale_service.dart';
import 'workout_service.dart';

final appNavigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background,
  // make sure you call Firebase.initializeApp() first.
  if (kDebugMode) {
    print('Handling a background message: ${message.messageId}');
  }
}

class NotificationService {
  NotificationService._privateConstructor();

  static final NotificationService instance =
      NotificationService._privateConstructor();

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool _localReady = false;
  int? restControlsSessionID;
  final restAction = ValueNotifier<Map<String, dynamic>?>(null);
  Map<String, dynamic>? _pendingClick;
  final Set<int> _workoutNotificationIDs = {};

  Future<bool> scheduleWorkoutRest(int sessionID, int seconds,
      {required String title,
      required String body,
      bool sound = true,
      bool vibration = true}) async {
    if (kIsWeb ||
        !_localReady ||
        !{TargetPlatform.android, TargetPlatform.iOS}
            .contains(defaultTargetPlatform)) {
      return false;
    }
    final user = await ApiService.getUserData();
    if (user == null) return false;
    final id = 100000000 + (sessionID % 100000000) * 2;
    _workoutNotificationIDs.addAll([id, id + 1]);
    try {
      await _localNotifications.cancel(id: id);
      await _localNotifications.cancel(id: id + 1);
      if (seconds <= 0) return true;
      tzdata.initializeTimeZones();
      final deadline = DateTime.now().toUtc().add(Duration(seconds: seconds));
      final payload = jsonEncode({
        'type': 'workout_rest',
        'relatedEntityID': sessionID,
        'userID': user['id']
      });
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _localNotifications.show(
            id: id,
            title: title,
            body: body,
            payload: payload,
            notificationDetails: NotificationDetails(
                android: AndroidNotificationDetails(
                    'sirvya_workout_countdown', 'Workout timers',
                    importance: Importance.low,
                    priority: Priority.low,
                    ongoing: true,
                    playSound: false,
                    enableVibration: false,
                    when: deadline.millisecondsSinceEpoch,
                    usesChronometer: true,
                    chronometerCountDown: true,
                    timeoutAfter: seconds * 1000,
                    actions: [
                  AndroidNotificationAction(
                      'pause',
                      workoutTranslate(
                          'Pause', LocaleService.instance.locale.languageCode),
                      showsUserInterface: true),
                  AndroidNotificationAction(
                      'extend',
                      workoutTranslate('+30 sec',
                          LocaleService.instance.locale.languageCode),
                      showsUserInterface: true),
                  AndroidNotificationAction(
                      'skip',
                      workoutTranslate(
                          'Skip', LocaleService.instance.locale.languageCode),
                      showsUserInterface: true)
                ])));
      }
      await _localNotifications.zonedSchedule(
          id: id + 1,
          title: title,
          body: body,
          scheduledDate: tz.TZDateTime.from(deadline, tz.UTC),
          payload: payload,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                  'sirvya_workout_alerts', 'Workout alerts',
                  importance: Importance.high,
                  priority: Priority.high,
                  playSound: sound,
                  enableVibration: vibration),
              iOS: DarwinNotificationDetails(
                  presentAlert: true, presentSound: sound)));
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Workout timer notification unavailable');
      return false;
    }
  }

  /// Get the current FCM token and save it locally & on server
  Future<String?> getFCMToken() async {
    try {
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
        print('Error getting FCM token: $e');
      }
      return null;
    }
  }

  /// Initialize notification services
  Future<void> init() async {
    if (_isInitialized) return;
    ApiService.onLogout = () async {
      _pendingClick = null;
      WorkoutService.preferences = {};
      restAction.value = null;
      if (!kIsWeb && _localReady) {
        for (final pending
            in await _localNotifications.pendingNotificationRequests()) {
          try {
            final payload = jsonDecode(pending.payload ?? '{}');
            if ('${payload['type']}'.startsWith('workout_')) {
              await _localNotifications.cancel(id: pending.id);
              if (pending.id >= 100000000 && pending.id < 300000000) {
                await _localNotifications.cancel(id: pending.id - 1);
              }
            }
          } catch (_) {}
        }
        for (final id in _workoutNotificationIDs) {
          await _localNotifications.cancel(id: id);
        }
      }
      _workoutNotificationIDs.clear();
    };

    // 1. Request Permission (iOS and Android 13+)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

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
          if (details.actionId != null && details.actionId!.isNotEmpty) {
            try {
              restAction.value = {
                ...Map<String, dynamic>.from(
                    jsonDecode(details.payload ?? '{}')),
                'action': details.actionId,
                'event': DateTime.now().microsecondsSinceEpoch
              };
            } catch (_) {}
          }
          if (details.actionId == null ||
              details.actionId!.isEmpty ||
              restControlsSessionID == null) {
            _handleNotificationClick(details.payload);
          }
        },
      );
      _localReady = true;

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

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
          payload: jsonEncode(message.data),
        );
      }
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
        print('Refreshed FCM token saved locally');
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
    try {
      _pendingClick = Map<String, dynamic>.from(jsonDecode(payload));
      openPendingWorkoutNotification();
    } catch (_) {}
  }

  Future<void> openPendingWorkoutNotification() async {
    final click = _pendingClick;
    if (click == null || !('${click['type']}'.startsWith('workout_'))) return;
    final user = await ApiService.getUserData(),
        navigator = appNavigatorKey.currentState;
    if (user == null || navigator == null) return;
    if (click['userID'] != null && '${click['userID']}' != '${user['id']}') {
      _pendingClick = null;
      return;
    }
    _pendingClick = null;
    final id = int.tryParse('${click['relatedEntityID']}');
    final role = await ApiService.getRole();
    navigator.push(WorkoutRoute(
        builder: (_) => click['type'] == 'workout_rest' && id != null
            ? ActiveWorkoutScreen(sessionID: id)
            : WorkoutHomeScreen(coach: role == 'coach')));
  }
}
