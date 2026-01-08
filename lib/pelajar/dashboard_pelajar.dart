import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'detail_mentor_pelajar.dart';
import 'history_pelajar.dart';
import '../common/chat_list.dart';
import 'profile_pelajar.dart';
import '../common/welcome_page.dart';
import '../utils/session_manager.dart';
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
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
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
    _pageController.dispose();
    super.dispose();
  }

  Future<void> loadMentors() async {
    setState(() => isLoading = true);

    try {
      print('🔍 Loading mentors from Firebase...');
      final mentorSnapshot =
          await FirebaseDatabase.instance.ref('mentors').get();
      final kelasSnapshot = await FirebaseDatabase.instance.ref('kelas').get();

      // Load all kelas first
      Map<String, List<String>> mentorKelasMap = {};
      if (kelasSnapshot.exists && kelasSnapshot.value != null) {
        final kelasData = kelasSnapshot.value;
        if (kelasData is Map) {
          kelasData.forEach((key, value) {
            if (value is Map) {
              final kelas = Map<String, dynamic>.from(value);
              if (kelas['status'] == 'active') {
                final mentorUid = kelas['mentor_uid'];
                final category = (kelas['category'] ?? '').toString();
                if (mentorUid != null && category.isNotEmpty) {
                  if (!mentorKelasMap.containsKey(mentorUid)) {
                    mentorKelasMap[mentorUid] = [];
                  }
                  mentorKelasMap[mentorUid]!.add(category);
                }
              }
            }
          });
        }
      }
      print('📚 Loaded kelas for ${mentorKelasMap.length} mentors');

      if (mentorSnapshot.exists && mentorSnapshot.value != null) {
        final data = mentorSnapshot.value;
        List<Map<String, dynamic>> tempList = [];

        if (data is Map) {
          print('📊 Found ${data.length} mentors in Firebase');
          data.forEach((key, value) {
            if (value is Map) {
              final mentor = Map<String, dynamic>.from(value);

              // Check if mentor is verified AND active
              final isVerified = mentor['status_verifikasi'] == 'verified';
              final isActive = mentor['is_active'] == '1' ||
                  mentor['is_active'] == 1 ||
                  mentor['is_active'] == true;

              if (isVerified && isActive) {
                mentor['id'] = key;
                mentor['uid'] = key;
                // Add kelas categories to mentor data
                mentor['kelas_categories'] = mentorKelasMap[key] ?? [];
                tempList.add(mentor);
                print(
                    '  ✓ Loaded: ${mentor['nama_lengkap']} (verified & active) - Kelas: ${mentor['kelas_categories']}');
              } else {
                print(
                    '  ✗ Skipped: ${mentor['nama_lengkap']} (verified: $isVerified, active: $isActive)');
              }
            }
          });
        }

        // Load real ratings from bookings
        print('📊 Calculating real ratings from bookings...');
        final bookingsSnapshot = await FirebaseDatabase.instance.ref('bookings').get();
        if (bookingsSnapshot.exists) {
          Map<String, List<double>> mentorRatings = {};
          
          final bookingsData = bookingsSnapshot.value as Map<dynamic, dynamic>;
          for (var entry in bookingsData.entries) {
            final booking = entry.value as Map<dynamic, dynamic>;
            final mentorId = booking['mentor_id']?.toString() ?? '';
            final rating = booking['rating'];
            
            if (mentorId.isNotEmpty && rating != null) {
              final ratingValue = double.tryParse(rating.toString()) ?? 0;
              if (ratingValue > 0) {
                if (!mentorRatings.containsKey(mentorId)) {
                  mentorRatings[mentorId] = [];
                }
                mentorRatings[mentorId]!.add(ratingValue);
              }
            }
          }
          
          // Update mentor ratings
          for (var mentor in tempList) {
            final mentorId = mentor['uid'] ?? mentor['id'];
            if (mentorRatings.containsKey(mentorId)) {
              final ratings = mentorRatings[mentorId]!;
              final avgRating = ratings.reduce((a, b) => a + b) / ratings.length;
              mentor['rating'] = avgRating;
              print('  📊 ${mentor['nama_lengkap']}: ${avgRating.toStringAsFixed(2)} (${ratings.length} reviews)');
            } else {
              mentor['rating'] = 0;
            }
          }
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
      } else if (category == "⭐ Rating Tertinggi") {
        filteredMentorList = List.from(mentorList)
          ..sort((a, b) {
            double ratingA =
                double.tryParse((a['rating'] ?? 0).toString()) ?? 0;
            double ratingB =
                double.tryParse((b['rating'] ?? 0).toString()) ?? 0;
            return ratingB.compareTo(ratingA); // Descending order
          });
      } else if (category == "💰 Harga Termurah") {
        filteredMentorList = List.from(mentorList)
          ..sort((a, b) {
            double priceA =
                double.tryParse((a['harga_per_jam'] ?? 0).toString()) ?? 20000;
            double priceB =
                double.tryParse((b['harga_per_jam'] ?? 0).toString()) ?? 20000;
            return priceA.compareTo(priceB);
          });
      } else {
        // Filter by subject - check both bidang_keahlian and kelas categories
        filteredMentorList = mentorList.where((mentor) {
          String bidang =
              (mentor['bidang_keahlian'] ?? '').toString().toLowerCase();
          List<String> kelasCategories =
              (mentor['kelas_categories'] as List<dynamic>?)
                      ?.map((e) => e.toString().toLowerCase())
                      .toList() ??
                  [];

          String searchCategory = category.toLowerCase();

          // Remove emoji from category for matching
          searchCategory =
              searchCategory.replaceAll(RegExp(r'[^\w\s]'), '').trim();

          // Check if any kelas category matches
          bool kelasMatches = kelasCategories.any((kelasCategory) {
            if (searchCategory.contains('sosial') ||
                searchCategory.contains('ips')) {
              return kelasCategory.contains('sosial') ||
                  kelasCategory.contains('ips');
            }
            if (searchCategory.contains('sains') ||
                searchCategory.contains('ipa')) {
              return kelasCategory.contains('sains') ||
                  kelasCategory.contains('ipa');
            }
            if (searchCategory.contains('inggris') ||
                searchCategory.contains('english')) {
              return kelasCategory.contains('inggris') ||
                  kelasCategory.contains('english');
            }
            if (searchCategory.contains('indonesia')) {
              return kelasCategory.contains('indonesia') ||
                  kelasCategory.contains('bahasa');
            }
            if (searchCategory.contains('program')) {
              return kelasCategory.contains('program') ||
                  kelasCategory.contains('coding') ||
                  kelasCategory.contains('komputer');
            }
            return kelasCategory.contains(searchCategory);
          });

          // Check bidang_keahlian as well
          bool bidangMatches = false;
          if (searchCategory.contains('sosial') ||
              searchCategory.contains('ips')) {
            bidangMatches = bidang.contains('sosial') || bidang.contains('ips');
          } else if (searchCategory.contains('sains') ||
              searchCategory.contains('ipa')) {
            bidangMatches = bidang.contains('sains') || bidang.contains('ipa');
          } else if (searchCategory.contains('inggris') ||
              searchCategory.contains('english')) {
            bidangMatches =
                bidang.contains('inggris') || bidang.contains('english');
          } else if (searchCategory.contains('indonesia')) {
            bidangMatches =
                bidang.contains('indonesia') || bidang.contains('bahasa');
          } else if (searchCategory.contains('program')) {
            bidangMatches = bidang.contains('program') ||
                bidang.contains('coding') ||
                bidang.contains('komputer');
          } else {
            bidangMatches = bidang.contains(searchCategory);
          }

          // Return true if either bidang or any kelas matches
          return bidangMatches || kelasMatches;
        }).toList();
      }
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Filter Mentor",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Filter content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sorting Section
                    _buildFilterSection(
                      "Urutkan Berdasarkan",
                      [
                        _buildFilterChip("⭐ Rating Tertinggi", Icons.star),
                        _buildFilterChip(
                            "💰 Harga Termurah", Icons.attach_money),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Subjects Section
                    _buildFilterSection(
                      "Mata Pelajaran",
                      [
                        _buildFilterChip("📐 Matematika", Icons.calculate),
                        _buildFilterChip("⚗️ Fisika", Icons.science),
                        _buildFilterChip("🧪 Kimia", Icons.biotech),
                        _buildFilterChip("🧬 Biologi", Icons.eco),
                        _buildFilterChip(
                            "🏛️ IPS (Sosial)", Icons.account_balance),
                        _buildFilterChip("💼 Ekonomi", Icons.business),
                        _buildFilterChip("🌍 Geografi", Icons.public),
                        _buildFilterChip("📜 Sejarah", Icons.history_edu),
                        _buildFilterChip("👥 Sosiologi", Icons.groups),
                        _buildFilterChip("🗣️ Bahasa Inggris", Icons.language),
                        _buildFilterChip("📝 Bahasa Indonesia", Icons.book),
                        _buildFilterChip("💻 Programming", Icons.computer),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(String title, List<Widget> filters) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: filters,
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    bool isSelected = selectedTab == label;
    return GestureDetector(
      onTap: () {
        filterByCategory(label);
        Navigator.pop(context);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [Colors.blue[700]!, Colors.blue[500]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue[700]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onNavBarTap(int index) {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          // Halaman 0: Beranda
          _buildBerandaPage(),
          // Halaman 1: Riwayat
          HistoryPelajar(pelajarData: widget.userData),
          // Halaman 2: Chat
          ChatListPage(
            userData: widget.userData,
            userType: 'pelajar',
          ),
          // Halaman 3: Profil
          Builder(
            builder: (context) => ProfilePelajar(pelajarData: widget.userData),
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

  Widget _buildBerandaPage() {
    return Stack(
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
                    Row(
                      children: [
                        // Filter Button
                        GestureDetector(
                          onTap: _showFilterBottomSheet,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue[700]!, Colors.blue[500]!],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.filter_list,
                                    color: Colors.white, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  "Filter",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Quick filters
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildTab("Semua"),
                                const SizedBox(width: 8),
                                _buildTab("⭐ Rating Tertinggi"),
                                const SizedBox(width: 8),
                                _buildTab("💰 Harga Termurah"),
                              ],
                            ),
                          ),
                        ),
                      ],
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
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: loadMentors,
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
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
                                            imageUrl:
                                                mentor['profile_photo_url'],
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
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Row(
                                                        children: [
                                                          // Rating stars
                                                          ..._buildRatingStars(
                                                            double.tryParse(
                                                                    (mentor['rating'] ??
                                                                            0)
                                                                        .toString()) ??
                                                                0,
                                                            size: 14,
                                                          ),
                                                          const SizedBox(
                                                              width: 6),
                                                          Text(
                                                            "${(double.tryParse((mentor['rating'] ?? 0).toString()) ?? 0).toStringAsFixed(1)}",
                                                            style:
                                                                const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontSize: 13,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 5),
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
                                                        mentor['is_active'] ==
                                                                '1'
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
    );
  }

  Widget _buildTab(String title) {
    bool isSelected = selectedTab == title;
    return GestureDetector(
      onTap: () => filterByCategory(title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [Colors.blue[700]!, Colors.blue[500]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.grey[200],
          borderRadius: BorderRadius.circular(25),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
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

  List<Widget> _buildRatingStars(double rating, {double size = 16}) {
    List<Widget> stars = [];
    int fullStars = rating.floor(); // Get integer part
    double decimalPart = rating - fullStars;
    bool hasHalfStar = decimalPart >= 0.5; // Half star only if >= 0.5

    // Add full stars
    for (int i = 0; i < fullStars; i++) {
      stars.add(
        Icon(
          Icons.star,
          color: Colors.amber[700],
          size: size,
        ),
      );
    }

    // Add half star if needed
    if (hasHalfStar && fullStars < 5) {
      stars.add(
        Icon(
          Icons.star_half,
          color: Colors.amber[700],
          size: size,
        ),
      );
      fullStars += 1;
    }

    // Add empty stars to complete 5 stars
    for (int i = fullStars; i < 5; i++) {
      stars.add(
        Icon(
          Icons.star_outline,
          color: Colors.amber[300],
          size: size,
        ),
      );
    }
    return stars;
  }
}
