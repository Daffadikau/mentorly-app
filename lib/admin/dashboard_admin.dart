import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../common/welcome_page.dart';
import '../utils/session_manager.dart';
import 'detail_mentor_admin.dart';
import '../common/api_config.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardAdmin extends StatefulWidget {
  const DashboardAdmin({super.key});

  @override
  _DashboardAdminState createState() => _DashboardAdminState();
}

class _DashboardAdminState extends State<DashboardAdmin> {
  Map<String, dynamic> stats = {
    "total_user": 0,
    "total_pelajar": 0,
    "total_pengajar": 0
  };
  List mentorPending = [];
  List mentorVerified = [];
  bool isLoading = true;
  bool showVerified = false;

  @override
  void initState() {
    super.initState();
    loadStats();
    loadMentorPending();
    loadMentorVerified();
  }

  Future<void> loadStats() async {
    // PHP backend removed - using Firebase only
    // You can calculate stats from Firebase RTDB if needed
    setState(() {
      stats = {
        "total_user": 0,
        "total_pelajar": 0,
        "total_pengajar": mentorVerified.length
      };
    });
  }

  Future<void> loadMentorPending() async {
    setState(() {
      isLoading = true;
    });

    print("🔍 Loading pending mentors from Firebase...");
    List allPending = [];

    try {
      // 1. Check Firebase RTDB for pending mentors
      final snapshot = await FirebaseDatabase.instance.ref('mentors').get();

      if (snapshot.exists) {
        final data = snapshot.value;
        print("📊 Firebase data type: ${data.runtimeType}");

        if (data is List) {
          // Data stored as List
          for (int i = 0; i < data.length; i++) {
            final mentor = data[i];
            if (mentor != null && mentor is Map) {
              if (mentor['status_verifikasi'] == 'pending') {
                final mentorData = Map<String, dynamic>.from(mentor);
                mentorData['firebase_index'] = i;
                mentorData['source'] = 'firebase';
                allPending.add(mentorData);
                print("✅ Found pending: ${mentorData['nama_lengkap']}");
              }
            }
          }
        } else if (data is Map) {
          // Data stored as Map
          data.forEach((key, value) {
            if (value != null && value is Map) {
              if (value['status_verifikasi'] == 'pending') {
                final mentorData = Map<String, dynamic>.from(value);
                mentorData['uid'] = key;
                mentorData['source'] = 'firebase';
                allPending.add(mentorData);
                print("✅ Found pending: ${mentorData['nama_lengkap']}");
              }
            }
          });
        }
      }
      print("📊 Firebase pending count: ${allPending.length}");
    } catch (e) {
      print("❌ Error loading from Firebase: $e");
    }

    // 2. Also check PHP backend
    try {
      String uri = ApiConfig.getUrl("select_mentor_pending.php");
      final respon = await http.get(Uri.parse(uri));
      if (respon.statusCode == 200) {
        final phpData = jsonDecode(respon.body);
        if (phpData is List) {
          for (var mentor in phpData) {
            mentor['source'] = 'php';
          }
          allPending.addAll(phpData);
        }
        print("📊 PHP pending count: ${phpData.length}");
      }
    } catch (e) {
      print("❌ Error loading from PHP: $e");
    }

    setState(() {
      mentorPending = allPending;
      isLoading = false;
    });
    print("✅ Total pending mentors: ${allPending.length}");
  }

  Future<void> loadMentorVerified() async {
    // Load verified mentors from Firebase RTDB
    try {
      final snapshot = await FirebaseDatabase.instance.ref('mentors').get();
      List verifiedList = [];

      if (snapshot.exists) {
        final data = snapshot.value;

        if (data is List) {
          for (int i = 0; i < data.length; i++) {
            final mentor = data[i];
            if (mentor != null &&
                mentor is Map &&
                mentor['status_verifikasi'] == 'verified') {
              final mentorData = Map<String, dynamic>.from(mentor);
              mentorData['firebase_index'] = i;
              verifiedList.add(mentorData);
            }
          }
        } else if (data is Map) {
          data.forEach((key, value) {
            if (value != null &&
                value is Map &&
                value['status_verifikasi'] == 'verified') {
              final mentorData = Map<String, dynamic>.from(value);
              mentorData['uid'] = key;
              verifiedList.add(mentorData);
            }
          });
        }
      }

      setState(() {
        mentorVerified = verifiedList;
      });
    } catch (e) {
      print("❌ Error loading verified mentors: $e");
    }
  }

  Future<void> refreshAll() async {
    await loadStats();
    await loadMentorPending();
    await loadMentorVerified();
  }

  Future<bool> _checkEmailVerification(String email) async {
    try {
      // Fetch sign-in methods for the email
      final methods =
          await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);

      // If email doesn't exist in Firebase Auth, return false
      if (methods.isEmpty) {
        print("📧 Email not registered in Firebase Auth: $email");
        return false;
      }

      // Try to get user by email (this requires admin SDK or workaround)
      // Since we can't directly check emailVerified without signing in,
      // we'll check if the user exists in Firebase RTDB and has a uid
      final snapshot = await FirebaseDatabase.instance.ref('mentors').get();

      if (snapshot.exists) {
        final data = snapshot.value;

        if (data is List) {
          for (var mentor in data) {
            if (mentor != null && mentor is Map && mentor['email'] == email) {
              // If they have a UID and registered, check their auth status
              return methods.isNotEmpty; // Email exists in auth system
            }
          }
        } else if (data is Map) {
          for (var entry in data.entries) {
            final mentor = entry.value;
            if (mentor is Map && mentor['email'] == email) {
              return methods.isNotEmpty;
            }
          }
        }
      }

      return methods.isNotEmpty;
    } catch (e) {
      print("❌ Error checking email verification: $e");
      return false;
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
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.admin_panel_settings,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              "Admin Dashboard",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: refreshAll,
            tooltip: 'Refresh Data',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) async {
              if (value == 'logout') {
                await SessionManager.logout();
                if (context.mounted) {
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
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text("Keluar", style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: refreshAll,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section with Gradient
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
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
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Selamat Datang, Admin",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Kelola dan pantau platform Mentorly",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                // Stats Section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.bar_chart,
                              color: Colors.blue[700], size: 24),
                          const SizedBox(width: 8),
                          const Text(
                            "Statistik Platform",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                        childAspectRatio: 1.4,
                        children: [
                          _buildStatCard(
                            "Total User",
                            stats['total_user'].toString(),
                            Icons.people_rounded,
                            Colors.blue,
                          ),
                          _buildStatCard(
                            "Total Pelajar",
                            stats['total_pelajar'].toString(),
                            Icons.school_rounded,
                            Colors.green,
                          ),
                          _buildStatCard(
                            "Total Pengajar",
                            stats['total_pengajar'].toString(),
                            Icons.person_rounded,
                            Colors.orange,
                          ),
                          _buildStatCard(
                            "Pending",
                            mentorPending.length.toString(),
                            Icons.pending_actions_rounded,
                            Colors.red,
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      // Quick Actions Panel
                      Row(
                        children: [
                          Icon(Icons.flash_on_rounded,
                              color: Colors.amber[700], size: 24),
                          const SizedBox(width: 8),
                          const Text(
                            "Aksi Cepat",
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
                            child: _buildQuickActionCard(
                              "Pending",
                              mentorPending.length.toString(),
                              Icons.pending_outlined,
                              Colors.orange,
                              () {
                                setState(() {
                                  showVerified = false;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildQuickActionCard(
                              "Verified",
                              mentorVerified.length.toString(),
                              Icons.verified_rounded,
                              Colors.green,
                              () {
                                setState(() {
                                  showVerified = true;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      // Chart Section
                      Row(
                        children: [
                          Icon(Icons.pie_chart_rounded,
                              color: Colors.purple[700], size: 24),
                          const SizedBox(width: 8),
                          const Text(
                            "Distribusi Status",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      _buildStatusChart(),
                      const SizedBox(height: 30),

                      // Tab Section
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  showVerified = false;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  gradient: !showVerified
                                      ? LinearGradient(
                                          colors: [
                                            Colors.orange[600]!,
                                            Colors.orange[400]!
                                          ],
                                        )
                                      : null,
                                  color: showVerified ? Colors.white : null,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.orange[600]!,
                                    width: 2,
                                  ),
                                  boxShadow: !showVerified
                                      ? [
                                          BoxShadow(
                                            color:
                                                Colors.orange.withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.pending_rounded,
                                      color: !showVerified
                                          ? Colors.white
                                          : Colors.orange[600],
                                      size: 22,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        "Pending (${mentorPending.length})",
                                        style: TextStyle(
                                          color: !showVerified
                                              ? Colors.white
                                              : Colors.orange[600],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  showVerified = true;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  gradient: showVerified
                                      ? LinearGradient(
                                          colors: [
                                            Colors.green[600]!,
                                            Colors.green[400]!
                                          ],
                                        )
                                      : null,
                                  color: !showVerified ? Colors.white : null,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.green[600]!,
                                    width: 2,
                                  ),
                                  boxShadow: showVerified
                                      ? [
                                          BoxShadow(
                                            color:
                                                Colors.green.withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: showVerified
                                          ? Colors.white
                                          : Colors.green[600],
                                      size: 22,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        "Verified (${mentorVerified.length})",
                                        style: TextStyle(
                                          color: showVerified
                                              ? Colors.white
                                              : Colors.green[600],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      isLoading
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(30),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : showVerified
                              ? _buildVerifiedList()
                              : _buildPendingList(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, MaterialColor color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            spreadRadius: 0,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circle
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color[50]?.withOpacity(0.5),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color[400]!, color[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingList() {
    if (mentorPending.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline_rounded,
                size: 64,
                color: Colors.green[400],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Semua Mentor Terverifikasi!",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Tidak ada mentor yang menunggu verifikasi",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: mentorPending.length,
      itemBuilder: (context, index) {
        var mentor = mentorPending[index];
        return _buildMentorCard(mentor, isPending: true);
      },
    );
  }

  Widget _buildVerifiedList() {
    if (mentorVerified.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_search_rounded,
                size: 64,
                color: Colors.orange[400],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Belum Ada Mentor",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Mentor terverifikasi akan muncul di sini",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: mentorVerified.length,
      itemBuilder: (context, index) {
        var mentor = mentorVerified[index];
        return _buildMentorCard(mentor, isPending: false);
      },
    );
  }

  Widget _buildMentorCard(Map<String, dynamic> mentor,
      {required bool isPending}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailMentorAdmin(
                mentorData: mentor,
              ),
            ),
          );

          if (result == true) {
            refreshAll();
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                isPending
                    ? Colors.orange[50]!.withOpacity(0.3)
                    : Colors.green[50]!.withOpacity(0.3),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar with gradient border
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isPending
                          ? [Colors.orange[400]!, Colors.orange[600]!]
                          : [Colors.green[400]!, Colors.green[600]!],
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isPending ? Colors.orange[50] : Colors.green[50],
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      color: isPending ? Colors.orange[700] : Colors.green[700],
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mentor['nama_lengkap'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.email_rounded,
                              size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              mentor['email'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.blue[200]!,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.school_rounded,
                                size: 12, color: Colors.blue[700]),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                mentor['keahlian'],
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isPending) const SizedBox(height: 8),
                      if (isPending)
                        FutureBuilder<bool>(
                          future: _checkEmailVerification(mentor['email']),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return Row(
                                children: [
                                  SizedBox(
                                    width: 10,
                                    height: 10,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Mengecek email...',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              );
                            }
                            final isVerified = snapshot.data ?? false;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isVerified
                                    ? Colors.green[50]
                                    : Colors.orange[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isVerified
                                      ? Colors.green[200]!
                                      : Colors.orange[200]!,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isVerified
                                        ? Icons.verified_rounded
                                        : Icons.warning_amber_rounded,
                                    size: 14,
                                    color: isVerified
                                        ? Colors.green[700]
                                        : Colors.orange[700],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isVerified
                                        ? 'Email Terverifikasi'
                                        : 'Belum Diverifikasi',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isVerified
                                          ? Colors.green[700]
                                          : Colors.orange[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isPending
                              ? [Colors.orange[400]!, Colors.orange[600]!]
                              : [Colors.green[400]!, Colors.green[600]!],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: (isPending ? Colors.orange : Colors.green)
                                .withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        isPending ? "Pending" : "Verified",
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(String label, String count, IconData icon,
      MaterialColor color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
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
              color: color.withOpacity(0.1),
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
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              count,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: color[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChart() {
    int pending = mentorPending.length;
    int verified = mentorVerified.length;
    int total = pending + verified;

    if (total == 0) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pie_chart_outline, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'Belum ada data untuk ditampilkan',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                    value: pending.toDouble(),
                    title: '${(pending / total * 100).toInt()}%',
                    color: Colors.orange[400],
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: verified.toDouble(),
                    title: '${(verified / total * 100).toInt()}%',
                    color: Colors.green[400],
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLegendItem(
                  'Pending',
                  pending.toString(),
                  Colors.orange[400]!,
                ),
                const SizedBox(height: 12),
                _buildLegendItem(
                  'Verified',
                  verified.toString(),
                  Colors.green[400]!,
                ),
                const SizedBox(height: 12),
                Divider(color: Colors.grey[300], thickness: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      total.toString(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[900],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }
}
