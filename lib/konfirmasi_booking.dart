import 'package:flutter/material.dart';
import 'payment_succes.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class KonfirmasiBooking extends StatelessWidget {
  final Map<String, dynamic> mentorData;
  final Map<String, dynamic> pelajarData;
  final Map<String, dynamic> jadwalData;

  const KonfirmasiBooking({super.key, 
    required this.mentorData,
    required this.pelajarData,
    required this.jadwalData,
  });

  Future<void> processBooking(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    String uri = "http://localhost/mentorly/create_booking.php";

    double harga =
        double.tryParse(mentorData['total_penghasilan'].toString()) ?? 20000;
    if (harga == 0) harga = 20000;
    int durasi = int.tryParse(jadwalData['durasi'].toString()) ?? 1;
    double totalBiaya = harga * durasi;

    try {
      var response = await http.post(
        Uri.parse(uri),
        body: {
          "itempelajarid": pelajarData['id'].toString(),
          "itemmentorid": mentorData['id'].toString(),
          "itemjadwalid": jadwalData['id'].toString(),
          "itemdurasi": durasi.toString(),
          "itemtotalbiaya": totalBiaya.toString(),
        },
      );

      Navigator.pop(context); // Close loading dialog

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentSuccess(
                mentorName: mentorData['nama_lengkap'],
                pelajarData: pelajarData,
                totalBiaya: totalBiaya,
                jadwalData: jadwalData,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'])),
          );
        }
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double harga =
        double.tryParse(mentorData['total_penghasilan'].toString()) ?? 20000;
    if (harga == 0) harga = 20000;
    int durasi = int.tryParse(jadwalData['durasi'].toString()) ?? 1;
    double totalBiaya = harga * durasi;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        elevation: 0,
        title:
            const Text("Konfirmasi Booking", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child:
                        Icon(Icons.person, size: 40, color: Colors.blue[700]),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    mentorData['nama_lengkap'],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    mentorData['keahlian'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              "Detail Booking",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            _buildDetailRow(
              Icons.book,
              "Mata Pelajaran",
              jadwalData['mata_pelajaran'],
            ),
            _buildDetailRow(
              Icons.calendar_today,
              "Tanggal",
              _formatDate(jadwalData['tanggal']),
            ),
            _buildDetailRow(
              Icons.access_time,
              "Waktu",
              jadwalData['waktu'],
            ),
            _buildDetailRow(
              Icons.timer,
              "Durasi",
              "$durasi Jam",
            ),
            if (jadwalData['kelas'] != null &&
                jadwalData['kelas'].toString().isNotEmpty)
              _buildDetailRow(
                Icons.class_,
                "Kelas",
                jadwalData['kelas'],
              ),
            const SizedBox(height: 25),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Harga per Jam",
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      Text(
                        "Rp ${_formatCurrency(harga)}",
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Durasi",
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      Text(
                        "$durasi Jam",
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const Divider(height: 30, thickness: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Total Biaya",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[900],
                        ),
                      ),
                      Text(
                        "Rp ${_formatCurrency(totalBiaya)}",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[900],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.green[700]),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Pembayaran akan diproses setelah konfirmasi. Anda akan menerima notifikasi dari mentor.",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[900],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () => processBooking(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Bayar & Booking Sekarang",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Dengan melanjutkan, Anda menyetujui syarat dan ketentuan",
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue[700], size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
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

  String _formatCurrency(double value) {
    return value.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  String _formatDate(String date) {
    try {
      DateTime dateTime = DateTime.parse(date);
      List<String> days = [
        'Minggu',
        'Senin',
        'Selasa',
        'Rabu',
        'Kamis',
        'Jumat',
        'Sabtu',
      ];
      List<String> months = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember',
      ];

      return "${days[dateTime.weekday % 7]}, ${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}";
    } catch (e) {
      return date;
    }
  }
}
