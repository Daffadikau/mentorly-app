import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../common/welcome_page.dart';
import '../utils/session_manager.dart';
import 'profile_mentor.dart';

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

  @override
  void initState() {
    super.initState();
    currentMentorData = widget.mentorData;
    isActive = currentMentorData['is_active'] == '1';
    loadJadwal();
  }

  Future<void> loadJadwal() async {
    // GANTI URL INI SESUAI DEVICE KAMU!
    String uri = "http://localhost/mentorly/select_jadwal.php";
    var response = await http.post(
      Uri.parse(uri),
      body: {"itemmentorid": currentMentorData['id'].toString()},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        jadwalList = data;
      });
    }
  }

  Future<void> tarikDana() async {
    if (double.parse(currentMentorData['total_penghasilan'].toString()) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Saldo tidak mencukupi untuk penarikan")),
      );
      return;
    }

    // GANTI URL INI SESUAI DEVICE KAMU!
    String uri = "http://localhost/mentorly/tarik_dana.php";
    var response = await http.post(
      Uri.parse(uri),
      body: {
        "itemmentorid": currentMentorData['id'].toString(),
        "itemjumlah": currentMentorData['total_penghasilan'].toString(),
      },
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Dana berhasil ditarik dan sedang diproses")),
        );

        setState(() {
          currentMentorData['dana_proses'] =
              (double.parse(currentMentorData['dana_proses'].toString()) +
                      double.parse(
                        currentMentorData['total_penghasilan'].toString(),
                      ))
                  .toString();
          currentMentorData['total_penghasilan'] = '0';
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(data['message'])));
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
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            "Semua Jadwal",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 10),
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
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[700]!, Colors.blue[500]!],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Total Penghasilan",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Rp. ${_formatCurrency(currentMentorData['total_penghasilan'])}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: tarikDana,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        "Tarik Dana",
                        style: TextStyle(color: Colors.blue[700]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Dana di Proses",
                            style: TextStyle(fontSize: 16)),
                        const SizedBox(height: 5),
                        Text(
                          "Rp. ${_formatCurrency(currentMentorData['dana_proses'])}",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Dana sedang dalam proses transfer ke rekening Anda",
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        "Batalkan",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Jadwal Mengajar",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      decoration: InputDecoration(
                        hintText: "Cari jadwal",
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
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
                              return Card(
                                margin: const EdgeInsets.only(bottom: 15),
                                child: ListTile(
                                  leading: Icon(
                                    Icons.calendar_today,
                                    color: Colors.blue[700],
                                  ),
                                  title: Text(
                                    jadwal['mata_pelajaran'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "${jadwal['tanggal']} • ${jadwal['waktu']}",
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(20),
                child: FloatingActionButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Fitur tambah jadwal akan segera hadir"),
                      ),
                    );
                  },
                  backgroundColor: Colors.blue[700],
                  child: const Icon(Icons.add, color: Colors.white),
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
          if (index == 3) {
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
          BottomNavigationBarItem(icon: Icon(Icons.history), label: ''),
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
