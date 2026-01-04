import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'notification_service.dart';

// Cache to prevent duplicate notifications
final Map<String, DateTime> _notificationCache = {};

class SessionReminderService {
  static Timer? _timer;
  static final DatabaseReference _database = FirebaseDatabase.instance.ref();
  static String? _currentUserId;
  static bool _isRunning = false;

  // Start monitoring sessions for a user
  static void startMonitoring(String userId) {
    if (_isRunning && _currentUserId == userId) {
      print('⚠️ Session reminder service already running for user: $userId');
      return;
    }

    _currentUserId = userId;
    _isRunning = true;

    print('🔔 Starting session reminder service for user: $userId');

    // Check immediately
    _checkUpcomingSessions();

    // Check every 2 minutes (optimized for performance)
    _timer = Timer.periodic(const Duration(minutes: 2), (timer) {
      _checkUpcomingSessions();
    });
  }

  // Stop monitoring
  static void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _currentUserId = null;
    print('🛑 Session reminder service stopped');
  }

  // Check upcoming sessions
  static Future<void> _checkUpcomingSessions() async {
    if (_currentUserId == null) return;

    try {
      print('🔍 Checking upcoming sessions for user: $_currentUserId');

      // Get all bookings for this pelajar
      final snapshot = await _database
          .child('bookings')
          .orderByChild('pelajar_id')
          .equalTo(_currentUserId)
          .get();

      if (!snapshot.exists) {
        print('ℹ️ No bookings found');
        return;
      }

      Map<dynamic, dynamic> bookings = snapshot.value as Map<dynamic, dynamic>;
      DateTime now = DateTime.now();

      for (var entry in bookings.entries) {
        String bookingId = entry.key;
        Map<String, dynamic> booking = Map<String, dynamic>.from(entry.value);

        // Skip if not confirmed
        if (booking['status'] != 'confirmed') continue;

        // Check if notification already sent
        bool reminded5Min = booking['reminded_5min'] ?? false;
        bool remindedStart = booking['reminded_start'] ?? false;

        // Parse booking date and time
        try {
          final dateFormat = DateFormat('dd/MM/yyyy');
          final timeFormat = DateFormat('HH:mm');

          DateTime bookingDate = dateFormat.parse(booking['tanggal']);
          DateTime bookingTime = timeFormat.parse(booking['jam_mulai']);

          DateTime sessionDateTime = DateTime(
            bookingDate.year,
            bookingDate.month,
            bookingDate.day,
            bookingTime.hour,
            bookingTime.minute,
          );

          // Calculate time difference
          Duration difference = sessionDateTime.difference(now);

          print('📅 Session: ${booking['tanggal']} ${booking['jam_mulai']}');
          print('⏱️ Time until session: ${difference.inMinutes} minutes');

          // Send 5-minute reminder (with cache check)
          String cacheKey5 = '${bookingId}_5min';
          if (!reminded5Min &&
              difference.inMinutes <= 5 &&
              difference.inMinutes > 0 &&
              !_notificationCache.containsKey(cacheKey5)) {
            print('⏰ Sending 5-minute reminder');
            _notificationCache[cacheKey5] = now;
            await NotificationService.showSessionNotification(
              title: '⏰ Sesi akan dimulai dalam ${difference.inMinutes} menit!',
              body:
                  '${booking['mentor_name']} - ${booking['tanggal']} jam ${booking['jam_mulai']}',
              payload: 'session_reminder_$bookingId',
            );

            // Mark as reminded
            await _database
                .child('bookings')
                .child(bookingId)
                .update({'reminded_5min': true});
          }

          // Send session start notification (with cache check)
          String cacheKeyStart = '${bookingId}_start';
          if (!remindedStart &&
              difference.inMinutes <= 0 &&
              difference.inMinutes > -5 &&
              !_notificationCache.containsKey(cacheKeyStart)) {
            print('🎓 Sending session start notification');
            _notificationCache[cacheKeyStart] = now;
            await NotificationService.showSessionNotification(
              title: '🎓 Sesi dimulai sekarang!',
              body:
                  '${booking['mentor_name']} - ${booking['tanggal']} jam ${booking['jam_mulai']}',
              payload: 'session_start_$bookingId',
            );

            // Mark as reminded
            await _database
                .child('bookings')
                .child(bookingId)
                .update({'reminded_start': true});
          }
        } catch (e) {
          print('❌ Error parsing booking date/time: $e');
        }
      }
    } catch (e) {
      // Check if it's a permission error
      if (e.toString().contains('permission-denied')) {
        print('⚠️ Permission denied for bookings. Stopping reminder service.');
        // Stop the service to prevent repeated errors
        stopMonitoring();
      } else {
        print('❌ Error checking upcoming sessions: $e');
      }
    }
  }

  // Manual check (for testing)
  static Future<void> checkNow() async {
    await _checkUpcomingSessions();
  }
}
