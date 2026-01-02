import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register_pelajar.dart';
import 'dashboard_pelajar.dart';
import '../utils/session_manager.dart';
import '../services/notification_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  String? errorEmail;
  String? errorPassword;
  bool isLoading = false;
  bool _obscurePassword = true;
  int loginAttempts = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precache logo image to prevent freeze when keyboard appears
    precacheImage(const AssetImage('assets/images/logodoang.png'), context);
  }

  bool validasi() {
    bool isValid = true;
    setState(() {
      final emailText = _email.text.trim();
      final passText = _password.text;

      if (emailText.isEmpty || !emailText.contains('@')) {
        errorEmail = 'Email tidak valid';
        isValid = false;
      } else {
        errorEmail = null;
      }

      if (passText.isEmpty || passText.length < 4) {
        errorPassword = 'Password minimal 4 karakter';
        isValid = false;
      } else {
        errorPassword = null;
      }
    });
    return isValid;
  }

  Future<void> _login() async {
    if (!validasi()) return;

    if (loginAttempts >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Terlalu banyak percobaan login. Coba lagi nanti."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Firebase Auth login
      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim().toLowerCase(),
        password: _password.text,
      );

      final uid = userCredential.user!.uid;

      print('✅ Login successful: $uid');

      // No email verification needed - phone already verified during registration

      // Fetch user profile from RTDB
      final ref = FirebaseDatabase.instance.ref('pelajar').child(uid);
      final snapshot = await ref.get();

      if (!snapshot.exists) {
        // Create profile if doesn't exist
        final profileData = {
          'email': _email.text.trim().toLowerCase(),
          'uid': uid,
          'created_at': DateTime.now().toIso8601String(),
        };
        await ref.set(profileData);
      }

      final pelajarData =
          Map<String, dynamic>.from(snapshot.value as Map? ?? {});
      pelajarData['id'] = uid;
      pelajarData['uid'] = uid;

      // Phone already verified during registration - no need to sync email_verified

      loginAttempts = 0;

      await SessionManager.saveSession(
        userType: 'pelajar',
        userData: pelajarData,
      );

      // Save FCM token for push notifications
      try {
        String userId = pelajarData['uid'] ?? pelajarData['id'].toString();
        await NotificationService.saveFCMToken(userId, 'pelajar');
        print('✅ FCM token saved for pelajar: $userId');
      } catch (e) {
        print('❌ Error saving FCM token: $e');
        // Don't show error to user, continue with login
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Login Berhasil!"),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardPelajar(userData: pelajarData),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      loginAttempts++;
      String errorMessage = "Email atau password salah";

      if (e.code == 'user-not-found') {
        errorMessage = "Akun tidak ditemukan";
      } else if (e.code == 'wrong-password') {
        errorMessage = "Password salah";
      } else if (e.code == 'too-many-requests') {
        errorMessage = "Terlalu banyak percobaan. Coba lagi nanti.";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = "Koneksi gagal. Periksa internet Anda.";
        if (e.toString().contains("timeout")) {
          errorMessage = "Koneksi timeout. Coba lagi.";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
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
      resizeToAvoidBottomInset: true,
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
              const SizedBox(height: 20),
              Image.asset(
                'assets/images/logodoang.png',
                width: 120,
                height: 120,
                cacheWidth: 240,
                cacheHeight: 240,
              ),
              const SizedBox(height: 20),
              const Text(
                "Selamat Datang Kembali,",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Text(
                "Pelajar.",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Login",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: "Email",
                  hintText: "email@example.com",
                  errorText: errorEmail,
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _password,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _login(),
                decoration: InputDecoration(
                  labelText: "Password",
                  errorText: errorPassword,
                  prefixIcon: const Icon(Icons.lock_outlined),
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Fitur reset password akan segera hadir"),
                      ),
                    );
                  },
                  child: Text(
                    "Lupa password?",
                    style: TextStyle(color: Colors.blue[700]),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _login,
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
                          "Login",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
              ),
              if (loginAttempts > 0 && loginAttempts < 5)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    "Percobaan login: $loginAttempts/5",
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Belum punya akun? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const RegisterPage()),
                      );
                    },
                    child: Text(
                      "Register",
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
