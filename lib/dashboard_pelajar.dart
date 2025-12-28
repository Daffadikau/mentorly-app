import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'detail_mentor_pelajar.dart';
import 'history_pelajar.dart';
import 'list_chat_page.dart';
import 'profile_pelajar.dart';
import 'welcome_page.dart';
import 'session_manager.dart';

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
  }

  Future<void> loadMentors() async {
    String uri = "http://localhost/mentorly/select_mentor.php";
    try {
      final respon = await http.get(Uri.parse(uri));
      if (respon.statusCode == 200) {
        final data = jsonDecode(respon.body);
        setState(() {
          mentorList = data;
          filteredMentorList = data;
          isLoading = false;
        });
      }
    } catch (e) {
      print(e);
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
          return mentor['nama_lengkap']
                  .toString()
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              mentor['keahlian']
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
                double.tryParse(a['total_penghasilan'].toString()) ?? 20000;
            double priceB =
                double.tryParse(b['total_penghasilan'].toString()) ?? 20000;
            return priceA.compareTo(priceB);
          });
      } else {
        filteredMentorList = mentorList.where((mentor) {
          return mentor['keahlian']
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
          builder: (context) => ListChatPage(pelajarData: widget.userData),
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
      ).then((_) {
        setState(() {
          _selectedIndex = 0;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
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
                          "Selamat Datang, ${widget.userData['nama']}.",
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
                              builder: (context) => WelcomePage(),
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
                                        CircleAvatar(
                                          radius: 30,
                                          backgroundColor: Colors.blue[100],
                                          child: Icon(
                                            Icons.person,
                                            color: Colors.blue[700],
                                            size: 30,
                                          ),
                                        ),
                                        const SizedBox(width: 15),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                mentor['nama_lengkap'],
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                "Rp ${_formatCurrency(mentor['total_penghasilan'])} / jam",
                                                style: const TextStyle(
                                                  color: Colors.orange,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                mentor['keahlian'],
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

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
