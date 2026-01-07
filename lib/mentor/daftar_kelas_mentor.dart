import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'tambah_kelas_mentor.dart';

class DaftarKelasMentor extends StatefulWidget {
  final Map<String, dynamic> mentorData;

  const DaftarKelasMentor({super.key, required this.mentorData});

  @override
  State<DaftarKelasMentor> createState() => _DaftarKelasMentorState();
}

class _DaftarKelasMentorState extends State<DaftarKelasMentor> {
  List<Map<String, dynamic>> kelasList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadKelas();
  }

  Future<void> _loadKelas() async {
    setState(() => isLoading = true);

    try {
      final mentorUid = widget.mentorData['uid'] ?? widget.mentorData['id'];
      final snapshot = await FirebaseDatabase.instance.ref('kelas').get();

      if (snapshot.exists) {
        final data = snapshot.value;
        List<Map<String, dynamic>> tempList = [];

        if (data is Map) {
          data.forEach((key, value) {
            if (value is Map && value['mentor_uid'] == mentorUid) {
              tempList.add({
                'id': key,
                ...Map<String, dynamic>.from(value),
              });
            }
          });
        }

        // Sort by created_at (newest first)
        tempList.sort((a, b) {
          String dateA = a['created_at'] ?? '';
          String dateB = b['created_at'] ?? '';
          return dateB.compareTo(dateA);
        });

        setState(() {
          kelasList = tempList;
          isLoading = false;
        });
      } else {
        setState(() {
          kelasList = [];
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading kelas: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _hapusKelas(String kelasId) async {
    try {
      await FirebaseDatabase.instance.ref('kelas').child(kelasId).remove();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Kelas berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );

      _loadKelas(); // Reload data
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteConfirmation(String kelasId, String kelasName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kelas'),
        content: Text('Apakah Anda yakin ingin menghapus kelas "$kelasName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _hapusKelas(kelasId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Kelas Saya'),
        backgroundColor: const Color(0xFF5B6BC4),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : kelasList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada kelas',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tambahkan kelas pertama Anda!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadKelas,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: kelasList.length,
                    itemBuilder: (context, index) {
                      final kelas = kelasList[index];
                      return _buildKelasCard(kelas);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  TambahKelasMentor(mentorData: widget.mentorData),
            ),
          ).then((_) => _loadKelas());
        },
        backgroundColor: const Color(0xFF5B6BC4),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Tambah Kelas',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        elevation: 4,
      ),
    );
  }

  Widget _buildKelasCard(Map<String, dynamic> kelas) {
    final createdAt = kelas['created_at'] != null
        ? DateTime.parse(kelas['created_at'])
        : DateTime.now();
    final formattedDate = DateFormat('dd MMM yyyy').format(createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF5B6BC4), Color(0xFF7B8DD4)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kelas['course_name'] ?? 'No Name',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        kelas['category'] ?? '',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(Icons.class_, kelas['class_level'] ?? '-'),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.schedule, kelas['duration'] ?? '-'),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.attach_money,
                  _formatPrice(kelas['price']),
                ),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.calendar_today, formattedDate),
                const SizedBox(height: 12),

                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: kelas['status'] == 'active'
                        ? Colors.green[50]
                        : Colors.orange[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        kelas['status'] == 'active'
                            ? Icons.check_circle
                            : Icons.schedule,
                        size: 14,
                        color: kelas['status'] == 'active'
                            ? Colors.green
                            : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        kelas['status'] == 'active' ? 'Active' : 'Pending',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: kelas['status'] == 'active'
                              ? Colors.green[700]
                              : Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Jadwal info
                if (kelas['jadwal_ids'] != null &&
                    (kelas['jadwal_ids'] as List).isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.event_available,
                            color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${(kelas['jadwal_ids'] as List).length} Jadwal Terhubung',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                if (kelas['jadwal_ids'] != null &&
                    (kelas['jadwal_ids'] as List).isNotEmpty)
                  const SizedBox(height: 12),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showManageJadwalDialog(kelas);
                        },
                        icon: const Icon(Icons.schedule, size: 18),
                        label: const Text('Jadwal'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF5B6BC4),
                          side: const BorderSide(color: Color(0xFF5B6BC4)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showDeleteConfirmation(
                            kelas['id'],
                            kelas['course_name'] ?? 'kelas ini',
                          );
                        },
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text('Hapus'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
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

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  String _formatPrice(dynamic value) {
    if (value == null) return '-';
    try {
      final intPrice = value is int
          ? value
          : int.tryParse(value.toString().replaceAll('.', ''));
      if (intPrice == null) return '-';
      final formatter = NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      );
      return formatter.format(intPrice);
    } catch (_) {
      return '-';
    }
  }

  Future<void> _showManageJadwalDialog(Map<String, dynamic> kelas) async {
    // Load all jadwal
    final mentorUid = widget.mentorData['uid'] ?? widget.mentorData['id'];
    final snapshot =
        await FirebaseDatabase.instance.ref('jadwal').child(mentorUid).get();

    List<Map<String, dynamic>> allJadwal = [];
    Set<String> currentJadwalIds = {};

    if (kelas['jadwal_ids'] != null) {
      currentJadwalIds = Set<String>.from(kelas['jadwal_ids'] as List);
    }

    if (snapshot.exists) {
      final data = snapshot.value;
      if (data is Map) {
        final now = DateTime.now();
        for (final entry in data.entries) {
          final key = entry.key;
          final value = entry.value;
          if (value is! Map) continue;

          final map = Map<String, dynamic>.from(value);
          final type = (map['type'] ?? 'weekly').toString();
          final tanggal = (map['tanggal'] ?? '').toString();
          final jamMulai = (map['jam_mulai'] ?? '').toString();
          final jamSelesai = (map['jam_selesai'] ?? '').toString();
          final mataPelajaran = (map['mata_pelajaran'] ?? '').toString().trim();

          // Skip jadwal that have no subject or time info
          if (mataPelajaran.isEmpty || jamMulai.isEmpty || jamSelesai.isEmpty) {
            await FirebaseDatabase.instance
                .ref('jadwal')
                .child(mentorUid)
                .child(key)
                .remove();
            continue;
          }

          DateTime? endTime;
          if (tanggal.isNotEmpty && jamSelesai.isNotEmpty) {
            try {
              final parsedDate = DateFormat('dd-MM-yyyy').parseStrict(tanggal);
              final timeParts = jamSelesai.split(':');
              if (timeParts.length == 2) {
                final hour = int.tryParse(timeParts[0]) ?? 0;
                final minute = int.tryParse(timeParts[1]) ?? 0;
                endTime = DateTime(parsedDate.year, parsedDate.month,
                    parsedDate.day, hour, minute);
              }
            } catch (_) {}
          }

          // Auto-delete one-time jadwal yang sudah lewat
          if (type == 'one_time' && endTime != null && now.isAfter(endTime)) {
            await FirebaseDatabase.instance
                .ref('jadwal')
                .child(mentorUid)
                .child(key)
                .remove();
            continue;
          }

          // Untuk weekly, jika tanggal sudah lewat, geser ke pekan berikutnya
          if (type == 'weekly' && endTime != null && now.isAfter(endTime)) {
            final updatedDate = endTime.add(const Duration(days: 7));
            map['tanggal'] = DateFormat('dd-MM-yyyy').format(updatedDate);
            await FirebaseDatabase.instance
                .ref('jadwal')
                .child(mentorUid)
                .child(key)
                .update({'tanggal': map['tanggal']});
          }

          allJadwal.add({
            'id': key,
            ...map,
          });
        }
      }
    }

    if (!mounted) return;

    final durationMinutes = kelas['duration_minutes'] ?? 60;

    showDialog(
      context: context,
      builder: (context) => _ManageJadwalDialog(
        allJadwal: allJadwal,
        currentJadwalIds: currentJadwalIds,
        kelasId: kelas['id'],
        kelasName: kelas['course_name'] ?? 'Kelas',
        mentorUid: mentorUid,
        durationMinutes: durationMinutes,
        onUpdated: () {
          _loadKelas(); // Reload data
        },
      ),
    );
  }
}

// Dialog untuk mengelola jadwal kelas
class _ManageJadwalDialog extends StatefulWidget {
  final List<Map<String, dynamic>> allJadwal;
  final Set<String> currentJadwalIds;
  final String kelasId;
  final String kelasName;
  final String mentorUid;
  final int durationMinutes;
  final VoidCallback onUpdated;

  const _ManageJadwalDialog({
    required this.allJadwal,
    required this.currentJadwalIds,
    required this.kelasId,
    required this.kelasName,
    required this.mentorUid,
    required this.durationMinutes,
    required this.onUpdated,
  });

  @override
  State<_ManageJadwalDialog> createState() => _ManageJadwalDialogState();
}

class _ManageJadwalDialogState extends State<_ManageJadwalDialog> {
  late Set<String> selectedJadwalIds;
  bool isSaving = false;

  bool isWeekly = false;
  DateTime? selectedDate;
  int? selectedWeekday; // 1=Mon ... 7=Sun
  TimeOfDay? startTime;
  String? deleteTargetId;

  @override
  void initState() {
    super.initState();
    selectedJadwalIds = Set<String>.from(widget.currentJadwalIds);
    _initDefaultSelections();
  }

  void _initDefaultSelections() {
    final now = DateTime.now();
    selectedDate = DateTime(now.year, now.month, now.day);
    selectedWeekday = now.weekday;
    startTime = const TimeOfDay(hour: 9, minute: 0);
  }

  String _weekdayLabel(int weekday) {
    const labels = {
      1: 'Senin',
      2: 'Selasa',
      3: 'Rabu',
      4: 'Kamis',
      5: 'Jumat',
      6: 'Sabtu',
      7: 'Minggu',
    };
    return labels[weekday] ?? 'Hari';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _buildJadwalTitle(Map<String, dynamic> jadwal) {
    final mataPelajaran = jadwal['mata_pelajaran'] ?? 'Mata Pelajaran';
    final type = jadwal['type'] ?? 'weekly';
    if (type == 'one_time') {
      final tanggal = jadwal['tanggal'] ?? '';
      return '$mataPelajaran ($tanggal)';
    }
    final hari = jadwal['hari'] ?? '';
    return '$mataPelajaran ($hari)';
  }

  String _buildJadwalSubtitle(Map<String, dynamic> jadwal) {
    final type = jadwal['type'] ?? 'weekly';
    final jamMulai = jadwal['jam_mulai'] ?? '';
    final jamSelesai = jadwal['jam_selesai'] ?? '';
    if (type == 'one_time') {
      final tanggal = jadwal['tanggal'] ?? '';
      return '$tanggal · $jamMulai - $jamSelesai';
    }
    final hari = jadwal['hari'] ?? '';
    return '$hari · $jamMulai - $jamSelesai';
  }

  IconData _iconForJadwal(Map<String, dynamic> jadwal) {
    final type = jadwal['type'] ?? 'weekly';
    return type == 'one_time' ? Icons.event : Icons.repeat;
  }

  List<Map<String, dynamic>> _deletableJadwal() {
    return widget.allJadwal.where((j) => (j['status'] == 'available')).toList()
      ..sort((a, b) => (_buildJadwalTitle(a)).compareTo(_buildJadwalTitle(b)));
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  TimeOfDay? _calculateEndTime() {
    if (startTime == null) return null;
    final startMinutes = startTime!.hour * 60 + startTime!.minute;
    final endMinutes = startMinutes + widget.durationMinutes;
    return TimeOfDay(hour: endMinutes ~/ 60 % 24, minute: endMinutes % 60);
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: startTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() {
        startTime = picked;
      });
    }
  }

  Future<void> _createJadwal() async {
    if (startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih jam mulai')),
      );
      return;
    }

    final endTime = _calculateEndTime();
    if (endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menghitung jam selesai')),
      );
      return;
    }

    if (isWeekly) {
      if (selectedWeekday == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih hari untuk jadwal mingguan')),
        );
        return;
      }
    } else {
      if (selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih tanggal untuk jadwal sekali')),
        );
        return;
      }
    }

    setState(() {
      isSaving = true;
    });

    try {
      final jadwalRef =
          FirebaseDatabase.instance.ref('jadwal').child(widget.mentorUid);
      final newRef = jadwalRef.push();

      if (isWeekly) {
        final hari = _weekdayLabel(selectedWeekday!);
        final entry = {
          'id': newRef.key,
          'hari': hari,
          'mata_pelajaran': widget.kelasName,
          'status': 'available',
          'kelas_id': widget.kelasId,
          'kelas_name': widget.kelasName,
          'jam_mulai': _formatTime(startTime!),
          'jam_selesai': _formatTime(endTime),
          'type': 'weekly',
          'created_at': DateTime.now().toIso8601String(),
        };
        await newRef.set(entry);
        setState(() {
          widget.allJadwal.insert(0, entry);
          selectedJadwalIds.add(entry['id'] as String);
        });
      } else {
        final tanggalStr =
            '${selectedDate!.day.toString().padLeft(2, '0')}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.year}';
        final entry = {
          'id': newRef.key,
          'tanggal': tanggalStr,
          'hari': _weekdayLabel(selectedDate!.weekday),
          'mata_pelajaran': widget.kelasName,
          'status': 'available',
          'kelas_id': widget.kelasId,
          'kelas_name': widget.kelasName,
          'jam_mulai': _formatTime(startTime!),
          'jam_selesai': _formatTime(endTime),
          'type': 'one_time',
          'created_at': DateTime.now().toIso8601String(),
        };
        await newRef.set(entry);
        setState(() {
          widget.allJadwal.insert(0, entry);
          selectedJadwalIds.add(entry['id'] as String);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuat jadwal: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteJadwal() async {
    if (deleteTargetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih jadwal yang ingin dihapus')),
      );
      return;
    }

    final target = widget.allJadwal.firstWhere(
      (j) => j['id'] == deleteTargetId,
      orElse: () => {},
    );

    if (target.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jadwal tidak ditemukan')),
      );
      return;
    }

    if (target['status'] != 'available') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Jadwal sudah dibooking, tidak bisa dihapus')),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await FirebaseDatabase.instance
          .ref('jadwal')
          .child(widget.mentorUid)
          .child(deleteTargetId!)
          .remove();

      // Pastikan kelas tidak lagi mereferensikan jadwal yang dihapus
      selectedJadwalIds.remove(deleteTargetId!);
      widget.allJadwal.removeWhere((j) => j['id'] == deleteTargetId!);

      final updatedIds = selectedJadwalIds.toList();
      await FirebaseDatabase.instance
          .ref('kelas')
          .child(widget.kelasId)
          .child('jadwal_ids')
          .set(updatedIds);

      setState(() {
        deleteTargetId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jadwal berhasil dihapus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus jadwal: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Widget _buildCreateForm() {
    return Card(
      color: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        isWeekly = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isWeekly
                            ? Colors.white
                            : const Color(0xFF5B6BC4).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isWeekly
                              ? Colors.grey.shade300
                              : const Color(0xFF5B6BC4),
                        ),
                      ),
                      child: Column(
                        children: const [
                          Text(
                            'Sekali (Tanggal)',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Pilih tanggal spesifik',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        isWeekly = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isWeekly
                            ? const Color(0xFF5B6BC4).withOpacity(0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isWeekly
                              ? const Color(0xFF5B6BC4)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        children: const [
                          Text(
                            'Mingguan',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Berulang tiap minggu',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!isWeekly)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _pickDate,
                      child: Text(
                        selectedDate == null
                            ? 'Pilih tanggal'
                            : '${selectedDate!.day.toString().padLeft(2, '0')}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.year}',
                      ),
                    ),
                  ),
                ],
              ),
            if (isWeekly)
              DropdownButtonFormField<int>(
                value: selectedWeekday,
                decoration: const InputDecoration(
                  labelText: 'Pilih hari',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: List.generate(7, (index) {
                  final weekday = index + 1;
                  return DropdownMenuItem(
                    value: weekday,
                    child: Text(_weekdayLabel(weekday)),
                  );
                }),
                onChanged: (value) {
                  setState(() {
                    selectedWeekday = value;
                  });
                },
              ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _pickStartTime,
              child: Text(
                startTime == null
                    ? 'Pilih jam mulai'
                    : 'Mulai: ${_formatTime(startTime!)}',
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, color: Colors.grey[600], size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _calculateEndTime() == null
                          ? 'Jam selesai (otomatis)'
                          : 'Selesai: ${_formatTime(_calculateEndTime()!)} (${widget.durationMinutes} menit)',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : _createJadwal,
                icon: const Icon(Icons.add),
                label: Text(isSaving ? 'Menyimpan...' : 'Tambah Jadwal'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B6BC4),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: deleteTargetId,
              decoration: const InputDecoration(
                labelText: 'Pilih jadwal untuk dihapus',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: _deletableJadwal().map((j) {
                final id = j['id'] as String;
                return DropdownMenuItem(
                  value: id,
                  child: Text(_buildJadwalTitle(j)),
                );
              }).toList(),
              onChanged: isSaving
                  ? null
                  : (value) {
                      setState(() {
                        deleteTargetId = value;
                      });
                    },
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isSaving ? null : _deleteJadwal,
                icon: const Icon(Icons.delete_outline),
                label: Text(isSaving ? 'Menghapus...' : 'Hapus Jadwal'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red[700],
                  side: BorderSide(color: Colors.red.shade300),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    setState(() => isSaving = true);

    try {
      // Update kelas dengan jadwal_ids baru
      await FirebaseDatabase.instance
          .ref('kelas')
          .child(widget.kelasId)
          .child('jadwal_ids')
          .set(selectedJadwalIds.toList());

      // Update jadwal yang ditambahkan
      for (String jadwalId in selectedJadwalIds) {
        if (!widget.currentJadwalIds.contains(jadwalId)) {
          await FirebaseDatabase.instance
              .ref('jadwal')
              .child(widget.mentorUid)
              .child(jadwalId)
              .update({
            'kelas_id': widget.kelasId,
            'kelas_name': widget.kelasName,
          });
        }
      }

      // Hapus kelas_id dari jadwal yang dihapus
      for (String jadwalId in widget.currentJadwalIds) {
        if (!selectedJadwalIds.contains(jadwalId)) {
          await FirebaseDatabase.instance
              .ref('jadwal')
              .child(widget.mentorUid)
              .child(jadwalId)
              .update({
            'kelas_id': null,
            'kelas_name': null,
          });
        }
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Jadwal berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Kelola Jadwal Kelas'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCreateForm(),
            const SizedBox(height: 12),
            Builder(
              builder: (context) {
                final visibleJadwal = widget.allJadwal.where((jadwal) {
                  final isSelected = selectedJadwalIds.contains(jadwal['id']);
                  final isAvailable = jadwal['status'] == 'available';
                  final belongsToThisClass = jadwal['kelas_id'] == null ||
                      jadwal['kelas_id'] == widget.kelasId;
                  return isSelected || (isAvailable && belongsToThisClass);
                }).toList();

                if (visibleJadwal.isEmpty) {
                  return const Expanded(
                    child: Center(
                      child: Text('Tidak ada jadwal tersedia'),
                    ),
                  );
                }

                return Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: visibleJadwal.length,
                    itemBuilder: (context, index) {
                      final jadwal = visibleJadwal[index];
                      final jadwalId = jadwal['id'];
                      final isSelected = selectedJadwalIds.contains(jadwalId);
                      final isAvailable = jadwal['status'] == 'available';
                      final hasOtherKelas = jadwal['kelas_id'] != null &&
                          jadwal['kelas_id'] != widget.kelasId;

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (!isAvailable || hasOtherKelas)
                            ? null
                            : (value) {
                                setState(() {
                                  if (value == true) {
                                    selectedJadwalIds.add(jadwalId);
                                  } else {
                                    selectedJadwalIds.remove(jadwalId);
                                  }
                                });
                              },
                        title: Text(
                          _buildJadwalTitle(jadwal),
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: (!isAvailable || hasOtherKelas)
                                ? Colors.grey
                                : Colors.black,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _buildJadwalSubtitle(jadwal),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (!isAvailable)
                              Text(
                                'Sudah dibooking',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.red[700],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            if (hasOtherKelas)
                              Text(
                                'Terhubung ke: ${jadwal['kelas_name']}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange[700],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF5B6BC4).withOpacity(0.2)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _iconForJadwal(jadwal),
                            color: isSelected
                                ? const Color(0xFF5B6BC4)
                                : Colors.grey,
                            size: 20,
                          ),
                        ),
                        activeColor: const Color(0xFF5B6BC4),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSaving ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: isSaving ? null : _saveChanges,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5B6BC4),
          ),
          child: isSaving
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Simpan', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
