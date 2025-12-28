import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:file_picker/file_picker.dart';
import 'verifikasi_pending.dart';

class RegisterMentor extends StatefulWidget {
  const RegisterMentor({super.key});

  @override
  _RegisterMentorState createState() => _RegisterMentorState();
}

class _RegisterMentorState extends State<RegisterMentor> {
  final TextEditingController _namaLengkap = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();
  final TextEditingController _nik = TextEditingController();
  final TextEditingController _keahlianLain = TextEditingController();
  final TextEditingController _linkedin = TextEditingController();

  String selectedKeahlian = "IPA";
  String selectedKelamin = "Male";

  bool isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // File upload variables
  String? _selectedPendidikan;
  String? _selectedKTP;
  String? _selectedSKCK;
  String? _selectedSertifikat;

  @override
  void dispose() {
    _namaLengkap.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _nik.dispose();
    _keahlianLain.dispose();
    _linkedin.dispose();
    super.dispose();
  }

  bool validasi() {
    if (_namaLengkap.text.trim().isEmpty) {
      _showError("Nama lengkap tidak boleh kosong");
      return false;
    }

    if (_namaLengkap.text.trim().length < 3) {
      _showError("Nama lengkap minimal 3 karakter");
      return false;
    }

    if (_email.text.trim().isEmpty) {
      _showError("Email tidak boleh kosong");
      return false;
    }

    if (!_email.text.contains("@") || !_email.text.contains(".")) {
      _showError("Format email tidak valid");
      return false;
    }

    if (_password.text.isEmpty) {
      _showError("Password tidak boleh kosong");
      return false;
    }

    if (_password.text.length < 6) {
      _showError("Password minimal 6 karakter");
      return false;
    }

    if (_confirmPassword.text.isEmpty) {
      _showError("Konfirmasi password tidak boleh kosong");
      return false;
    }

    if (_password.text != _confirmPassword.text) {
      _showError("Password tidak cocok");
      return false;
    }

    if (_nik.text.trim().isEmpty) {
      _showError("NIK tidak boleh kosong");
      return false;
    }

    if (_nik.text.trim().length != 16) {
      _showError("NIK harus 16 digit");
      return false;
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(_nik.text.trim())) {
      _showError("NIK hanya boleh berisi angka");
      return false;
    }

    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _register() async {
    if (!validasi()) return;

    setState(() {
      isLoading = true;
    });

    try {
      final ref = FirebaseDatabase.instance.ref('mentor');
      final newRef = ref.push();

      final mentor = {
        'nama_lengkap': _namaLengkap.text.trim(),
        'email': _email.text.trim(),
        'password': _password.text,
        'nik': _nik.text.trim(),
        'keahlian': selectedKeahlian,
        'kelamin': selectedKelamin,
        'keahlian_lain': _keahlianLain.text.trim(),
        'linkedin': _linkedin.text.trim(),
        'status_verifikasi': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      };

      await newRef.set(mentor);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Registrasi berhasil. Menunggu verifikasi..."),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => VerifikasiPending()),
        );
      }
    } catch (e) {
      _showError("Registrasi gagal: $e");
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
        title: const Text(
          "Verifikasi Biodata Pengajar",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
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
            _buildTextField(
              "Nama Lengkap *",
              _namaLengkap,
              "Muhammad Rhyno Fazar Fahmi",
              TextInputType.name,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              "NIK (Nomor Induk Kewarganegaraan) *",
              _nik,
              "3173012312312322",
              TextInputType.number,
              maxLength: 16,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              "Email *",
              _email,
              "email@example.com",
              TextInputType.emailAddress,
            ),
            const SizedBox(height: 15),
            _buildPasswordField(
              "Password *",
              _password,
              _obscurePassword,
              () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            const SizedBox(height: 15),
            _buildPasswordField(
              "Konfirmasi Password *",
              _confirmPassword,
              _obscureConfirmPassword,
              () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
            const SizedBox(height: 15),
            _buildDropdown(
              "Keahlian Utama *",
              selectedKeahlian,
              ["IPA", "IPS", "Matematika", "Bahasa", "Seni"],
              (value) => setState(() => selectedKeahlian = value!),
            ),
            const SizedBox(height: 15),
            _buildDropdown(
              "Kelamin *",
              selectedKelamin,
              ["Male", "Female"],
              (value) => setState(() => selectedKelamin = value!),
            ),
            const SizedBox(height: 15),
            _buildTextField(
              "Keahlian Lain",
              _keahlianLain,
              "Algebraic Equations and Expressions",
              TextInputType.text,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              "Link Linkedin (CV)",
              _linkedin,
              "linkedin.com/in/yourprofile",
              TextInputType.url,
            ),
            const SizedBox(height: 15),
            _buildFileUpload("Hasil Pendidikan Terakhir (Pdf, file)", "pendidikan"),
            const SizedBox(height: 15),
            _buildFileUpload("KTP (Pdf, file)", "ktp"),
            const SizedBox(height: 15),
            _buildFileUpload("SKCK (Scan Keterangan Catatan Kepolisian)", "skck"),
            const SizedBox(height: 15),
            _buildFileUpload("Sertifikat (*opsional)", "sertifikat"),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  disabledBackgroundColor: Colors.grey,
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
                        "Upload!",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
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
    String hint,
    TextInputType keyboardType, {
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            counterText: "",
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(
    String label,
    TextEditingController controller,
    bool obscure,
    VoidCallback onToggle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
              onPressed: onToggle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildFileUpload(String label, String fileType) {
    String? selectedFile;
    
    // Get the selected file for this type
    switch (fileType) {
      case "pendidikan":
        selectedFile = _selectedPendidikan;
        break;
      case "ktp":
        selectedFile = _selectedKTP;
        break;
      case "skck":
        selectedFile = _selectedSKCK;
        break;
      case "sertifikat":
        selectedFile = _selectedSertifikat;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: () async {
            FilePickerResult? result = await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
            );

            if (result != null) {
              setState(() {
                switch (fileType) {
                  case "pendidikan":
                    _selectedPendidikan = result.files.single.name;
                    break;
                  case "ktp":
                    _selectedKTP = result.files.single.name;
                    break;
                  case "skck":
                    _selectedSKCK = result.files.single.name;
                    break;
                  case "sertifikat":
                    _selectedSertifikat = result.files.single.name;
                    break;
                }
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              border: Border.all(
                color: selectedFile != null ? Colors.green : Colors.grey,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.attach_file,
                  color: selectedFile != null ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    selectedFile ?? "Add Media",
                    style: TextStyle(
                      color: selectedFile != null ? Colors.black : Colors.grey,
                      fontWeight: selectedFile != null
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.upload_file,
                  color: selectedFile != null ? Colors.green : Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
