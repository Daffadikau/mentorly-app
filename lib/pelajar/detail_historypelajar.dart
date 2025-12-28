import 'package:flutter/material.dart';
import '../mentor/review_mentor.dart';

class DetailRiwayat extends StatelessWidget {
  final Map<String, dynamic> bookingData;

  const DetailRiwayat({super.key, required this.bookingData});

  @override
  Widget build(BuildContext context) {
    String status = bookingData['status'];
    bool isCompleted = status == 'completed';
    bool isPending = status == 'pending';
    bool hasReview = bookingData['rating'] != null &&
        int.parse(bookingData['rating'].toString()) > 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        elevation: 0,
        title:
            const Text("Detail Riwayat", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green[700]
                    : isPending
                        ? Colors.orange[700]
                        : Colors.red[700],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    isCompleted
                        ? Icons.check_circle
                        : isPending
                            ? Icons.schedule
                            : Icons.cancel,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isCompleted
                        ? "Sesi Selesai"
                        : isPending
                            ? "Menunggu Konfirmasi"
                            : "Dibatalkan",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isCompleted
                          ? "Terima kasih telah menggunakan Mentorly"
                          : isPending
                              ? "Mentor akan segera mengkonfirmasi"
                              : "Sesi tidak dapat dilanjutkan",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Informasi Mentor",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person,
                              color: Colors.blue[700], size: 30),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bookingData['nama_mentor'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                bookingData['mata_pelajaran'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
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
                    Icons.confirmation_number,
                    "No. Booking",
                    "#${bookingData['id']}",
                  ),
                  _buildDetailRow(
                    Icons.calendar_today,
                    "Tanggal",
                    _formatDate(bookingData['tanggal']),
                  ),
                  _buildDetailRow(
                    Icons.access_time,
                    "Waktu",
                    bookingData['waktu'],
                  ),
                  _buildDetailRow(
                    Icons.timer,
                    "Durasi",
                    "${bookingData['durasi']} Jam",
                  ),
                  _buildDetailRow(
                    Icons.attach_money,
                    "Total Biaya",
                    "Rp ${_formatCurrency(bookingData['total_biaya'])}",
                  ),
                  const SizedBox(height: 25),
                  if (isCompleted && hasReview) ...[
                    const Text(
                      "Review Anda",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                index <
                                        int.parse(
                                            bookingData['rating'].toString())
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 24,
                              );
                            }),
                          ),
                          if (bookingData['review'] != null &&
                              bookingData['review'].toString().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              bookingData['review'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                height: 1.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  if (isPending) ...[
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange[700]),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Booking Anda sedang menunggu konfirmasi dari mentor. Anda akan menerima notifikasi setelah dikonfirmasi.",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[900],
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isCompleted && !hasReview
          ? Container(
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
              child: SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ReviewPage(bookingData: bookingData),
                      ),
                    ).then((result) {
                      if (result == true) {
                        Navigator.pop(context, true);
                      }
                    });
                  },
                  icon: const Icon(Icons.star, color: Colors.white),
                  label: const Text(
                    "Berikan Review",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            )
          : null,
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
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.grey[700], size: 20),
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

  String _formatCurrency(dynamic value) {
    if (value == null) return "0";
    double amount = double.parse(value.toString());
    return amount.toStringAsFixed(0).replaceAllMapped(
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
