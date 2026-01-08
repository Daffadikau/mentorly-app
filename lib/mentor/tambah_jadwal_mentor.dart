import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class TambahJadwalMentor extends StatefulWidget {
  final Map<String, dynamic> mentorData;

  const TambahJadwalMentor({super.key, required this.mentorData});

  @override
  _TambahJadwalMentorState createState() => _TambahJadwalMentorState();
}

class _TambahJadwalMentorState extends State<TambahJadwalMentor> {
  final TextEditingController _mataPelajaranController =
      TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? jamMulai;
  TimeOfDay? jamSelesai;

  bool isLoading = false;

  @override
  void dispose() {
    _mataPelajaranController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue[700]!,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue[700]!,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          jamMulai = picked;
        } else {
          jamSelesai = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  bool _validateInput() {
    if (_mataPelajaranController.text.trim().isEmpty) {
      _showError("Mata pelajaran tidak boleh kosong");
      return false;
    }

    if (selectedDate == null) {
      _showError("Pilih tanggal jadwal");
      return false;
    }

    if (jamMulai == null) {
      _showError("Pilih jam mulai");
      return false;
    }

    if (jamSelesai == null) {
      _showError("Pilih jam selesai");
      return false;
    }

    // Validasi jam selesai > jam mulai
    final mulaiMinutes = jamMulai!.hour * 60 + jamMulai!.minute;
    final selesaiMinutes = jamSelesai!.hour * 60 + jamSelesai!.minute;

    if (selesaiMinutes <= mulaiMinutes) {
      _showError("Jam selesai harus lebih dari jam mulai");
      return false;
    }

    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _submitJadwal() async {
    if (!_validateInput()) return;

    setState(() {
      isLoading = true;
    });

    try {
      final mentorUid = widget.mentorData['mentor_id'] ?? widget.mentorData['id'];
      
      // Format tanggal dalam ISO dan display format
      final isoDate = DateFormat('yyyy-MM-dd').format(selectedDate!);
      final displayDate = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(selectedDate!);
      
      final ref = FirebaseDatabase.instance.ref('jadwal/$mentorUid');
      final newRef = ref.push();

      final jadwal = {
        'mentor_id': mentorUid,
        'mata_pelajaran': _mataPelajaranController.text.trim(),
        'tanggal': isoDate, // ISO format untuk parsing
        'display_date': displayDate, // Format display Indonesia
        'jam_mulai': _formatTime(jamMulai!),
        'jam_selesai': _formatTime(jamSelesai!),
        'status': 'available',
        'created_at': DateTime.now().toIso8601String(),
      };

      await newRef.set(jadwal);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Jadwal berhasil ditambahkan"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showError("Gagal menambahkan jadwal: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        elevation: 0,
        title:
            const Text("Tambah Jadwal", style: TextStyle(color: Colors.white)),
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
            Text(
              "Keahlian",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _mataPelajaranController,
              decoration: InputDecoration(
                hintText: "Contoh: Matematika - SMP Kelas 12",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.book_outlined),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Jadwal",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            // Date Picker
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Tanggal",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedDate != null
                              ? DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
                                  .format(selectedDate!)
                              : "Pilih tanggal",
                          style: TextStyle(
                            color: selectedDate != null
                                ? Colors.black87
                                : Colors.grey,
                          ),
                        ),
                        Icon(Icons.calendar_today, color: Colors.grey[600]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Jam Mulai",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectTime(context, true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 15,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                jamMulai != null
                                    ? _formatTime(jamMulai!)
                                    : "Pilih jam",
                                style: TextStyle(
                                  color: jamMulai != null
                                      ? Colors.black87
                                      : Colors.grey,
                                ),
                              ),
                              Icon(Icons.access_time, color: Colors.grey[600]),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Jam Selesai",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectTime(context, false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 15,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                jamSelesai != null
                                    ? _formatTime(jamSelesai!)
                                    : "Pilih jam",
                                style: TextStyle(
                                  color: jamSelesai != null
                                      ? Colors.black87
                                      : Colors.grey,
                                ),
                              ),
                              Icon(Icons.access_time, color: Colors.grey[600]),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed:
                          isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child:
                          const Text("Batal", style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _submitJadwal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Simpan",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                    ),
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
