import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../common/welcome_page.dart';
import '../utils/session_manager.dart';

import '../common/api_config.dart';

class ProfileMentor extends StatefulWidget {
  final Map<String, dynamic> mentorData;

  const ProfileMentor({super.key, required this.mentorData});

  @override
  _ProfileMentorState createState() => _ProfileMentorState();
}

class _ProfileMentorState extends State<ProfileMentor> {
  late TextEditingController _namaController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _keahlianUtamaController;
  late TextEditingController _keahlianLainController;
  late TextEditingController _linkedinController;
  late TextEditingController _deskripsiController;

  bool isEditing = false;
  bool _obscurePassword = true;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _validateSession();
    _namaController =
        TextEditingController(text: widget.mentorData['nama_lengkap'] ?? '');
    _emailController = TextEditingController(text: widget.mentorData['email']);
    _passwordController = TextEditingController();
    _keahlianUtamaController =
        TextEditingController(text: widget.mentorData['keahlian_utama'] ?? '');
    _keahlianLainController =
        TextEditingController(text: widget.mentorData['keahlian_lain'] ?? '');
    _linkedinController =
        TextEditingController(text: widget.mentorData['linkedin_url'] ?? '');
    _deskripsiController =
        TextEditingController(text: widget.mentorData['deskripsi'] ?? '');
  }

  Future<void> _validateSession() async {
    bool isValid = await SessionManager.validateSession();
    if (!isValid && mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  bool _validateInput() {
    if (_namaController.text.trim().isEmpty) {
      _showError("Nama tidak boleh kosong");
      return false;
    }

    if (_emailController.text.trim().isEmpty) {
      _showError("Email tidak boleh kosong");
      return false;
    }

    if (!_emailController.text.contains("@")) {
      _showError("Format email tidak valid");
      return false;
    }

    if (_keahlianUtamaController.text.trim().isEmpty) {
      _showError("Keahlian utama tidak boleh kosong");
      return false;
    }

    if (_passwordController.text.isNotEmpty) {
      if (_passwordController.text.length < 6) {
        _showError("Password minimal 6 karakter");
        return false;
      }
      if (_passwordController.text.length > 50) {
        _showError("Password terlalu panjang");
        return false;
      }
    }

    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> updateProfile() async {
    if (!_validateInput()) return;

    setState(() {
      isLoading = true;
    });

    String uri = ApiConfig.getUrl('update_profile_mentor.php');

    var body = {
      "itemid": widget.mentorData['id'].toString(),
      "itemnama": _namaController.text.trim(),
      "itememail": _emailController.text.trim(),
      "itemkeahlianutama": _keahlianUtamaController.text.trim(),
      "itemkeahlianlain": _keahlianLainController.text.trim(),
      "itemlinkedin": _linkedinController.text.trim(),
      "itemdeskripsi": _deskripsiController.text.trim(),
    };

    if (_passwordController.text.isNotEmpty) {
      body["itempassword"] = _passwordController.text;
    }

    try {
      var response = await http
          .post(
            Uri.parse(uri),
            body: body,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          // Update local data
          widget.mentorData['nama_lengkap'] = _namaController.text.trim();
          widget.mentorData['email'] = _emailController.text.trim();
          widget.mentorData['keahlian_utama'] =
              _keahlianUtamaController.text.trim();
          widget.mentorData['keahlian_lain'] =
              _keahlianLainController.text.trim();
          widget.mentorData['linkedin_url'] = _linkedinController.text.trim();
          widget.mentorData['deskripsi'] = _deskripsiController.text.trim();

          // Update session
          await SessionManager.saveSession(
            userType: 'mentor',
            userData: widget.mentorData,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Profil berhasil diupdate"),
                backgroundColor: Colors.green,
              ),
            );
            setState(() {
              isEditing = false;
              _passwordController.clear();
            });
          }
        } else {
          _showError(data['message'] ?? "Update gagal");
        }
      }
    } catch (e) {
      _showError("Koneksi gagal. Periksa internet Anda.");
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
        title: const Text("Profil Pengajar",
            style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header dengan foto profil
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.blue[700],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person,
                            size: 60, color: Colors.blue[700]),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text("Fitur ganti foto akan segera hadir"),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              color: Colors.blue[700],
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Ganti Foto Profil",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
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
                  // Info banner
                  if (!isEditing)
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700]),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Tap tombol Edit untuk mengubah informasi profil Anda",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 25),

                  // Nama Lengkap
                  _buildTextField(
                    "Nama Lengkap",
                    _namaController,
                    Icons.person_outline,
                  ),
                  const SizedBox(height: 20),

                  // Email
                  _buildTextField(
                    "Email",
                    _emailController,
                    Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),

                  // Password (hanya saat edit)
                  if (isEditing) ...[
                    Text(
                      "Password",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        hintText: "Kosongkan jika tidak ingin mengubah",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ] else ...[
                    Text(
                      "Password",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: TextEditingController(text: "•••••"),
                      enabled: false,
                      obscureText: true,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Keahlian Utama
                  _buildTextField(
                    "Keahlian Utama",
                    _keahlianUtamaController,
                    Icons.school_outlined,
                  ),
                  const SizedBox(height: 20),

                  // Keahlian Lain
                  _buildTextField(
                    "Keahlian Lain",
                    _keahlianLainController,
                    Icons.lightbulb_outline,
                  ),
                  const SizedBox(height: 20),

                  // Link LinkedIn
                  _buildTextField(
                    "Link Linkedin (Url)",
                    _linkedinController,
                    Icons.link,
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 20),

                  // Deskripsi
                  Text(
                    "Deskripsi",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _deskripsiController,
                    enabled: isEditing,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: "Ceritakan tentang diri Anda...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: isEditing ? Colors.white : Colors.grey[100],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Tombol Edit/Simpan/Batal
                  if (!isEditing)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            isEditing = true;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Simpan",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: OutlinedButton(
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      setState(() {
                                        isEditing = false;
                                        _namaController.text =
                                            widget.mentorData['nama_lengkap'] ??
                                                '';
                                        _emailController.text =
                                            widget.mentorData['email'];
                                        _keahlianUtamaController.text = widget
                                                .mentorData['keahlian_utama'] ??
                                            '';
                                        _keahlianLainController.text = widget
                                                .mentorData['keahlian_lain'] ??
                                            '';
                                        _linkedinController.text =
                                            widget.mentorData['linkedin_url'] ??
                                                '';
                                        _deskripsiController.text =
                                            widget.mentorData['deskripsi'] ??
                                                '';
                                        _passwordController.clear();
                                      });
                                    },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.grey),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text("Batal"),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : updateProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[700],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      "Simpan",
                                      style: TextStyle(
                                          fontSize: 16, color: Colors.white),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 15),
                  const Divider(),
                  const SizedBox(height: 15),

                  // Tombol Logout
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () async {
                        bool? confirm = await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Konfirmasi Keluar"),
                            content: const Text(
                                "Apakah Anda yakin ingin keluar dari akun?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text("Batal"),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text("Keluar",
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await SessionManager.logout();
                          if (mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const WelcomePage()),
                              (route) => false,
                            );
                          }
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "LOG OUT",
                        style: TextStyle(fontSize: 16, color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: isEditing,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            filled: true,
            fillColor: isEditing ? Colors.white : Colors.grey[100],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _keahlianUtamaController.dispose();
    _keahlianLainController.dispose();
    _linkedinController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }
}
