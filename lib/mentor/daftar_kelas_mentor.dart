import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

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
        data.forEach((key, value) {
          if (value is Map) {
            allJadwal.add({
              'id': key,
              ...Map<String, dynamic>.from(value),
            });
          }
        });
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => _ManageJadwalDialog(
        allJadwal: allJadwal,
        currentJadwalIds: currentJadwalIds,
        kelasId: kelas['id'],
        kelasName: kelas['course_name'] ?? 'Kelas',
        mentorUid: mentorUid,
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
  final VoidCallback onUpdated;

  const _ManageJadwalDialog({
    required this.allJadwal,
    required this.currentJadwalIds,
    required this.kelasId,
    required this.kelasName,
    required this.mentorUid,
    required this.onUpdated,
  });

  @override
  State<_ManageJadwalDialog> createState() => _ManageJadwalDialogState();
}

class _ManageJadwalDialogState extends State<_ManageJadwalDialog> {
  late Set<String> selectedJadwalIds;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    selectedJadwalIds = Set<String>.from(widget.currentJadwalIds);
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
        child: widget.allJadwal.isEmpty
            ? const Center(
                child: Text('Tidak ada jadwal tersedia'),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: widget.allJadwal.length,
                itemBuilder: (context, index) {
                  final jadwal = widget.allJadwal[index];
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
                      jadwal['mata_pelajaran'] ?? 'Mata Pelajaran',
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
                          '${jadwal['hari']} - ${jadwal['jam_mulai']} - ${jadwal['jam_selesai']}',
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
                        Icons.schedule,
                        color:
                            isSelected ? const Color(0xFF5B6BC4) : Colors.grey,
                        size: 20,
                      ),
                    ),
                    activeColor: const Color(0xFF5B6BC4),
                  );
                },
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
