import 'package:firebase_database/firebase_database.dart';

class TransactionHelper {
  static final DatabaseReference _database = FirebaseDatabase.instance.ref();

  /// Add earning transaction for mentor
  static Future<void> addEarning({
    required String mentorUid,
    required double amount,
    required String description,
    String? bookingId,
  }) async {
    try {
      int timestamp = DateTime.now().millisecondsSinceEpoch;

      // Create earning transaction
      await _database.child('transactions').child(mentorUid).push().set({
        'type': 'earning',
        'amount': amount,
        'status': 'completed',
        'description': description,
        'timestamp': timestamp,
        if (bookingId != null) 'booking_id': bookingId,
      });

      // Update mentor balance
      final balanceSnapshot = await _database
          .child('mentors')
          .child(mentorUid)
          .child('balance')
          .get();

      double currentBalance = 0;
      if (balanceSnapshot.exists) {
        currentBalance = double.tryParse(balanceSnapshot.value.toString()) ?? 0;
      }

      await _database.child('mentors').child(mentorUid).update({
        'balance': currentBalance + amount,
        'last_earning': timestamp,
      });

      print('✅ Added earning: Rp$amount for mentor $mentorUid');
    } catch (e) {
      print('❌ Error adding earning: $e');
      rethrow;
    }
  }

  /// Add withdrawal transaction for mentor
  static Future<void> addWithdrawal({
    required String mentorUid,
    required double amount,
    String description = 'Penarikan dana ke rekening',
  }) async {
    try {
      int timestamp = DateTime.now().millisecondsSinceEpoch;

      // Create withdrawal transaction
      await _database.child('transactions').child(mentorUid).push().set({
        'type': 'withdrawal',
        'amount': amount,
        'status': 'processing',
        'description': description,
        'timestamp': timestamp,
      });

      // Update mentor balance
      final balanceSnapshot = await _database
          .child('mentors')
          .child(mentorUid)
          .child('balance')
          .get();

      double currentBalance = 0;
      if (balanceSnapshot.exists) {
        currentBalance = double.tryParse(balanceSnapshot.value.toString()) ?? 0;
      }

      double newBalance = currentBalance - amount;
      if (newBalance < 0) newBalance = 0;

      await _database.child('mentors').child(mentorUid).update({
        'balance': newBalance,
        'last_withdrawal': timestamp,
      });

      print('✅ Added withdrawal: Rp$amount for mentor $mentorUid');
    } catch (e) {
      print('❌ Error adding withdrawal: $e');
      rethrow;
    }
  }

  /// Update transaction status (for admin)
  static Future<void> updateTransactionStatus({
    required String mentorUid,
    required String transactionId,
    required String status,
  }) async {
    try {
      await _database
          .child('transactions')
          .child(mentorUid)
          .child(transactionId)
          .update({
        'status': status,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });

      print('✅ Updated transaction $transactionId status to $status');
    } catch (e) {
      print('❌ Error updating transaction status: $e');
      rethrow;
    }
  }

  /// Get mentor balance
  static Future<double> getMentorBalance(String mentorUid) async {
    try {
      final snapshot = await _database
          .child('mentors')
          .child(mentorUid)
          .child('balance')
          .get();

      if (snapshot.exists) {
        return double.tryParse(snapshot.value.toString()) ?? 0;
      }
      return 0;
    } catch (e) {
      print('❌ Error getting balance: $e');
      return 0;
    }
  }

  /// Calculate total earnings for mentor
  static Future<double> getTotalEarnings(String mentorUid) async {
    try {
      final snapshot = await _database
          .child('transactions')
          .child(mentorUid)
          .orderByChild('type')
          .equalTo('earning')
          .get();

      if (!snapshot.exists) return 0;

      double total = 0;
      Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        if (value['status'] == 'completed') {
          total += double.tryParse(value['amount'].toString()) ?? 0;
        }
      });

      return total;
    } catch (e) {
      print('❌ Error calculating total earnings: $e');
      return 0;
    }
  }

  /// Calculate total withdrawals for mentor
  static Future<double> getTotalWithdrawals(String mentorUid) async {
    try {
      final snapshot = await _database
          .child('transactions')
          .child(mentorUid)
          .orderByChild('type')
          .equalTo('withdrawal')
          .get();

      if (!snapshot.exists) return 0;

      double total = 0;
      Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        if (value['status'] == 'completed') {
          total += double.tryParse(value['amount'].toString()) ?? 0;
        }
      });

      return total;
    } catch (e) {
      print('❌ Error calculating total withdrawals: $e');
      return 0;
    }
  }
}
