import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class KelolaBookingMentor extends StatefulWidget {
  final Map<String, dynamic> mentorData;

  const KelolaBookingMentor({super.key, required this.mentorData});

  @override
  _KelolaBookingMentorState createState() => _KelolaBookingMentorState();
}

class _KelolaBookingMentorState extends State<KelolaBookingMentor> {
  List<Map<String, dynamic>> pendingBookings = [];
  List<Map<String, dynamic>> acceptedBookings = [];
  bool isLoading = true;
  String selectedTab = 'pending'; // 'pending' or 'accepted'

  @override
  void initState() {
    super.initState();
    loadBookings();
  }

  Future<void> loadBookings() async {
    setState(() {
      isLoading = true;
    });

    try {
      final mentorUid = widget.mentorData['mentor_id'] ?? widget.mentorData['id'];
      final jadwalRef = FirebaseDatabase.instance.ref('jadwal/$mentorUid');
      final snapshot = await jadwalRef.get();

      List<Map<String, dynamic>> pending = [];
      List<Map<String, dynamic>> accepted = [];

      if (snapshot.exists) {
        Map<dynamic, dynamic> jadwalMap = snapshot.value as Map<dynamic, dynamic>;

        for (var entry in jadwalMap.entries) {
          Map<String, dynamic> jadwal = Map<String, dynamic>.from(entry.value as Map);
          jadwal['id'] = entry.key;

          String status = jadwal['status'] ?? '';
          String bookedBy = jadwal['booked_by'] ?? '';

          if (status == 'booked' && bookedBy.isNotEmpty) {
            // Load pelajar data
            final pelajarSnapshot = await FirebaseDatabase.instance
                .ref('pelajar/$bookedBy')
                .get();

            if (pelajarSnapshot.exists) {
              Map<String, dynamic> pelajarData =
                  Map<String, dynamic>.from(pelajarSnapshot.value as Map);
              jadwal['pelajar_name'] = pelajarData['nama_lengkap'] ?? 'Pelajar';
              jadwal['pelajar_photo'] = pelajarData['profile_photo_url'] ?? '';
            }

            // Check if already accepted
            bool isAccepted = jadwal['booking_accepted'] == true;
            
            if (isAccepted) {
              accepted.add(jadwal);
            } else {
              pending.add(jadwal);
            }
          }
        }
      }

      // Sort by date
      pending.sort((a, b) {
        String dateA = a['tanggal'] ?? '';
        String dateB = b['tanggal'] ?? '';
        return dateA.compareTo(dateB);
      });

      accepted.sort((a, b) {
        String dateA = a['tanggal'] ?? '';
        String dateB = b['tanggal'] ?? '';
        return dateA.compareTo(dateB);
      });

      setState(() {
        pendingBookings = pending;
        acceptedBookings = accepted;
        isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading bookings: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> acceptBooking(Map<String, dynamic> jadwal) async {
    try {
      final mentorUid = widget.mentorData['mentor_id'] ?? widget.mentorData['id'];
      final jadwalId = jadwal['id'];
      final bookedBy = jadwal['booked_by'];

      // Update jadwal status
      await FirebaseDatabase.instance
          .ref('jadwal/$mentorUid/$jadwalId')
          .update({'booking_accepted': true});

      // Send notification to pelajar
      await _sendNotification(
        bookedBy,
        'Booking Diterima',
        'Mentor ${widget.mentorData['nama_lengkap']} telah menerima booking Anda untuk ${jadwal['mata_pelajaran']}',
        'booking_accepted',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking berhasil diterima'),
          backgroundColor: Colors.green,
        ),
      );

      loadBookings();
    } catch (e) {
      print('❌ Error accepting booking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menerima booking: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> cancelBooking(Map<String, dynamic> jadwal) async {
    try {
      final mentorUid = widget.mentorData['mentor_id'] ?? widget.mentorData['id'];
      final jadwalId = jadwal['id'];
      final bookedBy = jadwal['booked_by'];

      // Update jadwal back to available
      await FirebaseDatabase.instance
          .ref('jadwal/$mentorUid/$jadwalId')
          .update({
        'status': 'available',
        'booked_by': '',
        'booking_accepted': false,
      });

      // Send notification to pelajar
      await _sendNotification(
        bookedBy,
        'Booking Dibatalkan',
        'Mentor ${widget.mentorData['nama_lengkap']} telah membatalkan booking Anda untuk ${jadwal['mata_pelajaran']}',
        'booking_cancelled',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking berhasil dibatalkan'),
          backgroundColor: Colors.orange,
        ),
      );

      loadBookings();
    } catch (e) {
      print('❌ Error cancelling booking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membatalkan booking: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendNotification(
    String userId,
    String title,
    String body,
    String type,
  ) async {
    try {
      // Get user's FCM token
      final userSnapshot =
          await FirebaseDatabase.instance.ref('pelajar/$userId').get();

      if (userSnapshot.exists) {
        Map<String, dynamic> userData =
            Map<String, dynamic>.from(userSnapshot.value as Map);
        String? fcmToken = userData['fcm_token'];

        if (fcmToken != null && fcmToken.isNotEmpty) {
          // Save notification to database
          await FirebaseDatabase.instance.ref('notifications').push().set({
            'user_id': userId,
            'title': title,
            'body': body,
            'type': type,
            'created_at': DateTime.now().toIso8601String(),
            'read': false,
          });

          print('✅ Notification saved for user: $userId');
        }
      }
    } catch (e) {
      print('❌ Error sending notification: $e');
    }
  }

  DateTime? _parseDateFlexible(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;

    try {
      // Try ISO format first (yyyy-MM-dd)
      return DateTime.parse(dateStr);
    } catch (e) {
      try {
        // Try Indonesian format (Senin, 08 Januari 2026)
        final indonesianFormat = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');
        return indonesianFormat.parse(dateStr);
      } catch (e2) {
        print('❌ Could not parse date: $dateStr');
        return null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        elevation: 0,
        title: const Text(
          'Kelola Booking',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Tab selector
          Container(
            color: Colors.blue[700],
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => selectedTab = 'pending'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: selectedTab == 'pending'
                                ? Colors.white
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        'Menunggu (${pendingBookings.length})',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: selectedTab == 'pending'
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => selectedTab = 'accepted'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: selectedTab == 'accepted'
                                ? Colors.white
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        'Diterima (${acceptedBookings.length})',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: selectedTab == 'accepted'
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: loadBookings,
                    child: selectedTab == 'pending'
                        ? _buildPendingList()
                        : _buildAcceptedList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingList() {
    if (pendingBookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Tidak ada booking menunggu',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pendingBookings.length,
      itemBuilder: (context, index) {
        return _buildBookingCard(pendingBookings[index], isPending: true);
      },
    );
  }

  Widget _buildAcceptedList() {
    if (acceptedBookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Belum ada booking diterima',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: acceptedBookings.length,
      itemBuilder: (context, index) {
        return _buildBookingCard(acceptedBookings[index], isPending: false);
      },
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> jadwal,
      {required bool isPending}) {
    final tanggalStr = jadwal['tanggal'] ?? '';
    final displayDate = jadwal['display_date'] ?? tanggalStr;
    final pelajarName = jadwal['pelajar_name'] ?? 'Pelajar';
    final pelajarPhoto = jadwal['pelajar_photo'] ?? '';
    final mataPelajaran = jadwal['mata_pelajaran'] ?? 'Mata Pelajaran';
    final jamMulai = jadwal['jam_mulai'] ?? '';
    final jamSelesai = jadwal['jam_selesai'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.blue[100],
                  backgroundImage:
                      pelajarPhoto.isNotEmpty ? NetworkImage(pelajarPhoto) : null,
                  child: pelajarPhoto.isEmpty
                      ? const Icon(Icons.person, color: Colors.blue)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pelajarName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mataPelajaran,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    displayDate.isNotEmpty ? displayDate : 'Tanggal belum ditentukan',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  '$jamMulai - $jamSelesai',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isPending)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showCancelDialog(jadwal),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Tolak'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => acceptBooking(jadwal),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Terima'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Booking Diterima',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => _showCancelDialog(jadwal),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Batalkan'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(Map<String, dynamic> jadwal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Booking?'),
        content: Text(
          'Apakah Anda yakin ingin membatalkan booking dari ${jadwal['pelajar_name']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              cancelBooking(jadwal);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
  }
}
