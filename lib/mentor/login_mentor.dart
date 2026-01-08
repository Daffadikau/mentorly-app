import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register_mentor.dart';
import 'dashboard_mentor.dart';
import '../utils/session_manager.dart';

class LoginMentor extends StatefulWidget {
  const LoginMentor({super.key});

  @override
  _LoginMentorState createState() => _LoginMentorState();
}

class _LoginMentorState extends State<LoginMentor> {
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

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool validasi() {
    bool isValid = true;

    setState(() {
      if (_email.text.isEmpty) {
        errorEmail = "Email tidak boleh kosong";
        isValid = false;
      } else if (!_email.text.contains("@") || !_email.text.contains(".")) {
        errorEmail = "Format email tidak valid";
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
    });

    return isValid;
  }

  Future<void> _login() async {
    if (!validasi()) return;

    setState(() {
      isLoading = true;
      errorEmail = null;
      errorPassword = null;
    });

    try {
      // 1. Lakukan Login Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
              email: _email.text.trim(), password: _password.text);

      User? user = userCredential.user;

      if (user != null) {
        // 2. CEK STATUS DI REALTIME DATABASE
        final ref = FirebaseDatabase.instance.ref('mentors').child(user.uid);
        final snapshot = await ref.get();

        if (snapshot.exists) {
          Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
          String status = data['status_verifikasi'] ?? 'pending';

          if (status == 'approved') {
            // JIKA SUDAH DI-ACC ADMIN
            await SessionManager.saveSession(
              userType: 'mentor',
              userData: Map<String, dynamic>.from(data),
            );
            
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => DashboardMentor(
                    mentorData: Map<String, dynamic>.from(data),
                  ),
                ),
              );
            }
          } else {
            // JIKA BELUM DI-ACC (Status 'pending' atau lainnya)
            await FirebaseAuth.instance.signOut(); // Paksa logout
            _showErrorDialog(
              "Akun Anda belum terverifikasi oleh kami. Mohon tunggu tim kami melakukan pengecekan berkas Anda."
            );
          }
        } else {
          // Jika data tidak ditemukan di tabel mentors
          await FirebaseAuth.instance.signOut();
          _showErrorDialog("Data mentor tidak ditemukan.");
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        loginAttempts++;
        if (e.code == 'user-not-found') {
          errorEmail = "Email tidak terdaftar";
        } else if (e.code == 'wrong-password') {
          errorPassword = "Password salah";
        } else {
          _showErrorDialog("Terjadi kesalahan: ${e.message}");
        }
      });
    } catch (e) {
      _showErrorDialog("Terjadi kesalahan sistem.");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Fungsi pembantu untuk menampilkan pesan error
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Perhatian"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
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
                "Login Mentor",
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
              const SizedBox(height: 30),
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
                    style: const TextStyle(color: Colors.orange, fontSize: 12),
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
                          builder: (context) => const RegisterMentor(),
                        ),
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
