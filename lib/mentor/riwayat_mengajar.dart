import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

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
      final uid = widget.mentorData['uid'];
      final snapshot = await _database.child('jadwal').child(uid).get();

      List<Map<String, dynamic>> tempList = [];

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;

        for (var entry in data.entries) {
          final jadwalData = Map<String, dynamic>.from(entry.value as Map);
          jadwalData['jadwal_id'] = entry.key;

          // Hanya ambil jadwal yang sudah selesai (completed) atau yang tanggalnya sudah lewat
          final tanggal = DateTime.parse(jadwalData['tanggal']);
          final now = DateTime.now();
          final isCompleted = jadwalData['status'] == 'completed';
          final isPast = tanggal.isBefore(DateTime(now.year, now.month, now.day));

          if (isCompleted || (isPast && jadwalData['status'] == 'booked')) {
            // Load student data if booked
            if (jadwalData['booked_by'] != null) {
              try {
                final studentSnapshot = await _database
                    .child('pelajar')
                    .child(jadwalData['booked_by'])
                    .get();

                if (studentSnapshot.exists) {
                  final studentData = studentSnapshot.value as Map;
                  jadwalData['student_name'] = studentData['nama_lengkap'] ?? 
                                                 studentData['email'] ?? 
                                                 'Pelajar';
                  jadwalData['student_uid'] = jadwalData['booked_by'];
                  jadwalData['student_email'] = studentData['email'];
                }
              } catch (e) {
                print("Error loading student: $e");
                jadwalData['student_name'] = 'Pelajar';
              }
            }

            tempList.add(jadwalData);
          }
        }

        // Sort by date descending (newest first)
        tempList.sort((a, b) {
          final dateA = DateTime.parse(a['tanggal']);
          final dateB = DateTime.parse(b['tanggal']);
          return dateB.compareTo(dateA);
        });
      }

      setState(() {
        riwayatList = tempList;
        isLoading = false;
      });
    } catch (e) {
      print("Error loading riwayat: $e");
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
              isCompleted ? Colors.green[50]!.withOpacity(0.3) : Colors.grey[50]!.withOpacity(0.3),
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
                          DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(tanggal),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isCompleted
                            ? [Colors.green[400]!, Colors.green[600]!]
                            : [Colors.grey[400]!, Colors.grey[600]!],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (isCompleted ? Colors.green : Colors.grey).withOpacity(0.3),
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
              if (riwayat['student_name'] != null) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        size: 20,
                        color: Colors.blue[700],
                      ),
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
                            riwayat['student_name'],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              if (riwayat['catatan'] != null && riwayat['catatan'].toString().isNotEmpty) ...[
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
                      Icon(Icons.note_rounded, size: 16, color: Colors.amber[800]),
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
}
