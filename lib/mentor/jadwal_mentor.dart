import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class JadwalMentor extends StatefulWidget {
  final Map<String, dynamic> mentorData;

  const JadwalMentor({super.key, required this.mentorData});

  @override
  State<JadwalMentor> createState() => _JadwalMentorState();
}

class _JadwalMentorState extends State<JadwalMentor> {
  final DatabaseReference _jadwalRef = FirebaseDatabase.instance.ref('jadwal');
  List<Map<String, dynamic>> jadwalList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadJadwal();
  }

  Future<void> _loadJadwal() async {
    setState(() => isLoading = true);

    try {
      final mentorUid = widget.mentorData['uid'] ?? widget.mentorData['id'];
      final snapshot = await _jadwalRef.child(mentorUid).get();

      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value;
        List<Map<String, dynamic>> tempList = [];

        if (data is Map) {
          data.forEach((key, value) {
            if (value is Map) {
              tempList.add({
                'id': key,
                ...Map<String, dynamic>.from(value),
              });
            }
          });
        }

        // Sort by date and time
        tempList.sort((a, b) {
          final dateA = DateTime.parse(a['tanggal']);
          final dateB = DateTime.parse(b['tanggal']);
          if (dateA != dateB) return dateA.compareTo(dateB);
          return a['jam_mulai'].compareTo(b['jam_mulai']);
        });

        setState(() {
          jadwalList = tempList;
          isLoading = false;
        });
      } else {
        setState(() {
          jadwalList = [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading jadwal: $e')),
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> _loadKelasList() async {
    try {
      final mentorUid = widget.mentorData['uid'] ?? widget.mentorData['id'];
      print('Loading kelas for mentor: $mentorUid'); // Debug

      // Load all kelas and filter on client side
      final snapshot = await FirebaseDatabase.instance.ref('kelas').get();

      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value;
        List<Map<String, dynamic>> tempList = [];

        if (data is Map) {
          data.forEach((key, value) {
            if (value is Map) {
              final kelasData = Map<String, dynamic>.from(value);
              // Filter by mentor_uid and active status
              if (kelasData['mentor_uid'] == mentorUid &&
                  kelasData['status'] == 'active') {
                tempList.add({
                  'id': key,
                  ...kelasData,
                });
              }
            }
          });
        }

        print('Found ${tempList.length} kelas'); // Debug
        return tempList;
      }
      print('No kelas found in database'); // Debug
      return [];
    } catch (e) {
      print('Error loading kelas: $e');
      return [];
    }
  }

  Future<void> _deleteJadwal(String jadwalId) async {
    try {
      final mentorUid = widget.mentorData['uid'] ?? widget.mentorData['id'];
      await _jadwalRef.child(mentorUid).child(jadwalId).remove();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jadwal berhasil dihapus')),
        );
      }

      _loadJadwal();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error menghapus jadwal: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Jadwal'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : jadwalList.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadJadwal,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: jadwalList.length,
                    itemBuilder: (context, index) {
                      return _buildJadwalCard(jadwalList[index]);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddJadwalDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Jadwal'),
        backgroundColor: Colors.blue[700],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Belum ada jadwal',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Tambahkan jadwal agar pelajar\nbisa memesan layanan Anda',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildJadwalCard(Map<String, dynamic> jadwal) {
    final tanggal = DateTime.parse(jadwal['tanggal']);
    final isBooked = jadwal['status'] == 'booked';
    final isAvailable = jadwal['status'] == 'available';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isBooked
                ? Colors.orange[100]
                : isAvailable
                    ? Colors.green[100]
                    : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DateFormat('dd').format(tanggal),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isBooked
                      ? Colors.orange[700]
                      : isAvailable
                          ? Colors.green[700]
                          : Colors.grey[700],
                ),
              ),
              Text(
                DateFormat('MMM').format(tanggal),
                style: TextStyle(
                  fontSize: 12,
                  color: isBooked
                      ? Colors.orange[700]
                      : isAvailable
                          ? Colors.green[700]
                          : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
        title: Text(
          DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(tanggal),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${jadwal['jam_mulai']} - ${jadwal['jam_selesai']}'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  isBooked
                      ? Icons.event_busy
                      : isAvailable
                          ? Icons.event_available
                          : Icons.event,
                  size: 16,
                  color: isBooked
                      ? Colors.orange[700]
                      : isAvailable
                          ? Colors.green[700]
                          : Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  isBooked
                      ? 'Sudah Dipesan'
                      : isAvailable
                          ? 'Tersedia'
                          : 'Tidak Aktif',
                  style: TextStyle(
                    color: isBooked
                        ? Colors.orange[700]
                        : isAvailable
                            ? Colors.green[700]
                            : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (jadwal['kelas_name'] != null &&
                jadwal['kelas_name'].isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.class_, size: 16, color: Colors.blue[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      jadwal['kelas_name'],
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: !isBooked
            ? PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Hapus', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditJadwalDialog(jadwal);
                  } else if (value == 'delete') {
                    _confirmDelete(jadwal['id']);
                  }
                },
              )
            : null,
      ),
    );
  }

  void _confirmDelete(String jadwalId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Jadwal'),
        content: const Text('Yakin ingin menghapus jadwal ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteJadwal(jadwalId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showAddJadwalDialog() {
    _showJadwalDialog();
  }

  void _showEditJadwalDialog(Map<String, dynamic> jadwal) {
    _showJadwalDialog(existingJadwal: jadwal);
  }

  void _showJadwalDialog({Map<String, dynamic>? existingJadwal}) {
    final isEdit = existingJadwal != null;
    DateTime selectedDate =
        isEdit ? DateTime.parse(existingJadwal['tanggal']) : DateTime.now();
    TimeOfDay jamMulai = isEdit
        ? TimeOfDay(
            hour: int.parse(existingJadwal['jam_mulai'].split(':')[0]),
            minute: int.parse(existingJadwal['jam_mulai'].split(':')[1]),
          )
        : const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay jamSelesai = isEdit
        ? TimeOfDay(
            hour: int.parse(existingJadwal['jam_selesai'].split(':')[0]),
            minute: int.parse(existingJadwal['jam_selesai'].split(':')[1]),
          )
        : const TimeOfDay(hour: 10, minute: 0);
    String? selectedKelasId = existingJadwal?['kelas_id'];
    List<Map<String, dynamic>> kelasList = [];
    bool isLoadingKelas = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Load kelas list on dialog open
          if (isLoadingKelas) {
            _loadKelasList().then((list) {
              setDialogState(() {
                kelasList = list;
                isLoadingKelas = false;
              });
            });
          }

          return AlertDialog(
            title: Text(isEdit ? 'Edit Jadwal' : 'Tambah Jadwal'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kelas Dropdown
                  const Text('Pilih Kelas',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (isLoadingKelas)
                    const Center(child: CircularProgressIndicator())
                  else if (kelasList.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange[700]),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Belum ada kelas. Buat kelas terlebih dahulu.',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      value: selectedKelasId,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      hint: const Text('Pilih kelas'),
                      items: kelasList.map((kelas) {
                        return DropdownMenuItem<String>(
                          value: kelas['id'],
                          child: Text(
                            '${kelas['course_name']} - ${kelas['category']}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedKelasId = value;
                        });
                      },
                    ),
                  const SizedBox(height: 16),

                  // Date Picker
                  const Text('Tanggal',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 20),
                          const SizedBox(width: 8),
                          Text(DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
                              .format(selectedDate)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Time Picker - Start
                  const Text('Jam Mulai',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: jamMulai,
                      );
                      if (picked != null) {
                        setDialogState(() => jamMulai = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, size: 20),
                          const SizedBox(width: 8),
                          Text(jamMulai.format(context)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Time Picker - End
                  const Text('Jam Selesai',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: jamSelesai,
                      );
                      if (picked != null) {
                        setDialogState(() => jamSelesai = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, size: 20),
                          const SizedBox(width: 8),
                          Text(jamSelesai.format(context)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: kelasList.isEmpty || selectedKelasId == null
                    ? null
                    : () {
                        _saveJadwal(
                          selectedDate,
                          jamMulai,
                          jamSelesai,
                          selectedKelasId!,
                          kelasList,
                          jadwalId: existingJadwal?['id'],
                        );
                        Navigator.pop(context);
                      },
                child: Text(isEdit ? 'Simpan' : 'Tambah'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveJadwal(
    DateTime tanggal,
    TimeOfDay jamMulai,
    TimeOfDay jamSelesai,
    String kelasId,
    List<Map<String, dynamic>> kelasList, {
    String? jadwalId,
  }) async {
    try {
      final mentorUid = widget.mentorData['uid'] ?? widget.mentorData['id'];
      final jamMulaiStr =
          '${jamMulai.hour.toString().padLeft(2, '0')}:${jamMulai.minute.toString().padLeft(2, '0')}';
      final jamSelesaiStr =
          '${jamSelesai.hour.toString().padLeft(2, '0')}:${jamSelesai.minute.toString().padLeft(2, '0')}';

      // Get kelas data
      final selectedKelas = kelasList.firstWhere((k) => k['id'] == kelasId);

      final jadwalData = {
        'mentor_id': mentorUid,
        'tanggal': DateFormat('yyyy-MM-dd').format(tanggal),
        'jam_mulai': jamMulaiStr,
        'jam_selesai': jamSelesaiStr,
        'status': 'available',
        'kelas_id': kelasId,
        'kelas_name': selectedKelas['course_name'],
        'created_at': DateTime.now().toIso8601String(),
      };

      String savedJadwalId;
      if (jadwalId != null) {
        // Update existing
        await _jadwalRef.child(mentorUid).child(jadwalId).update(jadwalData);
        savedJadwalId = jadwalId;
      } else {
        // Add new
        final newRef = await _jadwalRef.child(mentorUid).push();
        savedJadwalId = newRef.key!;
        await newRef.set(jadwalData);
      }

      // Update kelas jadwal_ids array
      final kelasRef = FirebaseDatabase.instance.ref('kelas/$kelasId');
      final kelasSnapshot = await kelasRef.get();

      if (kelasSnapshot.exists) {
        final kelasData = Map<String, dynamic>.from(kelasSnapshot.value as Map);
        List<dynamic> jadwalIds = kelasData['jadwal_ids'] ?? [];

        if (!jadwalIds.contains(savedJadwalId)) {
          jadwalIds.add(savedJadwalId);
          await kelasRef.update({'jadwal_ids': jadwalIds});
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  jadwalId != null ? 'Jadwal diupdate' : 'Jadwal ditambahkan')),
        );
      }

      _loadJadwal();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error menyimpan jadwal: $e')),
        );
      }
    }
  }
}
