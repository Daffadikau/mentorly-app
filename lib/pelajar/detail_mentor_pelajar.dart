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
  List<Map<String, dynamic>> kelasList = [];
  List<Map<String, dynamic>> allJadwalList = []; // Store all jadwal
  Map<String, List<Map<String, dynamic>>> groupedJadwal = {};
  bool isLoadingJadwal = true;
  bool isLoadingKelas = true;
  DateTime selectedDate = DateTime.now();
  Map<String, dynamic>? selectedJadwal;
  Map<String, dynamic>? selectedKelas; // Track selected kelas
  String? chatRoomId;
  bool hasBooked = false;

  // Real stats from bookings
  double realRating = 0.0;
  int totalReviews = 0;
  int totalStudents = 0;
  int totalSessions = 0;
  bool isLoadingStats = true;

  DateTime? _parseDateFlexible(String dateStr) {
    if (dateStr.isEmpty) return null;
    for (final pattern in ['dd-MM-yyyy', 'yyyy-MM-dd']) {
      try {
        return DateFormat(pattern).parseStrict(dateStr);
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  DateTime? _getNextOccurrenceOfWeekday(
    String hariName, {
    required String jamMulai,
    required String mentorUid,
    required Map<dynamic, dynamic> allJadwalsData,
  }) {
    const hariMap = {
      'Senin': 1,
      'Selasa': 2,
      'Rabu': 3,
      'Kamis': 4,
      'Jumat': 5,
      'Sabtu': 6,
      'Minggu': 7,
    };

    final targetWeekday = hariMap[hariName];
    if (targetWeekday == null) return null;

    DateTime now = DateTime.now();

    // Parse jam mulai
    final jamParts = jamMulai.split(':');
    final jamMulaiInt = int.tryParse(jamParts[0]) ?? 0;
    final menitMulaiInt =
        jamParts.length > 1 ? int.tryParse(jamParts[1]) ?? 0 : 0;

    // Check if today is the target weekday and time hasn't passed
    DateTime current = DateTime(now.year, now.month, now.day);

    if (current.weekday == targetWeekday) {
      // Check if jam mulai hasn't passed yet
      final jadwalTimeToday = DateTime(
        current.year,
        current.month,
        current.day,
        jamMulaiInt,
        menitMulaiInt,
      );

      if (jadwalTimeToday.isAfter(now)) {
        // Check if there's already a booking for today
        bool hasBookingToday = _checkIfJadwalHasBooking(
          hariName,
          current,
          mentorUid,
          allJadwalsData,
        );

        if (!hasBookingToday) {
          print(
              '   ✅ Can use today ($hariName): time not passed yet and no booking');
          return current;
        } else {
          print('   ⏭️ Today has booking, moving to next week');
        }
      } else {
        print('   ⏭️ Time passed today, moving to next week');
      }
    }

    // Find next occurrence of this weekday (next week onwards)
    current = current.add(const Duration(days: 1));
    while (true) {
      if (current.weekday == targetWeekday) {
        return current;
      }
      current = current.add(const Duration(days: 1));
    }
  }

  bool _checkIfJadwalHasBooking(
    String hariName,
    DateTime date,
    String mentorUid,
    Map<dynamic, dynamic> allJadwalData,
  ) {
    // Check if there's a booking for this schedule on this date
    for (var entry in allJadwalData.entries) {
      var value = entry.value;
      if (value is Map) {
        final type = value['type']?.toString() ?? 'one_time';
        final hari = value['hari']?.toString() ?? '';
        final tanggal = value['tanggal']?.toString() ?? '';
        final status = value['status']?.toString() ?? '';

        // Check if it's the same schedule
        if (type == 'weekly' && hari == hariName) {
          // Check if status is 'booked'
          if (status == 'booked') {
            return true;
          }
        }
      }
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _loadJadwal();
    _loadKelas();
    _checkChatRoom();
    _loadRealStats();
  }

  Future<void> _loadRealStats() async {
    setState(() => isLoadingStats = true);

    try {
      final mentorUid = widget.mentorData['uid'] ?? widget.mentorData['id'];
      
      // Get all bookings for this mentor
      final snapshot = await FirebaseDatabase.instance
          .ref('bookings')
          .orderByChild('mentor_id')
          .equalTo(mentorUid.toString())
          .get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        
        double totalRating = 0;
        int reviewCount = 0;
        Set<String> uniqueStudents = {};
        int sessionCount = 0;

        for (var entry in data.entries) {
          final booking = entry.value as Map<dynamic, dynamic>;
          
          // Skip cancelled sessions from count
          final status = booking['status']?.toString().toLowerCase() ?? '';
          final isCancelled = status == 'cancelled' || status == 'canceled';

          if (!isCancelled) {
            sessionCount++;
          }

          // Count unique students
          final pelajarId = booking['pelajar_id']?.toString() ?? '';
          if (pelajarId.isNotEmpty) {
            uniqueStudents.add(pelajarId);
          }

          // Calculate rating from reviews
          final rating = booking['rating'];
          if (rating != null) {
            final ratingValue = double.tryParse(rating.toString()) ?? 0;
            if (ratingValue > 0) {
              totalRating += ratingValue;
              reviewCount++;
            }
          }
        }

        setState(() {
          totalStudents = uniqueStudents.length;
          totalReviews = reviewCount;
          totalSessions = sessionCount;
          realRating = reviewCount > 0 ? totalRating / reviewCount : 0.0;
          isLoadingStats = false;
        });

        print('📊 Real Stats Loaded:');
        print('   Students: $totalStudents');
        print('   Reviews: $totalReviews');
        print('   Rating: ${realRating.toStringAsFixed(2)}');
      } else {
        setState(() {
          totalStudents = 0;
          totalReviews = 0;
          realRating = 0.0;
          isLoadingStats = false;
        });
      }
    } catch (e) {
      print('❌ Error loading real stats: $e');
      setState(() {
        isLoadingStats = false;
      });
    }
  }

  Future<void> _checkChatRoom() async {
    try {
      final pelajarUid = widget.pelajarData['uid'] ?? widget.pelajarData['id'];
      final mentorUid = widget.mentorData['uid'] ?? widget.mentorData['id'];
      final roomId = '${pelajarUid}_$mentorUid';

      final snapshot =
          await FirebaseDatabase.instance.ref('chat_rooms').child(roomId).get();

      if (snapshot.exists) {
        // Check if booking is accepted by checking jadwal
        bool bookingAccepted = false;
        
        // Check all jadwal for this mentor to find accepted booking
        final jadwalSnapshot = await FirebaseDatabase.instance
            .ref('jadwal/$mentorUid')
            .get();
            
        if (jadwalSnapshot.exists) {
          Map<dynamic, dynamic> jadwalMap = jadwalSnapshot.value as Map<dynamic, dynamic>;
          
          for (var entry in jadwalMap.entries) {
            Map<String, dynamic> jadwal = Map<String, dynamic>.from(entry.value as Map);
            
            if (jadwal['booked_by'] == pelajarUid && 
                jadwal['status'] == 'booked' &&
                jadwal['booking_accepted'] == true) {
              
              // Check if session hasn't ended + 1 hour
              String? tanggal = jadwal['tanggal'];
              String? jamSelesai = jadwal['jam_selesai'];
              
              if (tanggal != null && jamSelesai != null) {
                try {
                  DateTime sessionDate = DateTime.parse(tanggal);
                  List<String> timeParts = jamSelesai.split(':');
                  
                  DateTime sessionEnd = DateTime(
                    sessionDate.year,
                    sessionDate.month,
                    sessionDate.day,
                    int.parse(timeParts[0]),
                    int.parse(timeParts[1]),
                  );
                  
                  DateTime cutoffTime = sessionEnd.add(const Duration(hours: 1));
                  
                  if (DateTime.now().isBefore(cutoffTime)) {
                    bookingAccepted = true;
                    break;
                  }
                } catch (e) {
                  print('❌ Error parsing session time: $e');
                }
              } else {
                // No time restriction if date not set
                bookingAccepted = true;
                break;
              }
            }
          }
        }
        
        setState(() {
          chatRoomId = bookingAccepted ? roomId : null;
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

      print('🔄 Preparing booking data...');
      // Get ISO date string from scheduled_date for proper date storage
      String isoDate = '';
      String displayDate = '';
      if (selectedJadwal!['scheduled_date'] != null) {
        DateTime scheduledDate = selectedJadwal!['scheduled_date'] as DateTime;
        isoDate = DateFormat('yyyy-MM-dd').format(scheduledDate);
        displayDate = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(scheduledDate);
      } else {
        // Fallback to current date if scheduled_date is not available
        isoDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
        displayDate = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.now());
      }
      print('📅 Booking date: $isoDate ($displayDate)');

      print('🔄 Updating jadwal status...');
      // Update jadwal status to booked AND save the booking date
      await FirebaseDatabase.instance
          .ref('jadwal')
          .child(mentorUid)
          .child(selectedJadwal!['id'])
          .update({
            'status': 'booked', 
            'booked_by': pelajarUid,
            'tanggal': isoDate,  // Save the actual booking date
            'display_date': displayDate,  // Human readable date
          });
      print('✅ Jadwal updated with date: $isoDate');

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
        'unread_pelajar': 0,
        'unread_mentor': 0,
      });

      print('🔄 Sending welcome message...');
      // Send automatic welcome message from mentor
      String mentorName =
          (widget.mentorData['nama_lengkap'] ?? 'Mentor').toString();
        String pelajarName =
          (widget.pelajarData['nama_lengkap'] ?? 'Pelajar').toString();
        String jamMulai = (selectedJadwal!['jam_mulai'] ?? '-').toString();

        String welcomeMessage =
          'Hai $pelajarName! Saya $mentorName, dan di sesi kali ini saya akan menjadi mentor Anda. '
          'Kita akan melakukan sesi mentoring pada $displayDate pukul $jamMulai. '
          'Saya siap membantu Anda mencapai tujuan belajar. Jangan ragu untuk bertanya kapan saja! 😊🚀';

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
      // Save booking record with the date we already calculated above
      await FirebaseDatabase.instance.ref('bookings').push().set({
        'pelajar_id': pelajarUid,
        'pelajar_name': widget.pelajarData['nama_lengkap'] ?? 'Pelajar',
        'mentor_id': mentorUid,
        'mentor_name': widget.mentorData['nama_lengkap'] ?? 'Mentor',
        'jadwal_id': selectedJadwal!['id'],
        'tanggal': isoDate, // ISO date format for proper parsing
        'display_date': displayDate, // Human readable date
        'jam_mulai': selectedJadwal!['jam_mulai'],
        'jam_selesai': selectedJadwal!['jam_selesai'],
        'harga': widget.mentorData['harga_per_jam'] ?? 0,
        'status': 'confirmed',
        'created_at': timestamp,
      });
      print('✅ Booking saved with date: $isoDate');

      // Send booking notification to mentor
      try {
        String pelajarName = widget.pelajarData['nama_lengkap'] ?? 'Pelajar';
        String subject = selectedJadwal!['mata_pelajaran'] ?? 'Mentoring';
        String date = selectedJadwal!['display_date'] ?? '';
        String timeRange =
            '${selectedJadwal!['jam_mulai']} - ${selectedJadwal!['jam_selesai']}';

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

      final snapshot =
          await FirebaseDatabase.instance.ref('jadwal').child(mentorUid).get();

      print('📊 Snapshot exists: ${snapshot.exists}');

      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value;
        List<Map<String, dynamic>> tempList = [];

        if (data is Map) {
          print('📊 Found ${data.length} jadwal entries');

          // Get current date and time
          final now = DateTime.now();

          data.forEach((key, value) {
            if (value is! Map) return;

            final type = value['type']?.toString() ?? 'one_time';
            final status = value['status']?.toString() ?? 'NO_STATUS';

            print('📋 [$key] Type: $type, Status: $status');

            if (status != 'available') {
              print('   ⏭️ Skipped: status is not available');
              return;
            }

            try {
              DateTime? scheduledDate;
              String displayDate = '';

              if (type == 'weekly') {
                // For weekly schedules, find next occurrence
                final hari = value['hari']?.toString() ?? '';
                final jamMulai = value['jam_mulai']?.toString() ?? '00:00';
                scheduledDate = _getNextOccurrenceOfWeekday(
                  hari,
                  jamMulai: jamMulai,
                  mentorUid: mentorUid,
                  allJadwalsData: data,
                );
                displayDate = hari;
                print('   Weekly: $hari, Next: $scheduledDate');
              } else {
                // For one-time schedules, parse the date
                final tanggalStr = value['tanggal']?.toString() ?? '';
                scheduledDate = _parseDateFlexible(tanggalStr);
                displayDate = tanggalStr;
                print('   OneTime: $tanggalStr, Parsed: $scheduledDate');
              }

              if (scheduledDate == null) {
                print('   ❌ Failed to get scheduled date');
                return;
              }

              final jamMulaiStr = value['jam_mulai']?.toString() ?? '00:00';
              final jamMulaiParts = jamMulaiStr.split(':');
              final jadwalDateTime = DateTime(
                scheduledDate.year,
                scheduledDate.month,
                scheduledDate.day,
                int.parse(jamMulaiParts[0]),
                int.parse(jamMulaiParts[1]),
              );

              print('   🕐 Jadwal time: $jadwalDateTime, Now: $now');

              if (jadwalDateTime.isAfter(now)) {
                tempList.add({
                  'id': key,
                  'display_date': displayDate,
                  'scheduled_date': scheduledDate,
                  ...Map<String, dynamic>.from(value),
                });
                print('   ✅ ADDED');
              } else {
                print('   ⏭️ Skipped: time is in past');
              }
            } catch (e, st) {
              print('   ❌ Error: $e\n$st');
            }
          });
        }

        print('✅ Total jadwal loaded: ${tempList.length}');

        // Sort by date
        tempList.sort((a, b) {
          final dateA = a['scheduled_date'] as DateTime? ?? DateTime.now();
          final dateB = b['scheduled_date'] as DateTime? ?? DateTime.now();
          if (dateA != dateB) return dateA.compareTo(dateB);
          return (a['jam_mulai'] ?? '').compareTo(b['jam_mulai'] ?? '');
        });

        // Group by display date
        Map<String, List<Map<String, dynamic>>> grouped = {};
        for (var jadwal in tempList) {
          final displayDate = jadwal['display_date'] as String? ?? '';
          if (!grouped.containsKey(displayDate)) {
            grouped[displayDate] = [];
          }
          grouped[displayDate]!.add(jadwal);
        }

        setState(() {
          allJadwalList = tempList;
          jadwalList = tempList;
          groupedJadwal = grouped;
          isLoadingJadwal = false;
          if (grouped.isNotEmpty) {
            selectedDate =
                (grouped.values.first.first['scheduled_date'] as DateTime?) ??
                    DateTime.now();
          }
        });
      } else {
        print('❌ No jadwal found');
        setState(() {
          jadwalList = [];
          groupedJadwal = {};
          isLoadingJadwal = false;
        });
      }
    } catch (e, st) {
      print('❌ Error loading jadwal: $e\n$st');
      setState(() {
        jadwalList = [];
        groupedJadwal = {};
        isLoadingJadwal = false;
      });
    }
  }

  Future<void> _loadKelas() async {
    setState(() => isLoadingKelas = true);

    try {
      final mentorUid = widget.mentorData['uid'] ?? widget.mentorData['id'];
      print('🔍 Loading kelas for mentor UID: $mentorUid');

      final snapshot = await FirebaseDatabase.instance.ref('kelas').get();

      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value;
        List<Map<String, dynamic>> tempList = [];

        if (data is Map) {
          data.forEach((key, value) {
            if (value is Map) {
              final kelasData = Map<String, dynamic>.from(value);
              // Filter by mentor_uid and active status
              if (kelasData['mentor_uid'] == mentorUid &&
                  kelasData['status'] == 'active') {
                tempList.add({
                  'id': key,
                  ...kelasData,
                });
                print(
                    '  ✓ Found kelas: ${kelasData['course_name']} - ${kelasData['category']}');
              }
            }
          });
        }

        print('✅ Total kelas found: ${tempList.length}');

        setState(() {
          kelasList = tempList;
          isLoadingKelas = false;
        });
      } else {
        print('⚠️ No kelas found');
        setState(() {
          kelasList = [];
          isLoadingKelas = false;
        });
      }
    } catch (e) {
      print('❌ Error loading kelas: $e');
      setState(() => isLoadingKelas = false);
    }
  }

  void _filterJadwalByKelas() {
    if (selectedKelas == null) {
      // Show all jadwal
      List<Map<String, dynamic>> tempList = allJadwalList;

      // Group by display date
      Map<String, List<Map<String, dynamic>>> grouped = {};
      for (var jadwal in tempList) {
        final displayDate = jadwal['display_date'] as String? ?? '';
        if (!grouped.containsKey(displayDate)) {
          grouped[displayDate] = [];
        }
        grouped[displayDate]!.add(jadwal);
      }

      setState(() {
        jadwalList = tempList;
        groupedJadwal = grouped;
        if (grouped.isNotEmpty) {
          selectedDate =
              (grouped.values.first.first['scheduled_date'] as DateTime?) ??
                  DateTime.now();
        }
      });
    } else {
      // Filter jadwal by selected kelas
      final kelasCategory =
          selectedKelas!['category']?.toString().toLowerCase() ?? '';
      final kelasName =
          selectedKelas!['course_name']?.toString().toLowerCase() ?? '';

      List<Map<String, dynamic>> tempList = allJadwalList.where((jadwal) {
        final jadwalMataPelajaran =
            jadwal['mata_pelajaran']?.toString().toLowerCase() ?? '';

        // Match by category or course name
        return jadwalMataPelajaran.contains(kelasCategory) ||
            jadwalMataPelajaran.contains(kelasName) ||
            kelasName.contains(jadwalMataPelajaran);
      }).toList();

      // Group by display date
      Map<String, List<Map<String, dynamic>>> grouped = {};
      for (var jadwal in tempList) {
        final displayDate = jadwal['display_date'] as String? ?? '';
        if (!grouped.containsKey(displayDate)) {
          grouped[displayDate] = [];
        }
        grouped[displayDate]!.add(jadwal);
      }

      setState(() {
        jadwalList = tempList;
        groupedJadwal = grouped;
        if (grouped.isNotEmpty) {
          selectedDate =
              (grouped.values.first.first['scheduled_date'] as DateTime?) ??
                  DateTime.now();
        }
      });
    }
  }

  void _showKelasDetailDialog(Map<String, dynamic> kelas) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[700],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.school,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                kelas['course_name'] ?? 'Kelas',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
                Icons.category, 'Kategori', kelas['category'] ?? '-'),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.person, 'Level', kelas['class_level'] ?? '-'),
            const SizedBox(height: 12),
            _buildDetailRow(
                Icons.access_time, 'Durasi', kelas['duration'] ?? '-'),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.person_outline, 'Mentor',
                widget.mentorData['nama_lengkap'] ?? 'Mentor'),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pilih jadwal di bawah untuk booking kelas ini',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Scroll to jadwal section
              if (groupedJadwal.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('📅 Silakan pilih jadwal yang tersedia di bawah'),
                    duration: Duration(seconds: 2),
                    backgroundColor: Colors.blue,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        '⚠️ Mentor belum menambahkan jadwal untuk kelas ini'),
                    duration: Duration(seconds: 2),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Lihat Jadwal',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.blue[700]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
                            Text(
                              isLoadingStats
                                  ? "..."
                                  : realRating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              isLoadingStats
                                  ? "Loading"
                                  : "($totalReviews review${totalReviews != 1 ? 's' : ''})",
                              style: TextStyle(
                                fontSize: 11,
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
                            Text(
                              isLoadingStats
                                  ? "..."
                                  : "$totalStudents",
                              style: const TextStyle(
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
                            Text(
                              isLoadingStats ? "..." : "$totalSessions",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Sesi",
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

                  // Kelas Tersedia Section
                  const Text(
                    "Kelas Tersedia",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),

                  if (isLoadingKelas)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (kelasList.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'Mentor belum menambahkan kelas',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: kelasList.map((kelas) {
                        final isSelected = selectedKelas != null &&
                            selectedKelas!['id'] == kelas['id'];

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              // Toggle selection
                              if (isSelected) {
                                selectedKelas = null; // Deselect
                              } else {
                                selectedKelas = kelas; // Select
                              }
                            });
                            _filterJadwalByKelas(); // Filter jadwal
                            _showKelasDetailDialog(kelas); // Show dialog
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isSelected
                                    ? [Colors.blue[700]!, Colors.blue[800]!]
                                    : [Colors.blue[50]!, Colors.blue[100]!],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.blue[900]!
                                    : Colors.blue[200]!,
                                width: isSelected ? 3 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? Colors.blue.withOpacity(0.4)
                                      : Colors.blue.withOpacity(0.1),
                                  blurRadius: isSelected ? 8 : 4,
                                  offset: Offset(0, isSelected ? 4 : 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.blue[700],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        isSelected
                                            ? Icons.check_circle
                                            : Icons.school,
                                        color: isSelected
                                            ? Colors.blue[700]
                                            : Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            kelas['course_name'] ?? 'Kelas',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            kelas['category'] ?? '',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: isSelected
                                                  ? Colors.white
                                                      .withOpacity(0.9)
                                                  : Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      isSelected
                                          ? Icons.check
                                          : Icons.arrow_forward_ios,
                                      size: 16,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.blue[700],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    _buildKelasInfo(
                                      Icons.person,
                                      kelas['class_level'] ?? '-',
                                      isSelected: isSelected,
                                    ),
                                    const SizedBox(width: 16),
                                    _buildKelasInfo(
                                      Icons.access_time,
                                      kelas['duration'] ?? '-',
                                      isSelected: isSelected,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 25),

                  // Jadwal Section - Only show if kelas is selected
                  if (selectedKelas != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Jadwal",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedKelas = null;
                            });
                            _filterJadwalByKelas();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue[700],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Filter: ${selectedKelas!['course_name']}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.clear,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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
                            'Mentor belum menambahkan jadwal untuk kelas ini',
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
                            final displayDate =
                                groupedJadwal.keys.toList()[index];
                            final jadwalForDate =
                                groupedJadwal[displayDate] ?? [];
                            final scheduledDate = (jadwalForDate.isNotEmpty
                                    ? jadwalForDate.first['scheduled_date']
                                        as DateTime?
                                    : null) ??
                                DateTime.now();
                            final isSelected = DateFormat('yyyy-MM-dd')
                                    .format(scheduledDate) ==
                                DateFormat('yyyy-MM-dd').format(selectedDate);

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedDate = scheduledDate;
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
                                      DateFormat('E', 'id_ID')
                                          .format(scheduledDate),
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
                                      DateFormat('dd').format(scheduledDate),
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
                  ], // End of jadwal section (only show if kelas selected)

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
                  if (selectedKelas != null) ...[
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
                            "Rp ${_formatCurrency(selectedKelas!['price'] ?? widget.mentorData['harga_per_jam'])} / sesi",
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
                  ],
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
                            final jadwalDate = selectedJadwal!['scheduled_date']
                                    as DateTime? ??
                                now;
                            final jamMulai = selectedJadwal!['jam_mulai']
                                .toString()
                                .split(':');
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
                                  content: Text(
                                      '❌ Tidak dapat booking jadwal yang sudah lewat'),
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
                                  selectedJadwal!['scheduled_date']
                                          as DateTime? ??
                                      DateTime.now());
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
    // Find the display_date key that matches the selected date
    String? matchingDisplayDate;
    for (final displayDate in groupedJadwal.keys) {
      final jadwalList = groupedJadwal[displayDate] ?? [];
      if (jadwalList.isNotEmpty) {
        final scheduledDate = jadwalList.first['scheduled_date'] as DateTime?;
        if (scheduledDate != null &&
            DateFormat('yyyy-MM-dd').format(scheduledDate) ==
                DateFormat('yyyy-MM-dd').format(selectedDate)) {
          matchingDisplayDate = displayDate;
          break;
        }
      }
    }

    final slots = matchingDisplayDate != null
        ? groupedJadwal[matchingDisplayDate] ?? []
        : [];

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

  Widget _buildKelasInfo(IconData icon, String text,
      {bool isSelected = false}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isSelected ? Colors.white : Colors.blue[700],
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color:
                isSelected ? Colors.white.withOpacity(0.9) : Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
