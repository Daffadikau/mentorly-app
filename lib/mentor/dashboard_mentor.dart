import 'package:flutter/material.dart';
import 'dart:convert';
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

  @override
  void initState() {
    super.initState();
    currentMentorData = widget.mentorData;
    isActive = currentMentorData['is_active'] == '1';
    loadJadwal();
    _loadMentorBalance();
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

            // Jika jadwal sudah di-booking, ambil data pelajar
            if (jadwalData['status'] == 'booked' && jadwalData['booked_by'].toString().isNotEmpty) {
              try {
                final studentSnapshot = await _database
                    .child('pelajar')
                    .child(jadwalData['booked_by'])
                    .get();
                
                if (studentSnapshot.exists) {
                  final studentData = studentSnapshot.value as Map<dynamic, dynamic>;
                  jadwalData['student_name'] = studentData['nama_lengkap'] ?? studentData['email'] ?? 'Pelajar';
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
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
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 5,
                                backgroundColor:
                                    isActive ? Colors.green : Colors.grey,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                isActive ? "Active" : "Non Active",
                                style: TextStyle(
                                  color: isActive ? Colors.green : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
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
                                mentorName:
                                    currentMentorData['nama_lengkap'],
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
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => JadwalMentor(
                                    mentorData: currentMentorData,
                                  ),
                                ),
                              ).then((_) => loadJadwal());
                            },
                            icon: const Icon(Icons.edit_calendar, size: 18),
                            label: const Text('Jadwal'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[700],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RiwayatMengajar(
                                    mentorData: currentMentorData,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.history_edu, size: 18),
                            label: const Text('Riwayat'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
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
                              final tanggal = DateTime.parse(jadwal['tanggal']);
                              final isBooked = jadwal['status'] == 'booked';
                              final isAvailable = jadwal['status'] == 'available';
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 2,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: isBooked
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
                                            color: isBooked
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
                                            color: isBooked
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
                                    DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(tanggal),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Text('${jadwal['jam_mulai']} - ${jadwal['jam_selesai']}'),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            isBooked
                                                ? Icons.event_busy
                                                : isAvailable
                                                    ? Icons.event_available
                                                    : Icons.event,
                                            size: 16,
                                            color: isBooked
                                                ? Colors.orange[700]
                                                : isAvailable
                                                    ? Colors.green[700]
                                                    : Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            isBooked
                                                ? 'Sudah Dipesan'
                                                : isAvailable
                                                    ? 'Tersedia'
                                                    : 'Tidak Aktif',
                                            style: TextStyle(
                                              color: isBooked
                                                  ? Colors.orange[700]
                                                  : isAvailable
                                                      ? Colors.green[700]
                                                      : Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (isBooked && jadwal['student_name'] != null && jadwal['student_name'].toString().isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.person, size: 16, color: Colors.orange[700]),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () {
                                                  final roomId = '${jadwal['student_uid']}_${currentMentorData['uid']}';
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => ChatRoom(
                                                        roomId: roomId,
                                                        currentUser: currentMentorData,
                                                        otherUser: {
                                                          'uid': jadwal['student_uid'],
                                                          'nama_lengkap': jadwal['student_name'],
                                                          'email': jadwal['student_email'] ?? '',
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
                                                    decoration: TextDecoration.underline,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      if (jadwal['catatan'] != null && jadwal['catatan'].toString().isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.notes, size: 16, color: Colors.grey[600]),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                jadwal['catatan'],
                                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        selectedItemColor: Colors.blue[700],
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 1) {
            // Index 1 adalah icon history
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    TransactionMentor(mentorData: currentMentorData),
              ),
            );
          } else if (index == 2) {
            // Index 2 adalah icon chat
            print('📱 Opening chat list with mentor data:');
            print('   - uid: ${currentMentorData['uid']}');
            print('   - id: ${currentMentorData['id']}');
            print('   - nama: ${currentMentorData['nama_lengkap']}');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatListPage(
                  userData: currentMentorData,
                  userType: 'mentor',
                ),
              ),
            );
          } else if (index == 3) {
            // Index 3 adalah icon person
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ProfileMentor(mentorData: currentMentorData),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
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
}
