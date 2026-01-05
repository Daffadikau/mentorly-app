import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class HistoryPelajar extends StatefulWidget {
  final Map<String, dynamic> pelajarData;

  const HistoryPelajar({super.key, required this.pelajarData});

  @override
  _HistoryPelajarState createState() => _HistoryPelajarState();
}

class _HistoryPelajarState extends State<HistoryPelajar> {
  List<Map<String, dynamic>> historyList = [];
  bool isLoading = true;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    setState(() => isLoading = true);

    try {
      final pelajarId =
          widget.pelajarData['uid'] ?? widget.pelajarData['id'].toString();
      print('🔍 Loading history for pelajar: $pelajarId');

      // Get all bookings for this pelajar
      final snapshot = await _database
          .child('bookings')
          .orderByChild('pelajar_id')
          .equalTo(pelajarId)
          .get();

      if (snapshot.exists) {
        List<Map<String, dynamic>> tempList = [];
        Map<dynamic, dynamic> bookings =
            snapshot.value as Map<dynamic, dynamic>;

        DateTime now = DateTime.now();

        for (var entry in bookings.entries) {
          Map<String, dynamic> booking = Map<String, dynamic>.from(entry.value);
          booking['id'] = entry.key;

          try {
            // Parse booking date and time
            // Date format in database is yyyy-MM-dd (e.g., 2026-01-02)
            DateTime bookingDate = DateTime.parse(booking['tanggal']);

            // Parse jam_selesai (HH:mm format)
            List<String> timeParts =
                booking['jam_selesai'].toString().split(':');
            DateTime sessionEndTime = DateTime(
              bookingDate.year,
              bookingDate.month,
              bookingDate.day,
              int.parse(timeParts[0]),
              int.parse(timeParts[1]),
            );

            // Show all bookings (confirmed, completed, or past sessions)
            bool shouldShow = false;

            if (booking['status'] == 'completed') {
              shouldShow = true;
            } else if (booking['status'] == 'confirmed' &&
                sessionEndTime.isBefore(now)) {
              // Auto-update past confirmed sessions to completed
              await _database
                  .child('bookings')
                  .child(entry.key)
                  .update({'status': 'completed'});
              booking['status'] = 'completed';
              shouldShow = true;
            } else if (booking['status'] == 'confirmed') {
              // Also show upcoming confirmed bookings
              shouldShow = true;
            }

            if (shouldShow) {
              tempList.add(booking);
              print(
                  '✅ Added to history: ${booking['mentor_name']} - ${booking['tanggal']} (${booking['status']})');
            }
          } catch (e) {
            print('❌ Error parsing date for booking ${entry.key}: $e');
          }
        }

        // Sort by date descending (newest first)
        tempList.sort((a, b) {
          try {
            DateTime dateA = DateTime.parse(a['tanggal']);
            DateTime dateB = DateTime.parse(b['tanggal']);
            return dateB.compareTo(dateA);
          } catch (e) {
            return 0;
          }
        });

        setState(() {
          historyList = tempList;
          isLoading = false;
        });

        print('📊 Total history items: ${tempList.length}');
      } else {
        print('ℹ️ No bookings found');
        setState(() {
          historyList = [];
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading history: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> submitReview(String bookingId, int rating, String review) async {
    try {
      await _database.child('bookings').child(bookingId).update({
        'rating': rating,
        'review': review,
        'reviewed_at': DateTime.now().millisecondsSinceEpoch,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Review berhasil dikirim")),
      );
      loadHistory();
    } catch (e) {
      print('❌ Error submitting review: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal mengirim review")),
      );
    }
  }

  String _formatDate(String dateStr) {
    try {
      // Parse yyyy-MM-dd format
      final date = DateTime.parse(dateStr);
      // Format to readable Indonesian date
      return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return dateStr; // Return original if parsing fails
    }
  }

  String _formatCurrency(dynamic value) {
    try {
      double amount = double.parse(value.toString());
      return NumberFormat('#,###', 'id_ID').format(amount);
    } catch (e) {
      return value.toString();
    }
  }

  void showReviewDialog(Map<String, dynamic> booking) {
    int selectedRating = booking['rating'] ?? 5;
    TextEditingController reviewController =
        TextEditingController(text: booking['review'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Berikan Review"),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Rating:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < selectedRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () {
                      setDialogState(() {
                        selectedRating = index + 1;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: reviewController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: "Tulis review Anda...",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              submitReview(
                booking['id'].toString(),
                selectedRating,
                reviewController.text,
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
            ),
            child: const Text("Kirim", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        elevation: 0,
        title: const Text("Riwayat", style: TextStyle(color: Colors.white)),
        automaticallyImplyLeading: false,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : historyList.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 80, color: Colors.grey),
                      SizedBox(height: 20),
                      Text(
                        "Belum ada riwayat booking",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: historyList.length,
                  itemBuilder: (context, index) {
                    var booking = historyList[index];
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
                                CircleAvatar(
                                  radius: 25,
                                  backgroundColor: Colors.blue[100],
                                  child: Icon(Icons.person,
                                      color: Colors.blue[700]),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        booking['mentor_name'] ?? 'Mentor',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        booking['jadwal_id'] ?? '-',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: booking['status'] == 'completed'
                                        ? Colors.green[50]
                                        : booking['status'] == 'pending'
                                            ? Colors.orange[50]
                                            : Colors.red[50],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    booking['status'] == 'completed'
                                        ? 'Selesai'
                                        : booking['status'] == 'pending'
                                            ? 'Pending'
                                            : 'Dibatalkan',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: booking['status'] == 'completed'
                                          ? Colors.green[700]
                                          : booking['status'] == 'pending'
                                              ? Colors.orange[700]
                                              : Colors.red[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            Row(
                              children: [
                                Icon(Icons.calendar_today,
                                    size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    "${_formatDate(booking['tanggal'])} • ${booking['jam_mulai']} - ${booking['jam_selesai']}",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.attach_money,
                                    size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 5),
                                Text(
                                  "Rp ${_formatCurrency(booking['harga'] ?? 0)}",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ],
                            ),
                            if (booking['status'] == 'completed') ...[
                              const SizedBox(height: 15),
                              if (booking['rating'] != null &&
                                  booking['rating'] > 0)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: List.generate(5, (i) {
                                        return Icon(
                                          i <
                                                  int.parse(booking['rating']
                                                      .toString())
                                              ? Icons.star
                                              : Icons.star_border,
                                          color: Colors.amber,
                                          size: 20,
                                        );
                                      }),
                                    ),
                                    if (booking['review'] != null &&
                                        booking['review'].toString().isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          booking['review'],
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[700],
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                  ],
                                )
                              else
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () => showReviewDialog(booking),
                                    icon: Icon(Icons.star_outline,
                                        color: Colors.blue[700]),
                                    label: Text(
                                      "Berikan Review",
                                      style: TextStyle(color: Colors.blue[700]),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side:
                                          BorderSide(color: Colors.blue[700]!),
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
