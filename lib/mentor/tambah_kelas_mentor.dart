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
  final TextEditingController _priceController = TextEditingController();

  String? selectedCategory;
  String? selectedClass;
  double sessionDurationMinutes = 60; // default 1 jam

  bool isLoading = false;

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

  @override
  void dispose() {
    _courseNameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _simpanKelas() async {
    final priceValue = int.tryParse(_priceController.text.replaceAll('.', ''));

    if (selectedCategory == null ||
        selectedClass == null ||
        _courseNameController.text.trim().isEmpty ||
        priceValue == null ||
        priceValue <= 0) {
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
        'duration': _formatDurationLabel(sessionDurationMinutes.toInt()),
        'duration_minutes': sessionDurationMinutes.toInt(),
        'course_name': _courseNameController.text.trim(),
        'price': priceValue,
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
        'enrolled_students': 0,
        'jadwal_ids': [],
      };

      await kelasRef.push().set(kelasData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Kelas berhasil ditambahkan!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF5B6BC4),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Apa Yang Ingin Anda Ajarkan Hari Ini',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Kategori'),
            const SizedBox(height: 8),
            _buildDropdown(
              hint: 'contoh: Biologi',
              value: selectedCategory,
              items: categories,
              onChanged: (value) => setState(() => selectedCategory = value),
            ),
            const SizedBox(height: 20),
            _buildLabel('Tingkat Kelas'),
            const SizedBox(height: 8),
            _buildDropdown(
              hint: 'contoh: SMP Kelas 8',
              value: selectedClass,
              items: classes,
              onChanged: (value) => setState(() => selectedClass = value),
            ),
            const SizedBox(height: 20),
            _buildLabel('Durasi per Sesi'),
            const SizedBox(height: 8),
            _buildDurationSlider(),
            const SizedBox(height: 20),
            _buildLabel('Harga per Sesi (Rp)'),
            const SizedBox(height: 8),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'contoh: 150000',
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
            ),
            const SizedBox(height: 20),
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
    );
  }

  Widget _buildDurationSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDurationLabel(sessionDurationMinutes.toInt()),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Text(
              'Interval 15 menit',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
        Slider(
          value: sessionDurationMinutes,
          min: 30,
          max: 300,
          divisions: 18,
          activeColor: const Color(0xFF5B6BC4),
          inactiveColor: Colors.grey[300],
          label: _formatDurationLabel(sessionDurationMinutes.toInt()),
          onChanged: (value) => setState(() => sessionDurationMinutes = value),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('30 menit', style: TextStyle(fontSize: 12)),
            Text('5 jam', style: TextStyle(fontSize: 12)),
          ],
        ),
      ],
    );
  }

  String _formatDurationLabel(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours == 0) return '$mins menit';
    if (mins == 0) return '$hours jam';
    return '$hours jam $mins menit';
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
