import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Manual utility to verify a mentor in Firebase Realtime Database
///
/// Use this when you need to manually verify a mentor account
/// This is useful for debugging or when syncing from PHP backend manually
class ManualVerifyMentor {
  /// Verify a mentor by UID
  ///
  /// Example usage:
  /// ```dart
  /// await ManualVerifyMentor.verifyMentorByUid('mentor-uid-here');
  /// ```
  static Future<void> verifyMentorByUid(String uid) async {
    try {
      final ref = FirebaseDatabase.instance.ref('mentor').child(uid);
      final snapshot = await ref.get();

      if (!snapshot.exists) {
        print('❌ Mentor with UID $uid not found in Firebase RTDB');
        return;
      }

      await ref.update({
        'status_verifikasi': 'verified',
        'verified_at': DateTime.now().toIso8601String(),
      });

      print('✅ Mentor $uid has been verified successfully');
    } catch (e) {
      print('❌ Error verifying mentor: $e');
    }
  }

  /// Verify a mentor by email
  ///
  /// Example usage:
  /// ```dart
  /// await ManualVerifyMentor.verifyMentorByEmail('mentor@example.com');
  /// ```
  static Future<void> verifyMentorByEmail(String email) async {
    try {
      final ref = FirebaseDatabase.instance.ref('mentor');
      final snapshot = await ref.get();

      if (!snapshot.exists) {
        print('❌ No mentors found in Firebase RTDB');
        return;
      }

      final mentors = Map<String, dynamic>.from(snapshot.value as Map);
      String? foundUid;

      // Find mentor by email
      mentors.forEach((uid, data) {
        final mentorData = Map<String, dynamic>.from(data);
        if (mentorData['email']?.toString().toLowerCase() ==
            email.toLowerCase()) {
          foundUid = uid;
        }
      });

      if (foundUid == null) {
        print('❌ Mentor with email $email not found');
        return;
      }

      await ref.child(foundUid!).update({
        'status_verifikasi': 'verified',
        'verified_at': DateTime.now().toIso8601String(),
      });

      print('✅ Mentor $email (UID: $foundUid) has been verified');
    } catch (e) {
      print('❌ Error verifying mentor: $e');
    }
  }

  /// List all mentors and their verification status
  static Future<void> listAllMentors() async {
    try {
      final ref = FirebaseDatabase.instance.ref('mentor');
      final snapshot = await ref.get();

      if (!snapshot.exists) {
        print('❌ No mentors found in Firebase RTDB');
        return;
      }

      final mentors = Map<String, dynamic>.from(snapshot.value as Map);

      print('\n📋 All Mentors in Firebase RTDB:\n');
      print('─' * 80);

      mentors.forEach((uid, data) {
        final mentorData = Map<String, dynamic>.from(data);
        final email = mentorData['email'] ?? 'No email';
        final name = mentorData['nama_lengkap'] ?? 'No name';
        final status = mentorData['status_verifikasi'] ?? 'unknown';
        final statusIcon = status == 'verified' ? '✅' : '⏳';

        print('$statusIcon UID: $uid');
        print('   Email: $email');
        print('   Name: $name');
        print('   Status: $status');
        print('─' * 80);
      });
    } catch (e) {
      print('❌ Error listing mentors: $e');
    }
  }

  /// Verify currently logged in mentor (if any)
  static Future<void> verifyCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print('❌ No user is currently logged in');
      return;
    }

    print('🔍 Current user: ${user.email} (UID: ${user.uid})');
    await verifyMentorByUid(user.uid);
  }
}
