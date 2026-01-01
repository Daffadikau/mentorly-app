import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ClearBookingsUtility extends StatelessWidget {
  const ClearBookingsUtility({super.key});

  Future<void> _clearAllBookings() async {
    try {
      print('🗑️ Clearing all bookings...');

      // Delete all bookings
      await FirebaseDatabase.instance.ref('bookings').remove();
      print('✅ Bookings deleted');

      // Delete all chat rooms
      await FirebaseDatabase.instance.ref('chat_rooms').remove();
      print('✅ Chat rooms deleted');

      // Delete all messages
      await FirebaseDatabase.instance.ref('messages').remove();
      print('✅ Messages deleted');

      // Reset jadwal status to available
      final jadwalSnapshot =
          await FirebaseDatabase.instance.ref('jadwal').get();
      if (jadwalSnapshot.exists) {
        Map<dynamic, dynamic> mentors =
            jadwalSnapshot.value as Map<dynamic, dynamic>;
        for (var mentorEntry in mentors.entries) {
          String mentorId = mentorEntry.key;
          if (mentorEntry.value is Map) {
            Map<dynamic, dynamic> jadwalList =
                mentorEntry.value as Map<dynamic, dynamic>;
            for (var jadwalEntry in jadwalList.entries) {
              String jadwalId = jadwalEntry.key;
              await FirebaseDatabase.instance
                  .ref('jadwal')
                  .child(mentorId)
                  .child(jadwalId)
                  .update({'status': 'available'});
            }
          }
        }
        print('✅ All jadwal reset to available');
      }

      print('✅ All booking data cleared!');
    } catch (e) {
      print('❌ Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Clear Bookings', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red[700],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.delete_forever, size: 80, color: Colors.red),
              const SizedBox(height: 20),
              const Text(
                'Clear All Bookings',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'This will delete:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              const Text('• All bookings'),
              const Text('• All chat rooms'),
              const Text('• All messages'),
              const Text('• Reset jadwal to available'),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirm'),
                      content: const Text('Delete all booking data?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Delete',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );

                    await _clearAllBookings();

                    Navigator.pop(context); // Close loading

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All booking data cleared!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: const Text(
                  'Clear All Data',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
