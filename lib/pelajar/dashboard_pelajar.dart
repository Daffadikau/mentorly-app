import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'detail_mentor_pelajar.dart';
import 'history_pelajar.dart';
import '../common/chat_list.dart';
import 'profile_pelajar.dart';
import '../common/welcome_page.dart';
import '../utils/session_manager.dart';
import '../utils/clear_bookings.dart';
import '../services/session_reminder_service.dart';
import '../widgets/cached_circle_avatar.dart';

class DashboardPelajar extends StatefulWidget {
  final Map<String, dynamic> userData;

  const DashboardPelajar({super.key, required this.userData});

  @override
  _DashboardPelajarState createState() => _DashboardPelajarState();
}

class _DashboardPelajarState extends State<DashboardPelajar> {
  List mentorList = [];
  List filteredMentorList = [];
  String selectedTab = "Semua";
  int _selectedIndex = 0;
  bool isLoading = true;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadMentors();
    
    // Start session reminder service
    final userId = widget.userData['uid'] ?? widget.userData['id'].toString();
    SessionReminderService.startMonitoring(userId);
    print('🔔 Session reminder service started for user: $userId');
  }

  @override
  void dispose() {
    // Stop session reminder service when leaving dashboard
    SessionReminderService.stopMonitoring();
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadMentors() async {
    setState(() => isLoading = true);

    try {
      print('🔍 Loading mentors from Firebase...');
      final snapshot = await FirebaseDatabase.instance.ref('mentors').get();

      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value;
        List<Map<String, dynamic>> tempList = [];

        if (data is Map) {
          print('📊 Found ${data.length} mentors in Firebase');
          data.forEach((key, value) {
            if (value is Map) {
              final mentor = Map<String, dynamic>.from(value);
              
              // Check if mentor is verified AND active
              final isVerified = mentor['status_verifikasi'] == 'verified';
              final isActive = mentor['is_active'] == '1' || mentor['is_active'] == 1 || mentor['is_active'] == true;
              
              if (isVerified && isActive) {
                mentor['id'] = key;
                mentor['uid'] = key;
                tempList.add(mentor);
                print('  ✓ Loaded: ${mentor['nama_lengkap']} (verified & active)');
              } else {
                print('  ✗ Skipped: ${mentor['nama_lengkap']} (verified: $isVerified, active: $isActive)');
              }
            }
          });
        }

        print('✅ Total active & verified mentors: ${tempList.length}');
        setState(() {
          mentorList = tempList;
          filteredMentorList = tempList;
          isLoading = false;
        });
      } else {
        print('⚠️ No mentors found in Firebase');
        setState(() {
          mentorList = [];
          filteredMentorList = [];
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading mentors: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void filterMentors(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredMentorList = mentorList;
      } else {
        filteredMentorList = mentorList.where((mentor) {
          return (mentor['nama_lengkap'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              (mentor['bidang_keahlian'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void filterByCategory(String category) {
    setState(() {
      selectedTab = category;
      if (category == "Semua") {
        filteredMentorList = mentorList;
      } else if (category == "Rating") {
        filteredMentorList = List.from(mentorList)
          ..sort((a, b) => 5.compareTo(5));
      } else if (category == "Harga") {
        filteredMentorList = List.from(mentorList)
          ..sort((a, b) {
            double priceA =
                double.tryParse((a['harga_per_jam'] ?? 0).toString()) ?? 20000;
            double priceB =
                double.tryParse((b['harga_per_jam'] ?? 0).toString()) ?? 20000;
            return priceA.compareTo(priceB);
          });
      } else {
        filteredMentorList = mentorList.where((mentor) {
          return (mentor['bidang_keahlian'] ?? '')
              .toString()
              .toLowerCase()
              .contains(category.toLowerCase());
        }).toList();
      }
    });
  }

  void _onNavBarTap(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HistoryPelajar(pelajarData: widget.userData),
        ),
      ).then((_) {
        setState(() {
          _selectedIndex = 0;
        });
      });
    } else if (index == 2) {
      // NAVIGASI YANG BENAR KE LIST CHAT PAGE
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatListPage(
            userData: widget.userData,
            userType: 'pelajar',
          ),
        ),
      ).then((_) {
        setState(() {
          _selectedIndex = 0;
        });
      });
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfilePelajar(pelajarData: widget.userData),
        ),
      ).then((_) async {
        // Reload session data after returning from profile
        final userData = await SessionManager.getUserData();
        if (userData != null) {
          setState(() {
            widget.userData.addAll(userData);
            _selectedIndex = 0;
          });
        } else {
          setState(() {
            _selectedIndex = 0;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Watermark logo Mentorly
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(top: 120),
                child: Opacity(
                  opacity: 0.05,
                  child: Image.asset(
                    'assets/images/logot.png',
                    width: 300,
                    height: 300,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "Selamat Datang, ${widget.userData['nama_lengkap'] ?? 'Pelajar'}.",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_forever,
                            color: Colors.orange),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ClearBookingsUtility(),
                            ),
                          );
                        },
                        tooltip: 'Clear Bookings',
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.red),
                        onPressed: () async {
                          await SessionManager.logout();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const WelcomePage(),
                            ),
                            (route) => false,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: searchController,
                    onChanged: filterMentors,
                    decoration: InputDecoration(
                      hintText: "Cari Mentor / Bidang",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                  const SizedBox(height: 15),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildTab("Semua"),
                        const SizedBox(width: 10),
                        _buildTab("Rating"),
                        const SizedBox(width: 10),
                        _buildTab("IPA"),
                        const SizedBox(width: 10),
                        _buildTab("IPS"),
                        const SizedBox(width: 10),
                        _buildTab("Matematika"),
                        const SizedBox(width: 10),
                        _buildTab("Harga"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredMentorList.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off,
                                  size: 80, color: Colors.grey),
                              SizedBox(height: 20),
                              Text(
                                "Mentor tidak ditemukan",
                                style:
                                    TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: loadMentors,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: filteredMentorList.length,
                            itemBuilder: (context, index) {
                              var mentor = filteredMentorList[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DetailMentor(
                                        mentorData: mentor,
                                        pelajarData: widget.userData,
                                      ),
                                    ),
                                  );
                                },
                                child: Card(
                                  margin: const EdgeInsets.only(bottom: 15),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(15),
                                    child: Row(
                                      children: [
                                        CachedCircleAvatar(
                                          imageUrl: mentor['profile_photo_url'],
                                          radius: 30,
                                          backgroundColor: Colors.blue[100],
                                          iconColor: Colors.blue[700],
                                        ),
                                        const SizedBox(width: 15),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                mentor['nama_lengkap'] ??
                                                    'Nama tidak tersedia',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                "Rp ${_formatCurrency(mentor['harga_per_jam'])} / jam",
                                                style: const TextStyle(
                                                  color: Colors.orange,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                mentor['bidang_keahlian'] ??
                                                    'Bidang tidak tersedia',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: mentor['is_active'] == '1'
                                                ? Colors.green[100]
                                                : Colors.grey[200],
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              CircleAvatar(
                                                radius: 4,
                                                backgroundColor:
                                                    mentor['is_active'] == '1'
                                                        ? Colors.green
                                                        : Colors.grey,
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                mentor['is_active'] == '1'
                                                    ? "Online"
                                                    : "Offline",
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color:
                                                      mentor['is_active'] == '1'
                                                          ? Colors.green[700]
                                                          : Colors.grey[600],
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue[700],
        unselectedItemColor: Colors.grey,
        onTap: _onNavBarTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title) {
    bool isSelected = selectedTab == title;
    return GestureDetector(
      onTap: () => filterByCategory(title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[700] : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return "20.000";
    double amount = double.tryParse(value.toString()) ?? 20000;
    if (amount == 0) amount = 20000;
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }
}
