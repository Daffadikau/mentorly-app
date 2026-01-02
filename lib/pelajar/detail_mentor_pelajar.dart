import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import '../common/chat_room.dart';
import '../services/notification_service.dart';
import '../widgets/cached_circle_avatar.dart';
// import 'konfirmasi_booking.dart';

class DetailMentor extends StatefulWidget {
  final Map<String, dynamic> mentorData;
  final Map<String, dynamic> pelajarData;

  const DetailMentor(
      {super.key, required this.mentorData, required this.pelajarData});

  @override
  State<DetailMentor> createState() => _DetailMentorState();
}

class _DetailMentorState extends State<DetailMentor> {
  List<Map<String, dynamic>> jadwalList = [];
  Map<String, List<Map<String, dynamic>>> groupedJadwal = {};
  bool isLoadingJadwal = true;
  DateTime selectedDate = DateTime.now();
  Map<String, dynamic>? selectedJadwal;
  String? chatRoomId;
  bool hasBooked = false;

  @override
  void initState() {
    super.initState();
    _loadJadwal();
    _checkChatRoom();
  }

  Future<void> _checkChatRoom() async {
    try {
      final pelajarUid = widget.pelajarData['uid'] ?? widget.pelajarData['id'];
      final mentorUid = widget.mentorData['uid'] ?? widget.mentorData['id'];
      final roomId = '${pelajarUid}_$mentorUid';

      final snapshot =
          await FirebaseDatabase.instance.ref('chat_rooms').child(roomId).get();

      if (snapshot.exists) {
        setState(() {
          chatRoomId = roomId;
          hasBooked = true;
        });
      }
    } catch (e) {
      print('Error checking chat room: $e');
    }
  }

  Future<void> _createBooking() async {
    if (selectedJadwal == null) {
      print('❌ No jadwal selected');
      throw Exception('Pilih jadwal terlebih dahulu');
    }

    try {
      print('📋 Pelajar data: ${widget.pelajarData}');
      print('📋 Mentor data: ${widget.mentorData}');
      print('📋 Selected jadwal: $selectedJadwal');

      final pelajarUid = widget.pelajarData['uid'] ?? widget.pelajarData['id'];
      final mentorUid = widget.mentorData['uid'] ?? widget.mentorData['id'];

      if (pelajarUid == null || mentorUid == null) {
        throw Exception('User ID tidak ditemukan');
      }

      final roomId = '${pelajarUid}_$mentorUid';
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      print('🔄 Updating jadwal status...');
      // Update jadwal status to booked
      await FirebaseDatabase.instance
          .ref('jadwal')
          .child(mentorUid)
          .child(selectedJadwal!['id'])
          .update({'status': 'booked', 'booked_by': pelajarUid});

      print('🔄 Creating chat room...');
      // Create chat room - ensure IDs are strings
      await FirebaseDatabase.instance.ref('chat_rooms').child(roomId).set({
        'pelajar_id': pelajarUid.toString(),
        'pelajar_name': widget.pelajarData['nama_lengkap'] ?? 'Pelajar',
        'mentor_id': mentorUid.toString(),
        'mentor_name': widget.mentorData['nama_lengkap'] ?? 'Mentor',
        'created_at': timestamp,
        'last_message': 'Chat dimulai',
        'last_message_time': timestamp,
      });

      print('🔄 Sending welcome message...');
      // Send automatic welcome message from mentor
      String mentorName =
          (widget.mentorData['nama_lengkap'] ?? 'Mentor').toString();
      String bidangKeahlian =
          (widget.mentorData['bidang_keahlian'] ?? 'berbagai bidang')
              .toString();
      String pengalaman = (widget.mentorData['pengalaman'] ?? 5).toString();

      String welcomeMessage =
          'Hai! Saya $mentorName, dan saat ini saya akan menjadi mentor Anda. '
          'Saya berspesialisasi dalam $bidangKeahlian dengan pengalaman mengajar selama $pengalaman tahun. '
          'Saya siap membantu Anda mencapai tujuan belajar. Jangan ragu untuk bertanya kapan saja! 😊';

      await FirebaseDatabase.instance.ref('messages').child(roomId).push().set({
        'sender_id': mentorUid.toString(),
        'sender_name': mentorName,
        'message': welcomeMessage,
        'timestamp': timestamp + 1, // Slightly after room creation
        'type': 'text',
        'is_system': true, // Mark as system message
      });

      // Update last message in chat room
      await FirebaseDatabase.instance.ref('chat_rooms').child(roomId).update({
        'last_message': welcomeMessage,
        'last_message_time': timestamp + 1,
      });

      print('🔄 Saving booking record...');
      // Save booking record
      await FirebaseDatabase.instance.ref('bookings').push().set({
        'pelajar_id': pelajarUid,
        'pelajar_name': widget.pelajarData['nama_lengkap'] ?? 'Pelajar',
        'mentor_id': mentorUid,
        'mentor_name': widget.mentorData['nama_lengkap'] ?? 'Mentor',
        'jadwal_id': selectedJadwal!['id'],
        'tanggal': selectedJadwal!['tanggal'],
        'jam_mulai': selectedJadwal!['jam_mulai'],
        'jam_selesai': selectedJadwal!['jam_selesai'],
        'harga': widget.mentorData['harga_per_jam'] ?? 0,
        'status': 'confirmed',
        'created_at': timestamp,
      });

      // Send booking notification to mentor
      try {
        String pelajarName = widget.pelajarData['nama_lengkap'] ?? 'Pelajar';
        String subject = selectedJadwal!['mata_pelajaran'] ?? 'Mentoring';
        String date = selectedJadwal!['tanggal'] ?? '';
        String timeRange = '${selectedJadwal!['jam_mulai']} - ${selectedJadwal!['jam_selesai']}';
        
        await NotificationService.sendBookingNotification(
          mentorId: mentorUid.toString(),
          pelajarName: pelajarName,
          subject: subject,
          date: date,
          time: timeRange,
        );
      } catch (e) {
        print('Error sending booking notification: $e');
        // Don't show error to user for notification failure
      }

      print('🔄 Updating UI state...');
      setState(() {
        chatRoomId = roomId;
        hasBooked = true;
        selectedJadwal = null; // Clear selection
      });

      print('🔄 Reloading jadwal...');
      // Reload jadwal to reflect booked status
      await _loadJadwal();

      print('✅ Booking completed!');
    } catch (e, stackTrace) {
      print('❌ Error creating booking: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> _loadJadwal() async {
    setState(() => isLoadingJadwal = true);

    try {
      final mentorUid = widget.mentorData['uid'] ?? widget.mentorData['id'];
      print('🔍 Loading jadwal for mentor UID: $mentorUid');
      print('📊 Mentor data keys: ${widget.mentorData.keys.toList()}');

      final snapshot =
          await FirebaseDatabase.instance.ref('jadwal').child(mentorUid).get();

      print('📊 Snapshot exists: ${snapshot.exists}');
      print('📊 Snapshot value: ${snapshot.value}');

      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value;
        List<Map<String, dynamic>> tempList = [];

        if (data is Map) {
          print('📊 Found ${data.length} jadwal entries');
          
          // Get current date and time
          final now = DateTime.now();
          
          data.forEach((key, value) {
            print(
                '  - Jadwal key: $key, status: ${value is Map ? value['status'] : 'unknown'}');
            
            if (value is Map && value['status'] == 'available') {
              // Parse jadwal date and time
              try {
                final jadwalDate = DateTime.parse(value['tanggal']);
                final jamMulai = value['jam_mulai'].toString().split(':');
                final jadwalDateTime = DateTime(
                  jadwalDate.year,
                  jadwalDate.month,
                  jadwalDate.day,
                  int.parse(jamMulai[0]),
                  int.parse(jamMulai[1]),
                );
                
                // Only show future schedules
                if (jadwalDateTime.isAfter(now)) {
                  tempList.add({
                    'id': key,
                    ...Map<String, dynamic>.from(value),
                  });
                  print('  ✅ Added: ${value['tanggal']} ${value['jam_mulai']} (future)');
                } else {
                  print('  ⏭️ Skipped: ${value['tanggal']} ${value['jam_mulai']} (past)');
                }
              } catch (e) {
                print('  ❌ Error parsing jadwal time: $e');
              }
            }
          });
        }

        print('✅ Total available jadwal: ${tempList.length}');

        // Sort by date and time
        tempList.sort((a, b) {
          final dateA = DateTime.parse(a['tanggal']);
          final dateB = DateTime.parse(b['tanggal']);
          if (dateA != dateB) return dateA.compareTo(dateB);
          return a['jam_mulai'].compareTo(b['jam_mulai']);
        });

        // Group by date
        Map<String, List<Map<String, dynamic>>> grouped = {};
        for (var jadwal in tempList) {
          final tanggal = jadwal['tanggal'];
          if (!grouped.containsKey(tanggal)) {
            grouped[tanggal] = [];
          }
          grouped[tanggal]!.add(jadwal);
        }

        setState(() {
          jadwalList = tempList;
          groupedJadwal = grouped;
          isLoadingJadwal = false;
          // Set first available date as selected
          if (grouped.isNotEmpty) {
            selectedDate = DateTime.parse(grouped.keys.first);
          }
        });
      } else {
        setState(() {
          jadwalList = [];
          groupedJadwal = {};
          isLoadingJadwal = false;
        });
      }
    } catch (e) {
      print('Error loading jadwal: $e');
      setState(() => isLoadingJadwal = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        elevation: 0,
        title:
            const Text("Detail Mentor", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.blue[700],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  CachedCircleAvatar(
                    imageUrl: widget.mentorData['profile_photo_url'],
                    radius: 60,
                    backgroundColor: Colors.white,
                    iconColor: Colors.blue[700],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    widget.mentorData['nama_lengkap'] ?? 'Nama Mentor',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    decoration: BoxDecoration(
                      color: widget.mentorData['is_active'] == '1'
                          ? Colors.green
                          : Colors.grey,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.mentorData['is_active'] == '1'
                          ? 'Online'
                          : 'Offline',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Icon(Icons.star,
                                color: Colors.amber, size: 30),
                            const SizedBox(height: 5),
                            const Text(
                              "5.0",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Rating",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        Container(
                            height: 50, width: 1, color: Colors.grey[300]),
                        Column(
                          children: [
                            Icon(Icons.people,
                                color: Colors.blue[700], size: 30),
                            const SizedBox(height: 5),
                            const Text(
                              "150+",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Siswa",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        Container(
                            height: 50, width: 1, color: Colors.grey[300]),
                        Column(
                          children: [
                            const Icon(Icons.school,
                                color: Colors.green, size: 30),
                            const SizedBox(height: 5),
                            const Text(
                              "5+",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Tahun",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Jadwal Section
                  const Text(
                    "Jadwal",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),

                  if (isLoadingJadwal)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (groupedJadwal.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'Mentor belum menambahkan jadwal',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    )
                  else ...[
                    // Date selector (horizontal scroll)
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: groupedJadwal.keys.length,
                        itemBuilder: (context, index) {
                          final dateStr = groupedJadwal.keys.toList()[index];
                          final date = DateTime.parse(dateStr);
                          final isSelected =
                              DateFormat('yyyy-MM-dd').format(date) ==
                                  DateFormat('yyyy-MM-dd').format(selectedDate);

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedDate = date;
                                selectedJadwal =
                                    null; // Clear selection when changing date
                              });
                            },
                            child: Container(
                              width: 70,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.blue[700]
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.blue[700]!
                                      : Colors.grey[300]!,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    DateFormat('E', 'id_ID').format(date),
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey[700],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('dd').format(date),
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Time slots title
                    const Text(
                      "Jam",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Time slots grid
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _buildTimeSlots(),
                    ),
                  ],

                  const SizedBox(height: 25),
                  const Text(
                    "Keahlian",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildSkillChip(
                          widget.mentorData['bidang_keahlian'] ?? 'Umum'),
                      if (widget.mentorData['pengalaman'] != null &&
                          widget.mentorData['pengalaman'].toString().isNotEmpty)
                        _buildSkillChip(
                            '${widget.mentorData['pengalaman']} tahun'),
                    ],
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    "Tentang Mentor",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Mentor berpengalaman dengan dedikasi tinggi dalam mengajar dan membimbing siswa. Menggunakan metode pembelajaran yang interaktif dan disesuaikan dengan kebutuhan setiap siswa untuk hasil belajar yang optimal.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    "Harga",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Rp ${_formatCurrency(widget.mentorData['harga_per_jam'])} / jam",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                        ),
                        Icon(Icons.attach_money,
                            color: Colors.orange[700], size: 30),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  // Real reviews from bookings will be shown here in future update
                  // For now, removed fake demo reviews
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: chatRoomId == null
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  "Lakukan booking terlebih dahulu untuk chat"),
                            ),
                          );
                        }
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatRoom(
                                roomId: chatRoomId!,
                                currentUser: widget.pelajarData,
                                otherUser: widget.mentorData,
                                userType: 'pelajar',
                              ),
                            ),
                          );
                        },
                  icon: Icon(
                    Icons.chat,
                    color: chatRoomId == null ? Colors.grey : Colors.blue[700],
                  ),
                  label: Text(
                    "Chat",
                    style: TextStyle(
                      fontSize: 16,
                      color:
                          chatRoomId == null ? Colors.grey : Colors.blue[700],
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color:
                          chatRoomId == null ? Colors.grey : Colors.blue[700]!,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: selectedJadwal == null
                      ? null
                      : () {
                          // Validate jadwal is not in the past
                          try {
                            final now = DateTime.now();
                            final jadwalDate = DateTime.parse(selectedJadwal!['tanggal']);
                            final jamMulai = selectedJadwal!['jam_mulai'].toString().split(':');
                            final jadwalDateTime = DateTime(
                              jadwalDate.year,
                              jadwalDate.month,
                              jadwalDate.day,
                              int.parse(jamMulai[0]),
                              int.parse(jamMulai[1]),
                            );
                            
                            if (jadwalDateTime.isBefore(now)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('❌ Tidak dapat booking jadwal yang sudah lewat'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                          } catch (e) {
                            print('Error validating jadwal time: $e');
                          }
                          
                          // TODO: Navigate to booking confirmation
                          final dateStr =
                              DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(
                                  DateTime.parse(selectedJadwal!['tanggal']));
                          final timeStr =
                              '${selectedJadwal!['jam_mulai']}-${selectedJadwal!['jam_selesai']}';

                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Konfirmasi Booking'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'Mentor: ${widget.mentorData['nama_lengkap']}'),
                                  const SizedBox(height: 8),
                                  Text('Tanggal: $dateStr'),
                                  const SizedBox(height: 8),
                                  Text('Waktu: $timeStr'),
                                  const SizedBox(height: 8),
                                  Text(
                                      'Harga: Rp ${_formatCurrency(widget.mentorData['harga_per_jam'])}'),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Batal'),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    // Get the navigator before async operations
                                    final navigator = Navigator.of(context);
                                    final scaffoldMessenger =
                                        ScaffoldMessenger.of(context);

                                    // Close confirmation dialog
                                    navigator.pop();

                                    // Show loading dialog
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (dialogContext) => WillPopScope(
                                        onWillPop: () async => false,
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                    );

                                    try {
                                      print('🔄 Starting booking process...');
                                      await _createBooking();
                                      print('✅ Booking completed successfully');

                                      // Close loading dialog
                                      navigator.pop();

                                      scaffoldMessenger.showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Booking berhasil! Silakan hubungi mentor via chat.'),
                                          backgroundColor: Colors.green,
                                          duration: Duration(seconds: 3),
                                        ),
                                      );
                                    } catch (e) {
                                      print('❌ Booking error: $e');

                                      // Close loading dialog
                                      navigator.pop();

                                      scaffoldMessenger.showSnackBar(
                                        SnackBar(
                                          content: Text('Gagal booking: $e'),
                                          backgroundColor: Colors.red,
                                          duration: const Duration(seconds: 3),
                                        ),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green[600],
                                  ),
                                  child: const Text('Konfirmasi',
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    selectedJadwal == null ? 'Pilih Jadwal' : 'Booking',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTimeSlots() {
    final selectedDateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    final slots = groupedJadwal[selectedDateStr] ?? [];

    if (slots.isEmpty) {
      return [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              'Tidak ada jadwal tersedia',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
      ];
    }

    return slots.map((jadwal) {
      final isSelected =
          selectedJadwal != null && selectedJadwal!['id'] == jadwal['id'];

      return GestureDetector(
        onTap: () {
          setState(() {
            selectedJadwal = jadwal;
          });
        },
        child: Container(
          width: (MediaQuery.of(context).size.width - 60) / 2,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue[700] : Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.blue[700]! : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            '${jadwal['jam_mulai']}-${jadwal['jam_selesai']}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : Colors.black,
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildSkillChip(String skill) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Text(
        skill,
        style: TextStyle(
          color: Colors.blue[700],
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return "20.000";
    double amount = double.parse(value.toString());
    if (amount == 0) amount = 20000;
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }
}
