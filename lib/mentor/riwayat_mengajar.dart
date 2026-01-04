import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import '../widgets/cached_circle_avatar.dart';

class RiwayatMengajar extends StatefulWidget {
  final Map<String, dynamic> mentorData;

  const RiwayatMengajar({super.key, required this.mentorData});

  @override
  State<RiwayatMengajar> createState() => _RiwayatMengajarState();
}

class _RiwayatMengajarState extends State<RiwayatMengajar> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> riwayatList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadRiwayat();
  }

  Future<void> loadRiwayat() async {
    setState(() {
      isLoading = true;
    });

    try {
      final mentorId =
          widget.mentorData['uid'] ?? widget.mentorData['id'].toString();
      print('🔍 Loading riwayat for mentor: $mentorId');

      // Get all bookings for this mentor
      final snapshot = await _database
          .child('bookings')
          .orderByChild('mentor_id')
          .equalTo(mentorId)
          .get();

      List<Map<String, dynamic>> tempList = [];

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        DateTime now = DateTime.now();

        for (var entry in data.entries) {
          final booking = Map<String, dynamic>.from(entry.value as Map);
          booking['id'] = entry.key;

          try {
            // Parse booking date and time
            DateTime bookingDate = DateTime.parse(booking['tanggal']);
            List<String> timeParts =
                booking['jam_selesai'].toString().split(':');
            DateTime sessionEndTime = DateTime(
              bookingDate.year,
              bookingDate.month,
              bookingDate.day,
              int.parse(timeParts[0]),
              int.parse(timeParts[1]),
            );

            // Show completed or past sessions
            bool shouldShow = false;

            if (booking['status'] == 'completed') {
              shouldShow = true;
            } else if (booking['status'] == 'confirmed' &&
                sessionEndTime.isBefore(now)) {
              // Auto-update past confirmed sessions to completed
              await _database
                  .child('bookings')
                  .child(entry.key)
                  .update({'status': 'completed'});
              booking['status'] = 'completed';
              shouldShow = true;
            }

            if (shouldShow) {
              tempList.add(booking);
              print(
                  '✅ Added to riwayat: ${booking['pelajar_name']} - ${booking['tanggal']} (${booking['status']})');
              print('   📋 Booking data keys: ${booking.keys.toList()}');
              print('   👤 pelajar_id: ${booking['pelajar_id']}');
            }
          } catch (e) {
            print("❌ Error parsing booking date: $e");
          }
        }

        // Sort by date descending (newest first)
        tempList.sort((a, b) {
          try {
            final dateA = DateTime.parse(a['tanggal']);
            final dateB = DateTime.parse(b['tanggal']);
            return dateB.compareTo(dateA);
          } catch (e) {
            return 0;
          }
        });

        print('📊 Total riwayat items: ${tempList.length}');
      } else {
        print('ℹ️ No bookings found for this mentor');
      }

      setState(() {
        riwayatList = tempList;
        isLoading = false;
      });
    } catch (e) {
      print("❌ Error loading riwayat: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[700]!, Colors.blue[500]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Riwayat Mengajar",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: loadRiwayat,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadRiwayat,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : riwayatList.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.history_edu_rounded,
                              size: 64,
                              color: Colors.blue[300],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Belum Ada Riwayat",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Riwayat sesi mengajar yang sudah selesai\nakan muncul di sini",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: riwayatList.length,
                    itemBuilder: (context, index) {
                      final riwayat = riwayatList[index];
                      return _buildRiwayatCard(riwayat);
                    },
                  ),
      ),
    );
  }

  Widget _buildRiwayatCard(Map<String, dynamic> riwayat) {
    final tanggal = DateTime.parse(riwayat['tanggal']);
    final isCompleted = riwayat['status'] == 'completed';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              isCompleted
                  ? Colors.green[50]!.withOpacity(0.3)
                  : Colors.grey[50]!.withOpacity(0.3),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Date badge
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isCompleted
                            ? [Colors.green[400]!, Colors.green[600]!]
                            : [Colors.grey[400]!, Colors.grey[600]!],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('dd').format(tanggal),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          DateFormat('MMM', 'id_ID').format(tanggal),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
                              .format(tanggal),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.access_time,
                                size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              "${riwayat['jam_mulai']} - ${riwayat['jam_selesai']}",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isCompleted
                            ? [Colors.green[400]!, Colors.green[600]!]
                            : [Colors.grey[400]!, Colors.grey[600]!],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (isCompleted ? Colors.green : Colors.grey)
                              .withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      isCompleted ? 'Selesai' : 'Lewat',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (riwayat['pelajar_name'] != null) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Display student profile photo
                    FutureBuilder<String>(
                      future: _getStudentPhotoUrl(riwayat['pelajar_id']),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                          return CachedCircleAvatar(
                            imageUrl: snapshot.data!,
                            radius: 24,
                            backgroundColor: Colors.blue[100],
                            fallbackIcon: Icons.person,
                            iconColor: Colors.blue[700],
                          );
                        }
                        return Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person_rounded,
                            size: 24,
                            color: Colors.blue[700],
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Pelajar:",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            riwayat['pelajar_name'] ?? 'Pelajar',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (riwayat['harga'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Text(
                          "Rp ${_formatCurrency(riwayat['harga'])}",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              // Display review if exists
              if (riwayat['rating'] != null &&
                  int.tryParse(riwayat['rating'].toString()) != null &&
                  int.parse(riwayat['rating'].toString()) > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber[50]!, Colors.orange[50]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.star_rounded,
                              size: 18, color: Colors.amber[700]),
                          const SizedBox(width: 6),
                          Text(
                            "Review dari Pelajar",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[900],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(5, (i) {
                          return Icon(
                            i < int.parse(riwayat['rating'].toString())
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber[700],
                            size: 20,
                          );
                        }),
                      ),
                      if (riwayat['review'] != null &&
                          riwayat['review'].toString().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          riwayat['review'],
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[800],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              if (riwayat['catatan'] != null &&
                  riwayat['catatan'].toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.note_rounded,
                          size: 16, color: Colors.amber[800]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Catatan:",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber[800],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              riwayat['catatan'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<String> _getStudentPhotoUrl(String? studentId) async {
    if (studentId == null || studentId.isEmpty) {
      print('⚠️ Student ID is null or empty');
      return '';
    }

    print('📸 Trying to load photo for student: $studentId');

    try {
      // Get photo URL from database instead of constructing path
      final snapshot = await _database
          .child('pelajar')
          .child(studentId)
          .child('profile_photo_url')
          .get();

      if (snapshot.exists && snapshot.value != null) {
        final url = snapshot.value.toString();
        print('✅ Photo URL found from database: $url');
        return url;
      } else {
        print('⚠️ No profile_photo_url in database for $studentId');
        return '';
      }
    } catch (e) {
      print('❌ Error loading photo for $studentId: $e');
      return '';
    }
  }

  String _formatCurrency(dynamic value) {
    try {
      double amount = double.parse(value.toString());
      return NumberFormat('#,###', 'id_ID').format(amount);
    } catch (e) {
      return value.toString();
    }
  }
}
