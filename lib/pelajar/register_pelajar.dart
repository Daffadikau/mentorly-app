import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_pelajar.dart';
import 'phone_verification_page.dart';

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
      } else if (!_phone.text.startsWith('+')) {
        errorPhone = "Format: +62xxx (gunakan kode negara)";
        isValid = false;
      } else if (_phone.text.length < 10) {
        errorPhone = "Nomor telepon terlalu pendek";
        isValid = false;
      } else {
        errorPhone = null;
      }
    });

    return isValid;
  }

  Future<void> _register() async {
    if (!validasi()) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      print('📱 Starting phone verification for: ${_phone.text}');
      
      // Start phone verification
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _phone.text.trim(),
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification (Android only)
          print('✅ Auto-verification completed');
          Navigator.pop(context); // Close loading dialog
          
          // Proceed with registration
          await _completeRegistration(credential, null);
        },
        verificationFailed: (FirebaseAuthException e) {
          print('❌ Phone verification failed: ${e.message}');
          Navigator.pop(context); // Close loading dialog
          
          String errorMessage = 'Verifikasi nomor gagal';
          if (e.code == 'invalid-phone-number') {
            errorMessage = 'Format nomor telepon tidak valid. Gunakan format: +62xxx';
          } else if (e.code == 'too-many-requests') {
            errorMessage = 'Terlalu banyak percobaan. Coba lagi nanti';
          } else {
            errorMessage = 'Error: ${e.message}';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        },
        codeSent: (String verificationId, int? resendToken) async {
          print('📨 Verification code sent');
          Navigator.pop(context); // Close loading dialog
          
          // Navigate to verification page
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PhoneVerificationPage(
                phoneNumber: _phone.text.trim(),
                verificationId: verificationId,
                email: _email.text.trim().toLowerCase(),
                password: _password.text,
                additionalData: {
                  'phone': _phone.text.trim(),
                },
              ),
            ),
          );
          
          // Handle result from verification page
          if (result != null && result['success'] == true) {
            await _completeRegistration(null, result);
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('⏱️ Auto retrieval timeout');
        },
      );
      
    } catch (e) {
      print('❌ Error starting phone verification: $e');
      Navigator.pop(context); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  Future<void> _completeRegistration(
    PhoneAuthCredential? phoneCredential,
    Map<String, dynamic>? verificationResult,
  ) async {
    try {
      print('📝 Starting registration completion...');
      final normalizedEmail = _email.text.trim().toLowerCase();
      final phoneNumber = verificationResult?['phoneNumber'] ?? _phone.text.trim();

      // 1. Create email/password account first
      print('🔐 Creating email/password account...');
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: _password.text,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Failed to create account');
      }

      print('✅ Email/password account created: ${user.uid}');

      // 2. Save user profile to RTDB
      print('💾 Saving profile to database...');
      final ref = FirebaseDatabase.instance.ref('pelajar').child(user.uid);
      
      final profileData = {
        'email': normalizedEmail,
        'phone': phoneNumber,
        'created_at': DateTime.now().toIso8601String(),
        'uid': user.uid,
        'email_verified': false,
        'phone_verified': true, // Already verified via SMS
        'auth_method': 'email', // Login uses email/password
        'phone_verification_date': DateTime.now().toIso8601String(),
      };

      await ref.set(profileData);
      
      print('✅ Profile saved to database');

      // 3. Sign out so user needs to login with email/password
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text("Registrasi Berhasil! 🎉"),
            content: const Text(
              "Nomor telepon Anda telah terverifikasi dan akun telah dibuat.\n\nSilakan login dengan email dan password Anda.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                child: const Text("Login Sekarang"),
              ),
            ],
          ),
        );
      }
      
    } catch (e) {
      print('❌ Error completing registration: $e');
      
      if (mounted) {
        String errorMessage = 'Gagal menyimpan data';
        if (e.toString().contains('email-already-in-use')) {
          errorMessage = 'Email sudah terdaftar. Silakan gunakan email lain atau login.';
        } else if (e.toString().contains('weak-password')) {
          errorMessage = 'Password terlalu lemah. Minimal 6 karakter.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
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
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: "Nomor Telepon",
                  hintText: "+62xxx (contoh: +628123456789)",
                  errorText: errorPhone,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.phone),
                  helperText: "Gunakan kode negara (+62 untuk Indonesia)",
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
