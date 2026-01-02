import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class TambahKelasMentor extends StatefulWidget {
  final Map<String, dynamic> mentorData;

  const TambahKelasMentor({super.key, required this.mentorData});

  @override
  State<TambahKelasMentor> createState() => _TambahKelasMentorState();
}

class _TambahKelasMentorState extends State<TambahKelasMentor> {
  final TextEditingController _courseNameController = TextEditingController();
  
  String? selectedCategory;
  String? selectedClass;
  String? selectedDuration;
  
  bool isLoading = false;

  // Data untuk dropdown
  final List<String> categories = [
    'IPA (Sains)',
    'IPS (Sosial)',
    'Matematika',
    'Bahasa Indonesia',
    'Bahasa Inggris',
    'Fisika',
    'Kimia',
    'Biologi',
    'Sejarah',
    'Geografi',
    'Ekonomi',
    'Pemrograman',
    'Desain',
    'Bisnis',
    'Lainnya',
  ];

  final List<String> classes = [
    'SD Kelas 1',
    'SD Kelas 2',
    'SD Kelas 3',
    'SD Kelas 4',
    'SD Kelas 5',
    'SD Kelas 6',
    'SMP Kelas 7',
    'SMP Kelas 8',
    'SMP Kelas 9',
    'SMA Kelas 10',
    'SMA Kelas 11',
    'SMA Kelas 12',
    'Universitas',
    'Umum / Semua Level',
  ];

  final List<String> durations = [
    '30 menit',
    '1 jam',
    '1.5 jam',
    '2 jam',
    '2.5 jam',
    '3 jam',
    '3.5 jam',
    '4 jam',
    '4.5 jam',
    '5 jam',
  ];

  @override
  void dispose() {
    _courseNameController.dispose();
    super.dispose();
  }

  Future<void> _simpanKelas() async {
    if (selectedCategory == null ||
        selectedClass == null ||
        selectedDuration == null ||
        _courseNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon lengkapi semua field'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final mentorUid = widget.mentorData['uid'] ?? widget.mentorData['id'];
      final kelasRef = FirebaseDatabase.instance.ref('kelas');

      final kelasData = {
        'mentor_uid': mentorUid,
        'mentor_name': widget.mentorData['nama_lengkap'] ?? 'Mentor',
        'category': selectedCategory,
        'class_level': selectedClass,
        'duration': selectedDuration,
        'course_name': _courseNameController.text.trim(),
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
        'enrolled_students': 0,
        'jadwal_ids': [], // Array untuk menyimpan jadwal yang dipilih
      };

      await kelasRef.push().set(kelasData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Kelas berhasil ditambahkan!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
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
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Blue curved header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 280,
              decoration: BoxDecoration(
                color: const Color(0xFF5B6BC4),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(200),
                  bottomRight: Radius.circular(200),
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Back button
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Title
                    const Text(
                      'Apa Yang Ingin Anda\nAjarkan Hari Ini',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Form content
          Positioned(
            top: 260,
            left: 0,
            right: 0,
            bottom: 0,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kategori
                  _buildLabel('Kategori'),
                  const SizedBox(height: 8),
                  _buildDropdown(
                    hint: 'contoh: Biologi',
                    value: selectedCategory,
                    items: categories,
                    onChanged: (value) {
                      setState(() => selectedCategory = value);
                    },
                  ),
                  const SizedBox(height: 20),

                  // Kelas
                  _buildLabel('Tingkat Kelas'),
                  const SizedBox(height: 8),
                  _buildDropdown(
                    hint: 'contoh: SMP Kelas 8',
                    value: selectedClass,
                    items: classes,
                    onChanged: (value) {
                      setState(() => selectedClass = value);
                    },
                  ),
                  const SizedBox(height: 20),

                  // Durasi
                  _buildLabel('Durasi per Sesi'),
                  const SizedBox(height: 8),
                  _buildDropdown(
                    hint: 'contoh: 2 jam',
                    value: selectedDuration,
                    items: durations,
                    onChanged: (value) {
                      setState(() => selectedDuration = value);
                    },
                  ),
                  const SizedBox(height: 20),

                  // Nama Kelas
                  _buildLabel('Nama Kelas Anda?'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _courseNameController,
                    decoration: InputDecoration(
                      hintText: 'contoh: bagaimana tumbuhan berfotosintesis',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 40),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _simpanKelas,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B6BC4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Buat Kelas Anda',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        hint: Text(
          hint,
          style: TextStyle(color: Colors.grey[400], fontSize: 14),
        ),
        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item, style: const TextStyle(fontSize: 14)),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
