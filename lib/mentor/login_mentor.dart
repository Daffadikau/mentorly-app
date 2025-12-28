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
      final user = userCredential.user!;

      // Check if email is verified
      if (!user.emailVerified) {
        if (mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text("Verifikasi Diperlukan"),
              content: const Text(
                  "Email Anda belum terverifikasi.\n\n1. Cek Inbox/Spam email Anda.\n2. Klik link verifikasi.\n3. Kembali ke sini dan tekan tombol di bawah."),
              actions: [
                TextButton(
                  onPressed: () async {
                    // Resend verification email
                    try {
                      await user.sendEmailVerification();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Email verifikasi dikirim ulang!")),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Gagal mengirim ulang: $e")),
                        );
                      }
                    }
                  },
                  child: const Text("Kirim Ulang"),
                ),
                TextButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await user.reload();
                    if (FirebaseAuth.instance.currentUser?.emailVerified ==
                        true) {
                      if (context.mounted) Navigator.pop(context);
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                "Belum terverifikasi. Silakan cek email lagi."),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text("Saya Sudah Verifikasi"),
                ),
              ],
            ),
          );

          // Re-check after dialog closes
          await user.reload();
          if (FirebaseAuth.instance.currentUser?.emailVerified != true) {
            await FirebaseAuth.instance.signOut();
            if (mounted) {
              setState(() {
                isLoading = false;
              });
            }
            return;
          }
        }
      }

      // Fetch mentor profile from RTDB
      final ref = FirebaseDatabase.instance.ref('mentor').child(uid);
      final snapshot = await ref.get();

      if (!snapshot.exists) {
        // Profile doesn't exist, create basic profile
        final profileData = {
          'email': _email.text.trim().toLowerCase(),
          'uid': uid,
          'created_at': DateTime.now().toIso8601String(),
          'status_verifikasi': 'pending',
        };
        await ref.set(profileData);
      }

      final mentorData =
          Map<String, dynamic>.from(snapshot.value as Map? ?? {});
      mentorData['id'] = uid;
      mentorData['uid'] = uid;

      // Check verification status
      if (mentorData['status_verifikasi'] != 'verified') {
        await FirebaseAuth.instance.signOut();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Akun Anda masih dalam proses verifikasi"),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
        setState(() {
          isLoading = false;
        });
        return;
      }

      loginAttempts = 0;

      await SessionManager.saveSession(
        userType: 'mentor',
        userData: mentorData,
      );

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
            builder: (context) => DashboardMentor(mentorData: mentorData),
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
