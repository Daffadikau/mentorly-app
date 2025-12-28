import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_pelajar.dart';
import 'dashboard_pelajar.dart';
import '../utils/session_manager.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _phone = TextEditingController();

  String? errorEmail;
  String? errorPassword;
  String? errorPhone;

  bool validasi() {
    bool isValid = true;

    setState(() {
      if (_email.text.isEmpty) {
        errorEmail = "Email tidak boleh kosong";
        isValid = false;
      } else if (!_email.text.contains("@")) {
        errorEmail = "Email tidak valid";
        isValid = false;
      } else {
        errorEmail = null;
      }

      if (_password.text.isEmpty) {
        errorPassword = "Password tidak boleh kosong";
        isValid = false;
      } else if (_password.text.length < 6) {
        errorPassword = "Password minimal 6 karakter";
        isValid = false;
      } else {
        errorPassword = null;
      }

      if (_phone.text.isEmpty) {
        errorPhone = "Nomor telepon tidak boleh kosong";
        isValid = false;
      } else {
        errorPhone = null;
      }
    });

    return isValid;
  }

  Future<void> _register() async {
    if (!validasi()) return;

    try {
      // Create Firebase Auth account
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email.text.trim().toLowerCase(),
        password: _password.text,
      );

      final uid = userCredential.user!.uid;
      final user = userCredential.user!;

      // 1. Send Email Verification
      await user.sendEmailVerification();

      // Save user profile to RTDB
      final ref = FirebaseDatabase.instance.ref('pelajar').child(uid);

      final normalizedEmail = _email.text.trim().toLowerCase();
      final profileData = {
        'email': normalizedEmail,
        'phone': _phone.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
        'uid': uid,
        'email_verified': false,
      };

      await ref.set(profileData);

      // 2. Sign out immediately so they can't access dashboard yet
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        // 3. Show Verification Dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text("Verifikasi Email"),
            content: Text(
                "Link verifikasi telah dikirim ke ${_email.text}. Silakan cek email Anda untuk mengaktifkan akun sebelum login."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                child: const Text("Ke Halaman Login"),
              ),
            ],
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Gagal registrasi';
      if (e.code == 'weak-password') {
        errorMessage = 'Password terlalu lemah';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Email sudah terdaftar';
      } else if (e.code == 'configuration-not-found' ||
          e.code == 'operation-not-allowed') {
        errorMessage =
            'Login Email/Password belum diaktifkan di Firebase Console';
      } else {
        errorMessage = 'Gagal (${e.code}): ${e.message}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.blue[700]),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(height: 40),
              Image.asset(
                'assets/images/logodoang.png',
                width: 150,
                height: 150,
              ),
              const SizedBox(height: 20),
              const Text(
                "Siap untuk naik level?",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Text(
                "Daftar Mentorly sekarang!",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              const Text(
                "Register",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _email,
                decoration: InputDecoration(
                  labelText: "Email",
                  hintText: "Email",
                  errorText: errorEmail,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Password",
                  hintText: "Password",
                  errorText: errorPassword,
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.visibility_off),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _phone,
                decoration: InputDecoration(
                  labelText: "Phone Number",
                  hintText: "Phone Number",
                  errorText: errorPhone,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Sign Up",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Punya Akun? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginPage()),
                      );
                    },
                    child: Text(
                      "Login",
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
