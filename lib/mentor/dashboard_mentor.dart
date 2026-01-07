import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import '../common/welcome_page.dart';
import '../utils/session_manager.dart';
import 'profile_mentor.dart';
import 'transaction_mentor.dart';
import 'demo_add_earning.dart';
import 'jadwal_mentor.dart';
import 'riwayat_mengajar.dart';
import '../common/chat_list.dart';
import '../common/chat_room.dart';
import 'tambah_kelas_mentor.dart';
import 'daftar_kelas_mentor.dart';

class DashboardMentor extends StatefulWidget {
  final Map<String, dynamic> mentorData;

  const DashboardMentor({super.key, required this.mentorData});

  @override
  _DashboardMentorState createState() => _DashboardMentorState();
}

class _DashboardMentorState extends State<DashboardMentor> {
  List jadwalList = [];
  bool isActive = true;
  late Map<String, dynamic> currentMentorData;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  late PageController _pageController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    currentMentorData = widget.mentorData;
    isActive = currentMentorData['is_active'] == '1';
    loadJadwal();
    _loadMentorBalance();
    _loadLatestMentorData();
  }

  @override
  void didUpdateWidget(DashboardMentor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload data when widget is updated
    if (oldWidget.mentorData != widget.mentorData) {
      setState(() {
        currentMentorData = widget.mentorData;
        isActive = currentMentorData['is_active'] == '1';
      });
      _loadLatestMentorData();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadLatestMentorData() async {
    try {
      // Load from session first
      final sessionData = await SessionManager.getUserData();
      if (sessionData != null) {
        setState(() {
          currentMentorData = sessionData;
        });
      }

      // Then load from Firebase to ensure we have the latest
      final uid = currentMentorData['uid'];
      final snapshot = await _database.child('mentors').child(uid).get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          currentMentorData = Map<String, dynamic>.from(data);
        });

        // Update session with latest data
        await SessionManager.saveSession(
          userType: 'mentor',
          userData: currentMentorData,
        );
      }
    } catch (e) {
      print('Error loading latest mentor data: $e');
    }
  }

  Future<void> _loadMentorBalance() async {
    try {
      final snapshot = await _database
          .child('mentors')
          .child(currentMentorData['uid'])
          .child('balance')
          .get();

      if (snapshot.exists) {
        setState(() {
          currentMentorData['total_penghasilan'] = snapshot.value.toString();
        });
      }
    } catch (e) {
      print('Error loading balance: $e');
    }
  }

  Future<void> loadJadwal() async {
    try {
      final mentorUid = currentMentorData['uid'];
      final snapshot = await _database.child('jadwal').child(mentorUid).get();

      if (snapshot.exists) {
        List<Map<String, dynamic>> tempList = [];
        final data = snapshot.value as Map<dynamic, dynamic>;

        for (var entry in data.entries) {
          final key = entry.key;
          final value = entry.value;

          if (value is Map) {
            Map<String, dynamic> jadwalData = {
              'id': key,
              'mata_pelajaran': value['mata_pelajaran'] ?? '',
              'tanggal': value['tanggal'] ?? '',
              'jam_mulai': value['jam_mulai'] ?? '',
              'jam_selesai': value['jam_selesai'] ?? '',
              'harga': value['harga'] ?? '',
              'deskripsi': value['deskripsi'] ?? '',
              'catatan': value['catatan'] ?? '',
              'status': value['status'] ?? 'available',
              'booked_by': value['booked_by'] ?? '',
              'student_name': '',
            };

            jadwalData['computed_status'] = _deriveStatus(
                jadwalData['status'],
                jadwalData['tanggal'],
                jadwalData['jam_mulai'],
                jadwalData['jam_selesai']);

            // Jika jadwal sudah di-booking, ambil data pelajar
            if (jadwalData['status'] == 'booked' &&
                jadwalData['booked_by'].toString().isNotEmpty) {
              try {
                final studentSnapshot = await _database
                    .child('pelajar')
                    .child(jadwalData['booked_by'])
                    .get();

                if (studentSnapshot.exists) {
                  final studentData =
                      studentSnapshot.value as Map<dynamic, dynamic>;
                  jadwalData['student_name'] = studentData['nama_lengkap'] ??
                      studentData['email'] ??
                      'Pelajar';
                  jadwalData['student_uid'] = jadwalData['booked_by'];
                  jadwalData['student_email'] = studentData['email'] ?? '';
                }
              } catch (e) {
                print('Error loading student name: $e');
              }
            }

            tempList.add(jadwalData);
          }
        }

        // Hanya tampilkan sesi yang sudah dipesan
        tempList = tempList
            .where((j) => (j['status'] ?? 'available') == 'booked')
            .toList();

        // Urutkan berdasarkan waktu mulai (jika dapat diparse)
        tempList.sort((a, b) {
          final aStart =
              _combineDateTime(a['tanggal'] ?? '', a['jam_mulai'] ?? '');
          final bStart =
              _combineDateTime(b['tanggal'] ?? '', b['jam_mulai'] ?? '');
          if (aStart == null && bStart == null) return 0;
          if (aStart == null) return 1;
          if (bStart == null) return -1;
          return aStart.compareTo(bStart);
        });

        setState(() {
          jadwalList = tempList;
        });
      } else {
        setState(() {
          jadwalList = [];
        });
      }
    } catch (e) {
      print('Error loading jadwal: $e');
      setState(() {
        jadwalList = [];
      });
    }
  }

  Future<void> tarikDana() async {
    double currentBalance =
        double.tryParse(currentMentorData['total_penghasilan'].toString()) ?? 0;

    if (currentBalance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Saldo tidak mencukupi untuk penarikan")),
      );
      return;
    }

    // Show confirmation dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Penarikan'),
        content: Text(
          'Anda akan menarik Rp ${_formatCurrency(currentBalance)}\n\nDana akan diproses dan dikirim ke rekening Anda dalam 1-3 hari kerja.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
            ),
            child: const Text(
              'Tarik Dana',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      String uid = currentMentorData['uid'];
      int timestamp = DateTime.now().millisecondsSinceEpoch;

      // Create withdrawal transaction
      await _database.child('transactions').child(uid).push().set({
        'type': 'withdrawal',
        'amount': currentBalance,
        'status': 'processing',
        'description': 'Penarikan dana ke rekening',
        'timestamp': timestamp,
      });

      // Update mentor balance to 0
      await _database.child('mentors').child(uid).update({
        'balance': 0,
        'last_withdrawal': timestamp,
      });

      // Update dana_proses
      double danaProses = double.tryParse(
              currentMentorData['dana_proses']?.toString() ?? '0') ??
          0;
      await _database.child('mentors').child(uid).update({
        'dana_proses': danaProses + currentBalance,
      });

      setState(() {
        currentMentorData['dana_proses'] =
            (danaProses + currentBalance).toString();
        currentMentorData['total_penghasilan'] = '0';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Dana berhasil ditarik dan sedang diproses"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error withdrawing funds: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menarik dana: $e')),
        );
      }
    }
  }

  Future<void> _toggleActiveStatus() async {
    try {
      final newStatus = !isActive;
      final uid = currentMentorData['uid'];

      // Update status di Firebase
      await _database.child('mentors').child(uid).update({
        'is_active': newStatus ? '1' : '0',
      });

      setState(() {
        isActive = newStatus;
        currentMentorData['is_active'] = newStatus ? '1' : '0';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus
                  ? 'Status diubah menjadi Active - Pelajar dapat memesan jadwal Anda'
                  : 'Status diubah menjadi Non Active - Pelajar tidak dapat memesan jadwal Anda',
            ),
            backgroundColor: newStatus ? Colors.green : Colors.grey,
          ),
        );
      }
    } catch (e) {
      print('Error toggling status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengubah status: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalSessions = jadwalList.where((j) => j['status'] == 'booked').length;
    int availableSlots =
        jadwalList.where((j) => j['status'] == 'available').length;
    double earnings = double.tryParse(
            currentMentorData['total_penghasilan']?.toString() ?? '0') ??
        0;
    double rating =
        double.tryParse(currentMentorData['rating']?.toString() ?? '0') ?? 0;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          // Halaman 0: Beranda
          _buildBerandaPage(
              context, totalSessions, availableSlots, earnings, rating),
          // Halaman 1: Transaksi
          TransactionMentor(mentorData: currentMentorData),
          // Halaman 2: Chat
          ChatListPage(
            userData: currentMentorData,
            userType: 'mentor',
          ),
          // Halaman 3: Profil
          ProfileMentor(mentorData: currentMentorData),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue[700],
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (_selectedIndex != index) {
            setState(() {
              _selectedIndex = index;
            });
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet), label: 'Transaksi'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'kelas_saya',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  DaftarKelasMentor(mentorData: currentMentorData),
            ),
          );
        },
        backgroundColor: const Color(0xFF5B6BC4),
        child: const Icon(Icons.school, color: Colors.white),
        elevation: 4,
      ),
    );
  }

  Widget _buildBerandaPage(BuildContext context, int totalSessions,
      int availableSlots, double earnings, double rating) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Modern Header with Gradient
          Container(
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 15, 20, 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[700]!, Colors.blue[500]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Halo, ${currentMentorData['nama_lengkap']}!",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.green.withOpacity(0.2)
                              : Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                isActive ? Colors.greenAccent : Colors.white54,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.greenAccent
                                    : Colors.white70,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isActive ? "Active" : "Non Active",
                              style: TextStyle(
                                color: isActive
                                    ? Colors.greenAccent
                                    : Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) async {
                    if (value == 'toggle_status') {
                      // Toggle active status
                      await _toggleActiveStatus();
                    } else if (value == 'demo') {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DemoAddEarning(
                            mentorUid: currentMentorData['uid'],
                            mentorName: currentMentorData['nama_lengkap'],
                          ),
                        ),
                      );
                      if (result == true) {
                        _loadMentorBalance();
                      }
                    } else if (value == 'logout') {
                      await SessionManager.logout();
                      if (mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WelcomePage(),
                          ),
                          (route) => false,
                        );
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'toggle_status',
                      child: Row(
                        children: [
                          Icon(
                            isActive ? Icons.toggle_on : Icons.toggle_off,
                            color: isActive ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(isActive ? 'Set Non Active' : 'Set Active'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'demo',
                      child: Row(
                        children: [
                          Icon(Icons.attach_money, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Demo Tambah Pemasukan'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Logout'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Statistics Cards
                Row(
                  children: [
                    Icon(Icons.analytics_rounded,
                        color: Colors.blue[700], size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      "Statistik Anda",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniStatCard(
                        'Sesi',
                        totalSessions.toString(),
                        Icons.school_rounded,
                        Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMiniStatCard(
                        'Slot Tersedia',
                        availableSlots.toString(),
                        Icons.event_available_rounded,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniStatCard(
                        'Rating',
                        rating.toStringAsFixed(1),
                        Icons.star_rounded,
                        Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMiniStatCard(
                        'Penghasilan',
                        'Rp ${NumberFormat('#,###', 'id_ID').format(earnings)}',
                        Icons.account_balance_wallet_rounded,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionButton(
                        'Jadwal',
                        Icons.edit_calendar_rounded,
                        Colors.blue,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => JadwalMentor(
                                mentorData: currentMentorData,
                              ),
                            ),
                          ).then((_) => loadJadwal());
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickActionButton(
                        'Riwayat',
                        Icons.history_rounded,
                        Colors.green,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RiwayatMengajar(
                                mentorData: currentMentorData,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                // Upcoming Sessions
                Row(
                  children: [
                    Icon(Icons.upcoming_rounded,
                        color: Colors.purple[700], size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      "Sesi Mendatang",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                jadwalList.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text("Belum ada jadwal mengajar"),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: jadwalList.length,
                        itemBuilder: (context, index) {
                          var jadwal = jadwalList[index];
                          final tanggal =
                              _parseDateFlexible(jadwal['tanggal'] ?? '');
                          if (tanggal == null) {
                            return const SizedBox.shrink();
                          }
                          final baseStatus = jadwal['status'] ?? 'available';
                          final derivedStatus =
                              jadwal['computed_status'] ?? baseStatus;
                          final isBooked = baseStatus == 'booked';
                          final isAvailable = baseStatus == 'available';
                          final isOngoing = derivedStatus == 'ongoing';
                          final isFinished = derivedStatus == 'finished';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: isOngoing
                                      ? Colors.blue[100]
                                      : isFinished
                                          ? Colors.grey[200]
                                          : isBooked
                                              ? Colors.orange[100]
                                              : isAvailable
                                                  ? Colors.green[100]
                                                  : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      DateFormat('dd').format(tanggal),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: isOngoing
                                            ? Colors.blue[700]
                                            : isFinished
                                                ? Colors.grey[700]
                                                : isBooked
                                                    ? Colors.orange[700]
                                                    : isAvailable
                                                        ? Colors.green[700]
                                                        : Colors.grey[700],
                                      ),
                                    ),
                                    Text(
                                      DateFormat('MMM').format(tanggal),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isOngoing
                                            ? Colors.blue[700]
                                            : isFinished
                                                ? Colors.grey[700]
                                                : isBooked
                                                    ? Colors.orange[700]
                                                    : isAvailable
                                                        ? Colors.green[700]
                                                        : Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              title: Text(
                                DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
                                    .format(tanggal),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.access_time,
                                          size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                          '${jadwal['jam_mulai']} - ${jadwal['jam_selesai']}'),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        isOngoing
                                            ? Icons.play_circle_fill
                                            : isFinished
                                                ? Icons.check_circle
                                                : isBooked
                                                    ? Icons.event_busy
                                                    : isAvailable
                                                        ? Icons.event_available
                                                        : Icons.event,
                                        size: 16,
                                        color: isOngoing
                                            ? Colors.blue[700]
                                            : isFinished
                                                ? Colors.grey[700]
                                                : isBooked
                                                    ? Colors.orange[700]
                                                    : isAvailable
                                                        ? Colors.green[700]
                                                        : Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isOngoing
                                            ? 'Sedang Berlangsung'
                                            : isFinished
                                                ? 'Selesai'
                                                : isBooked
                                                    ? 'Sudah Dipesan'
                                                    : isAvailable
                                                        ? 'Tersedia'
                                                        : 'Tidak Aktif',
                                        style: TextStyle(
                                          color: isOngoing
                                              ? Colors.blue[700]
                                              : isFinished
                                                  ? Colors.grey[700]
                                                  : isBooked
                                                      ? Colors.orange[700]
                                                      : isAvailable
                                                          ? Colors.green[700]
                                                          : Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (isBooked &&
                                      jadwal['student_name'] != null &&
                                      jadwal['student_name']
                                          .toString()
                                          .isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.person,
                                            size: 16,
                                            color: Colors.orange[700]),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () {
                                              final roomId =
                                                  '${jadwal['student_uid']}_${currentMentorData['uid']}';
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      ChatRoom(
                                                    roomId: roomId,
                                                    currentUser:
                                                        currentMentorData,
                                                    otherUser: {
                                                      'uid':
                                                          jadwal['student_uid'],
                                                      'nama_lengkap': jadwal[
                                                          'student_name'],
                                                      'email': jadwal[
                                                              'student_email'] ??
                                                          '',
                                                    },
                                                    userType: 'mentor',
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Text(
                                              jadwal['student_name'],
                                              style: TextStyle(
                                                color: Colors.orange[700],
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (jadwal['catatan'] != null &&
                                      jadwal['catatan']
                                          .toString()
                                          .isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.notes,
                                            size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            jadwal['catatan'],
                                            style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return "0";
    double amount = double.parse(value.toString());
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  String _deriveStatus(
      String status, String tanggal, String jamMulai, String jamSelesai) {
    if (status != 'booked') return status;
    try {
      final start = _combineDateTime(tanggal, jamMulai);
      final end = _combineDateTime(tanggal, jamSelesai);
      final now = DateTime.now();

      if (end != null && now.isAfter(end)) return 'finished';
      if (start != null &&
          end != null &&
          now.isAfter(start) &&
          now.isBefore(end)) {
        return 'ongoing';
      }
      return status;
    } catch (_) {
      return status;
    }
  }

  DateTime? _combineDateTime(String dateStr, String timeStr) {
    if (dateStr.isEmpty || timeStr.isEmpty) return null;
    final date = _parseDateFlexible(dateStr);
    if (date == null) return null;

    try {
      final normalizedTime = timeStr.length == 4 ? '0$timeStr' : timeStr;
      final parts = normalizedTime.split(':');
      if (parts.length != 2) return null;
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  DateTime? _parseDateFlexible(String dateStr) {
    // Coba dd-MM-yyyy lalu fallback ke ISO
    for (final pattern in ['dd-MM-yyyy', 'yyyy-MM-dd']) {
      try {
        return DateFormat(pattern).parseStrict(dateStr);
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  Widget _buildMiniStatCard(
      String label, String value, IconData icon, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color[50]!, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color[200]!, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color[400]!, color[600]!],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: label == 'Penghasilan' ? 13 : 22,
                fontWeight: FontWeight.bold,
                color: color[700],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
      String label, IconData icon, MaterialColor color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color[400]!, color[600]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
