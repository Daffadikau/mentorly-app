import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io' show Platform;

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  static final DatabaseReference _database = FirebaseDatabase.instance.ref();
  
  static String? _fcmToken;
  static BuildContext? _context;

  // Initialize notification service
  static Future<void> initialize(BuildContext context) async {
    try {
      _context = context;
      
      // Request permission
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ Notification permission granted');
        
        // For iOS, get APNS token first
        if (Platform.isIOS) {
          String? apnsToken = await _firebaseMessaging.getAPNSToken();
          if (apnsToken != null) {
            print('📱 APNS Token: $apnsToken');
          } else {
            print('⚠️ APNS token not available yet, will retry...');
            // Wait a bit and try again
            await Future.delayed(const Duration(seconds: 2));
            apnsToken = await _firebaseMessaging.getAPNSToken();
            if (apnsToken != null) {
              print('📱 APNS Token (retry): $apnsToken');
            }
          }
        }
        
        // Get FCM token
        try {
          _fcmToken = await _firebaseMessaging.getToken();
          print('📱 FCM Token: $_fcmToken');
        } catch (e) {
          print('⚠️ Error getting FCM token: $e');
          // Continue without FCM token
        }
        
        // Initialize local notifications
        await _initializeLocalNotifications();
        
        // Setup message handlers
        _setupMessageHandlers();
        
      } else {
        print('❌ Notification permission denied');
      }
    } catch (e) {
      print('❌ Error initializing notifications: $e');
      // Continue app execution even if notifications fail
    }
  }

  // Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings = 
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels
    const AndroidNotificationChannel chatChannel = AndroidNotificationChannel(
      'chat_channel',
      'Chat Notifications',
      description: 'Notifications for new chat messages',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    const AndroidNotificationChannel callChannel = AndroidNotificationChannel(
      'call_channel',
      'Call Notifications',
      description: 'Notifications for incoming calls',
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
    );

    const AndroidNotificationChannel bookingChannel = AndroidNotificationChannel(
      'booking_channel',
      'Booking Notifications',
      description: 'Notifications for new bookings',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(chatChannel);
    
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(callChannel);
    
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(bookingChannel);

    // Create session reminder channel
    const AndroidNotificationChannel sessionChannel = AndroidNotificationChannel(
      'session_channel',
      'Session Reminders',
      description: 'Notifications for upcoming sessions',
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(sessionChannel);
  }

  // Setup message handlers
  static void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 Foreground message: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // Handle background messages (app in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📲 Background message opened: ${message.data}');
      _handleNotificationTap(message.data);
    });

    // Handle message when app is opened from terminated state
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('🚀 App opened from terminated state: ${message.data}');
        _handleNotificationTap(message.data);
      }
    });
  }

  // Show local notification
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    String channelId = 'chat_channel';
    if (message.data['type'] == 'call') {
      channelId = 'call_channel';
    } else if (message.data['type'] == 'booking') {
      channelId = 'booking_channel';
    }

    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelId == 'chat_channel' ? 'Chat Notifications' : 
      channelId == 'call_channel' ? 'Call Notifications' : 'Booking Notifications',
      channelDescription: message.notification?.body ?? '',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'New Notification',
      message.notification?.body ?? '',
      notificationDetails,
      payload: message.data.toString(),
    );
  }

  // Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    print('🔔 Notification tapped: ${response.payload}');
    // Parse payload and navigate accordingly
    if (response.payload != null) {
      // You can parse the payload and navigate to specific screen
      // For now, just print it
      print('Payload: ${response.payload}');
    }
  }

  // Handle notification tap with data
  static void _handleNotificationTap(Map<String, dynamic> data) {
    String type = data['type'] ?? '';
    
    if (_context == null) return;

    if (type == 'chat') {
      // Navigate to chat screen
      print('Navigate to chat: ${data['room_id']}');
      // TODO: Navigate to chat room
    } else if (type == 'call') {
      // Navigate to incoming call screen
      print('Navigate to call: ${data['room_id']}');
      // TODO: Show incoming call dialog
    } else if (type == 'booking') {
      // Navigate to booking details
      print('Navigate to booking: ${data['booking_id']}');
      // TODO: Navigate to booking details
    }
  }

  // Save FCM token to database
  static Future<void> saveFCMToken(String userId, String userType) async {
    if (_fcmToken == null) return;

    try {
      await _database
          .child('fcm_tokens')
          .child(userId)
          .set({
        'token': _fcmToken,
        'user_type': userType,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });
      print('✅ FCM token saved for user: $userId');
    } catch (e) {
      print('❌ Error saving FCM token: $e');
    }
  }

  // Send notification to user
  static Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get user's FCM token
      final snapshot = await _database.child('fcm_tokens').child(userId).get();
      
      if (!snapshot.exists) {
        print('⚠️ No FCM token found for user: $userId');
        return;
      }

      Map<String, dynamic> tokenData = Map<String, dynamic>.from(
        snapshot.value as Map<dynamic, dynamic>
      );
      String token = tokenData['token'] ?? '';

      if (token.isEmpty) return;

      // Create notification payload
      Map<String, dynamic> notificationData = {
        'title': title,
        'body': body,
        'type': type,
        ...?data,
      };

      // Save to database for triggering Cloud Function (if you have one)
      await _database.child('notifications').push().set({
        'to': token,
        'notification': {
          'title': title,
          'body': body,
        },
        'data': notificationData,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });

      print('✅ Notification sent to user: $userId');
    } catch (e) {
      print('❌ Error sending notification: $e');
    }
  }

  // Send chat notification
  static Future<void> sendChatNotification({
    required String recipientId,
    required String senderName,
    required String message,
    required String roomId,
  }) async {
    await sendNotificationToUser(
      userId: recipientId,
      title: 'Pesan baru dari $senderName',
      body: message.length > 50 ? '${message.substring(0, 50)}...' : message,
      type: 'chat',
      data: {
        'room_id': roomId,
        'sender_name': senderName,
      },
    );
  }

  // Send call notification
  static Future<void> sendCallNotification({
    required String recipientId,
    required String callerName,
    required bool isVideo,
    required String roomId,
    required String channelId,
  }) async {
    await sendNotificationToUser(
      userId: recipientId,
      title: isVideo ? '📹 Video Call dari $callerName' : '📞 Voice Call dari $callerName',
      body: 'Ketuk untuk menjawab',
      type: 'call',
      data: {
        'room_id': roomId,
        'caller_name': callerName,
        'is_video': isVideo.toString(),
        'channel_id': channelId,
      },
    );
  }

  // Send booking notification
  static Future<void> sendBookingNotification({
    required String mentorId,
    required String pelajarName,
    required String subject,
    required String date,
    required String time,
  }) async {
    await sendNotificationToUser(
      userId: mentorId,
      title: '📚 Booking Baru dari $pelajarName',
      body: '$subject - $date, $time',
      type: 'booking',
      data: {
        'pelajar_name': pelajarName,
        'subject': subject,
        'date': date,
        'time': time,
      },
    );
  }

  // Get FCM token
  static String? get fcmToken => _fcmToken;

  // Schedule session reminder notifications
  static Future<void> scheduleSessionReminders({
    required String bookingId,
    required String tanggal,
    required String jamMulai,
    required String mentorName,
    required String subject,
  }) async {
    try {
      // Parse date and time
      final dateFormat = DateFormat('dd/MM/yyyy');
      final timeFormat = DateFormat('HH:mm');
      
      DateTime sessionDate = dateFormat.parse(tanggal);
      DateTime sessionTime = timeFormat.parse(jamMulai);
      
      // Combine date and time
      DateTime sessionDateTime = DateTime(
        sessionDate.year,
        sessionDate.month,
        sessionDate.day,
        sessionTime.hour,
        sessionTime.minute,
      );

      // Calculate notification times
      DateTime fiveMinutesBefore = sessionDateTime.subtract(const Duration(minutes: 5));
      DateTime sessionStart = sessionDateTime;

      // Get current time
      DateTime now = DateTime.now();

      print('📅 Session scheduled for: $sessionDateTime');
      print('⏰ 5 minutes reminder: $fiveMinutesBefore');

      // Schedule 5 minutes before notification
      if (fiveMinutesBefore.isAfter(now)) {
        await _scheduleNotification(
          id: bookingId.hashCode,
          title: '⏰ Sesi akan dimulai dalam 5 menit!',
          body: '$subject dengan $mentorName - Jam ${jamMulai}',
          scheduledTime: fiveMinutesBefore,
          payload: 'session_reminder_5min_$bookingId',
        );
        print('✅ 5-minute reminder scheduled');
      }

      // Schedule session start notification
      if (sessionStart.isAfter(now)) {
        await _scheduleNotification(
          id: (bookingId.hashCode + 1),
          title: '🎓 Sesi dimulai sekarang!',
          body: '$subject dengan $mentorName',
          scheduledTime: sessionStart,
          payload: 'session_start_$bookingId',
        );
        print('✅ Session start notification scheduled');
      }

    } catch (e) {
      print('❌ Error scheduling session reminders: $e');
    }
  }

  // Schedule a notification
  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'session_channel',
      'Session Reminders',
      channelDescription: 'Notifications for upcoming sessions',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
      fullScreenIntent: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // For immediate or past notifications, show them now
    if (scheduledTime.isBefore(DateTime.now()) || 
        scheduledTime.difference(DateTime.now()).inSeconds < 5) {
      await _localNotifications.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } else {
      // Note: flutter_local_notifications doesn't support scheduled notifications on iOS
      // For production, consider using timezone package or a background task
      // For now, we'll show immediate notification with schedule info
      await _localNotifications.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    }
  }

  // Show immediate session notification
  static Future<void> showSessionNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'session_channel',
      'Session Reminders',
      channelDescription: 'Notifications for upcoming sessions',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
      fullScreenIntent: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }
}
