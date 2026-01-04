import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import '../common/welcome_page.dart';
import '../utils/session_manager.dart';

class ProfilePelajar extends StatefulWidget {
  final Map<String, dynamic> pelajarData;

  const ProfilePelajar({super.key, required this.pelajarData});

  @override
  _ProfilePelajarState createState() => _ProfilePelajarState();
}

class _ProfilePelajarState extends State<ProfilePelajar> {
  late TextEditingController _namaController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;

  bool isEditing = false;
  bool _obscurePassword = true;
  bool isLoading = false;
  bool isUploadingPhoto = false;
  String? profilePhotoUrl;

  @override
  void initState() {
    super.initState();
    _validateSession();
    profilePhotoUrl = widget.pelajarData['profile_photo_url'];
    _namaController = TextEditingController(
        text: widget.pelajarData['nama'] ??
            widget.pelajarData['nama_lengkap'] ??
            '');
    _emailController =
        TextEditingController(text: widget.pelajarData['email'] ?? '');
    _phoneController =
        TextEditingController(text: widget.pelajarData['phone'] ?? '');
    _passwordController = TextEditingController();
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

    if (_phoneController.text.trim().isNotEmpty) {
      if (_phoneController.text.length < 10) {
        _showError("Nomor telepon tidak valid");
        return false;
      }
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

    try {
      final ref =
          FirebaseDatabase.instance.ref('pelajar/${widget.pelajarData['id']}');

      final updates = {
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
      };

      if (_namaController.text.trim().isNotEmpty) {
        updates['nama'] = _namaController.text.trim();
        updates['nama_lengkap'] = _namaController.text.trim();
      }

      if (_passwordController.text.isNotEmpty) {
        updates['password'] = _passwordController.text;
      }

      await ref.update(updates);

      // Update local data
      widget.pelajarData['email'] = _emailController.text.trim();
      widget.pelajarData['phone'] = _phoneController.text.trim();
      if (_namaController.text.trim().isNotEmpty) {
        widget.pelajarData['nama'] = _namaController.text.trim();
        widget.pelajarData['nama_lengkap'] = _namaController.text.trim();
      }

      // Update session
      await SessionManager.saveSession(
        userType: 'pelajar',
        userData: widget.pelajarData,
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
    } catch (e) {
      _showError("Update gagal: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _uploadProfilePhoto() async {
    try {
      // Pick image file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null) return;

      setState(() {
        isUploadingPhoto = true;
      });

      final file = result.files.single;
      final uid = widget.pelajarData['uid'] ?? widget.pelajarData['id'];

      if (uid == null) {
        _showError("User ID tidak ditemukan");
        return;
      }

      // Upload to Firebase Storage
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_photos/$uid/${file.name}');

      final uploadTask =
          kIsWeb ? ref.putData(file.bytes!) : ref.putFile(File(file.path!));

      final snapshot = await uploadTask.whenComplete(() => null);
      final downloadURL = await snapshot.ref.getDownloadURL();

      // Update Firebase RTDB
      await FirebaseDatabase.instance
          .ref('pelajar')
          .child(uid)
          .update({'profile_photo_url': downloadURL});

      // Update local state and session
      setState(() {
        profilePhotoUrl = downloadURL;
        widget.pelajarData['profile_photo_url'] = downloadURL;
      });

      await SessionManager.saveSession(
        userType: 'pelajar',
        userData: widget.pelajarData,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Foto profil berhasil diupdate"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError("Gagal mengupload foto: $e");
    } finally {
      if (mounted) {
        setState(() {
          isUploadingPhoto = false;
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
        title: const Text("Profil", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
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
                      profilePhotoUrl != null && profilePhotoUrl!.isNotEmpty
                          ? CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.white,
                              child: ClipOval(
                                child: Image.network(
                                  profilePhotoUrl!,
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(Icons.person,
                                        size: 60, color: Colors.blue[700]);
                                  },
                                ),
                              ),
                            )
                          : CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.white,
                              child: Icon(Icons.person,
                                  size: 60, color: Colors.blue[700]),
                            ),
                      if (isUploadingPhoto)
                        Positioned.fill(
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.black54,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: isUploadingPhoto ? null : _uploadProfilePhoto,
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
                  const SizedBox(height: 15),
                  Text(
                    widget.pelajarData['nama'] ??
                        widget.pelajarData['nama_lengkap'] ??
                        'Pelajar',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    widget.pelajarData['email'] ?? 'email@example.com',
                    style: const TextStyle(
                      color: Colors.white70,
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
                              "Klik tombol Edit Profil untuk mengubah informasi Anda",
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
                  const Text(
                    "Informasi Pribadi",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    "Nama Lengkap",
                    _namaController,
                    Icons.person_outline,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    "Email",
                    _emailController,
                    Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    "Nomor Telepon",
                    _phoneController,
                    Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  if (isEditing) ...[
                    const SizedBox(height: 20),
                    Text(
                      "Password Baru (Opsional)",
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
                  ],
                  const SizedBox(height: 30),
                  if (!isEditing)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            isEditing = true;
                          });
                        },
                        icon: const Icon(Icons.edit, color: Colors.white),
                        label: const Text(
                          "Edit Profil",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
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
                                            widget.pelajarData['nama'];
                                        _emailController.text =
                                            widget.pelajarData['email'];
                                        _phoneController.text =
                                            widget.pelajarData['phone'] ?? '';
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
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
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
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text(
                        "Keluar",
                        style: TextStyle(fontSize: 16, color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
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
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
