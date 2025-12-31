import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'tambah_jadwal_mentor.dart';

import '../common/api_config.dart';

class SemuaJadwalMentor extends StatefulWidget {
  final Map<String, dynamic> mentorData;

  const SemuaJadwalMentor({super.key, required this.mentorData});

  @override
  _SemuaJadwalMentorState createState() => _SemuaJadwalMentorState();
}

class _SemuaJadwalMentorState extends State<SemuaJadwalMentor> {
  List<dynamic> jadwalList = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadJadwal();
  }

  Future<void> loadJadwal() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    String uri = ApiConfig.getUrl('get_jadwal_mentor.php');

    try {
      var response = await http.post(
        Uri.parse(uri),
        body: {"itemmentorid": widget.mentorData['id'].toString()},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        if (data is List) {
          setState(() {
            jadwalList = data;
            isLoading = false;
          });
        } else if (data.containsKey('error')) {
          setState(() {
            errorMessage = data['error'];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        errorMessage = "Koneksi gagal";
        isLoading = false;
      });
    }
  }

  Future<void> _deleteJadwal(int jadwalId) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Hapus"),
        content: const Text("Yakin ingin menghapus jadwal ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    String uri = ApiConfig.getUrl('delete_jadwal_mentor.php');

    try {
      var response = await http.post(
        Uri.parse(uri),
        body: {
          "itemjadwalid": jadwalId.toString(),
          "itemmentorid": widget.mentorData['id'].toString(),
        },
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Jadwal berhasil dihapus"),
              backgroundColor: Colors.green,
            ),
          );
          loadJadwal();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? "Gagal menghapus"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Koneksi gagal"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Map<String, List<dynamic>> _groupByHari() {
    Map<String, List<dynamic>> grouped = {};

    for (var jadwal in jadwalList) {
      String hari = jadwal['hari'];
      if (!grouped.containsKey(hari)) {
        grouped[hari] = [];
      }
      grouped[hari]!.add(jadwal);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        elevation: 0,
        title: const Text("Semua Jadwal", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 80, color: Colors.red[300]),
                      const SizedBox(height: 20),
                      Text(errorMessage!,
                          style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: loadJadwal,
                        icon: const Icon(Icons.refresh),
                        label: const Text("Coba Lagi"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                )
              : jadwalList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 80, color: Colors.grey[400]),
                          const SizedBox(height: 20),
                          Text(
                            "Belum ada jadwal",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Tambah jadwal untuk mulai menerima booking",
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: loadJadwal,
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: _buildJadwalByHari(),
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  TambahJadwalMentor(mentorData: widget.mentorData),
            ),
          );
          if (result == true) {
            loadJadwal();
          }
        },
        backgroundColor: Colors.blue[700],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  List<Widget> _buildJadwalByHari() {
    List<Widget> widgets = [];
    Map<String, List<dynamic>> groupedJadwal = _groupByHari();

    List<String> hariOrder = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu'
    ];

    for (String hari in hariOrder) {
      if (groupedJadwal.containsKey(hari)) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10, top: 10),
            child: Text(
              hari,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
          ),
        );

        for (var jadwal in groupedJadwal[hari]!) {
          widgets.add(_buildJadwalCard(jadwal));
        }
      }
    }

    return widgets;
  }

  Widget _buildJadwalCard(Map<String, dynamic> jadwal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    jadwal['mata_pelajaran'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () =>
                      _deleteJadwal(int.parse(jadwal['id'].toString())),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.access_time, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  "${jadwal['jam_mulai'].substring(0, 5)} - ${jadwal['jam_selesai'].substring(0, 5)}",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.event_available, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  "${jadwal['total_booking']} booking",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
