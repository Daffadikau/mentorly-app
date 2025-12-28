import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'welcome_page.dart';
import 'session_manager.dart';
import 'detail_mentor_admin.dart';

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
    String uri = "http://localhost/mentorly/get_stats.php";
    try {
      final respon = await http.get(Uri.parse(uri));
      if (respon.statusCode == 200) {
        final data = jsonDecode(respon.body);
        setState(() {
          stats = data;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> loadMentorPending() async {
    setState(() {
      isLoading = true;
    });

    String uri = "http://localhost/mentorly/select_mentor_pending.php";
    try {
      final respon = await http.get(Uri.parse(uri));
      if (respon.statusCode == 200) {
        final data = jsonDecode(respon.body);
        setState(() {
          mentorPending = data;
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

  Future<void> loadMentorVerified() async {
    String uri = "http://localhost/mentorly/select_mentor.php";
    try {
      final respon = await http.get(Uri.parse(uri));
      if (respon.statusCode == 200) {
        final data = jsonDecode(respon.body);
        setState(() {
          mentorVerified = data;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> refreshAll() async {
    await loadStats();
    await loadMentorPending();
    await loadMentorVerified();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Colors.blue[700]),
            const SizedBox(width: 10),
            const Text(
              "Admin Dashboard",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.blue[700]),
            onPressed: refreshAll,
          ),
          PopupMenuButton(
            icon: Icon(Icons.more_vert, color: Colors.blue[700]),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text("Keluar", style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                  onTap: () async {
                    Navigator.pop(context);
                    await SessionManager.logout();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => WelcomePage()),
                      (route) => false,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refreshAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Statistik Platform",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.5,
                children: [
                  _buildStatCard(
                    "Total User",
                    stats['total_user'].toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                  _buildStatCard(
                    "Total Pelajar",
                    stats['total_pelajar'].toString(),
                    Icons.school,
                    Colors.green,
                  ),
                  _buildStatCard(
                    "Total Pengajar",
                    stats['total_pengajar'].toString(),
                    Icons.person,
                    Colors.orange,
                  ),
                  _buildStatCard(
                    "Pending",
                    mentorPending.length.toString(),
                    Icons.pending_actions,
                    Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          showVerified = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color:
                              !showVerified ? Colors.blue[700] : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.blue[700]!,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.pending,
                              color: !showVerified
                                  ? Colors.white
                                  : Colors.blue[700],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Pending (${mentorPending.length})",
                              style: TextStyle(
                                color: !showVerified
                                    ? Colors.white
                                    : Colors.blue[700],
                                fontWeight: FontWeight.bold,
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
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color:
                              showVerified ? Colors.green[700] : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.green[700]!,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: showVerified
                                  ? Colors.white
                                  : Colors.green[700],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Verified (${mentorVerified.length})",
                              style: TextStyle(
                                color: showVerified
                                    ? Colors.white
                                    : Colors.green[700],
                                fontWeight: FontWeight.bold,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color[700], size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color[700],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPendingList() {
    if (mentorPending.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(50),
          child: Column(
            children: [
              Icon(Icons.check_circle_outline, size: 80, color: Colors.grey),
              SizedBox(height: 20),
              Text(
                "Tidak ada mentor yang perlu diverifikasi",
                style: TextStyle(color: Colors.grey, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
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
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(50),
          child: Column(
            children: [
              Icon(Icons.person_off, size: 80, color: Colors.grey),
              SizedBox(height: 20),
              Text(
                "Belum ada mentor terverifikasi",
                style: TextStyle(color: Colors.grey, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
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
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
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
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor:
                    isPending ? Colors.orange[100] : Colors.green[100],
                child: Icon(
                  Icons.person,
                  color: isPending ? Colors.orange[700] : Colors.green[700],
                  size: 30,
                ),
              ),
              const SizedBox(width: 15),
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
                    ),
                    const SizedBox(height: 5),
                    Text(
                      mentor['email'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(Icons.school, size: 14, color: Colors.blue[700]),
                        const SizedBox(width: 5),
                        Text(
                          mentor['keahlian'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isPending ? Colors.orange[50] : Colors.green[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isPending ? "Pending" : "Verified",
                      style: TextStyle(
                        fontSize: 11,
                        color:
                            isPending ? Colors.orange[700] : Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
