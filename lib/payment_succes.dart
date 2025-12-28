import 'package:flutter/material.dart';
import 'dashboard_pelajar.dart';
import 'history_pelajar.dart';

class PaymentSuccess extends StatelessWidget {
  final String mentorName;
  final Map<String, dynamic> pelajarData;
  final double totalBiaya;
  final Map<String, dynamic> jadwalData;

  const PaymentSuccess({super.key, 
    required this.mentorName,
    required this.pelajarData,
    required this.totalBiaya,
    required this.jadwalData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      size: 80,
                      color: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  "Booking Berhasil!",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  "Pembayaran Anda telah berhasil diproses",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 30),
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
                        radius: 35,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person,
                            size: 35, color: Colors.blue[700]),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        mentorName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Divider(),
                      const SizedBox(height: 10),
                      _buildInfoRow(Icons.book, jadwalData['mata_pelajaran']),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.calendar_today,
                          _formatDate(jadwalData['tanggal'])),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.access_time, jadwalData['waktu']),
                      const SizedBox(height: 15),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Total Biaya",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange[900],
                              ),
                            ),
                            Text(
                              "Rp ${_formatCurrency(totalBiaya)}",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[900],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber[700]),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Silakan tunggu konfirmasi dari mentor. Anda akan menerima notifikasi segera.",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber[900],
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DashboardPelajar(userData: pelajarData),
                        ),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.home, color: Colors.white),
                    label: const Text(
                      "Kembali ke Beranda",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DashboardPelajar(userData: pelajarData),
                        ),
                        (route) => false,
                      );

                      // Delay navigasi ke history
                      Future.delayed(const Duration(milliseconds: 300), () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                HistoryPelajar(pelajarData: pelajarData),
                          ),
                        );
                      });
                    },
                    icon: Icon(Icons.receipt_long, color: Colors.blue[700]),
                    label: Text(
                      "Lihat Riwayat",
                      style: TextStyle(fontSize: 16, color: Colors.blue[700]),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.blue[700]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
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

      return "${days[dateTime.weekday % 7]}, ${dateTime.day} ${months[dateTime.month - 1]}";
    } catch (e) {
      return date;
    }
  }
}
