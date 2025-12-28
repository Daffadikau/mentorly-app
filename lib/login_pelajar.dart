import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'register_pelajar.dart';
import 'dashboard_pelajar.dart';
import 'session_manager.dart';

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
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool validasi() {
    bool isValid = true;

    setState(() {
      // Validasi email
      if (_email.text.isEmpty) {
        errorEmail = "Email tidak boleh kosong";
        isValid = false;
      } else if (!_email.text.contains("@") || !_email.text.contains(".")) {
        errorEmail = "Format email tidak valid";
        isValid = false;
      } else if (_email.text.length > 100) {
        errorEmail = "Email terlalu panjang";
        isValid = false;
      } else {
        errorEmail = null;
      }

      // Validasi password
      if (_password.text.isEmpty) {
        errorPassword = "Password tidak boleh kosong";
        isValid = false;
      } else if (_password.text.length < 6) {
        errorPassword = "Password minimal 6 karakter";
        isValid = false;
      } else if (_password.text.length > 50) {
        errorPassword = "Password terlalu panjang";
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
      final ref = FirebaseDatabase.instance.ref('pelajar');
      final query = ref.orderByChild('email').equalTo(_email.text.trim());
      
      final snapshot = await query.get().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception("Koneksi timeout");
        },
      );

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final firstEntry = data.entries.first;
        final pelajarId = firstEntry.key;
        final pelajarData = Map<String, dynamic>.from(firstEntry.value as Map);

        if (pelajarData['password'] == _password.text) {
          loginAttempts = 0;
          pelajarData['id'] = pelajarId;

          await SessionManager.saveSession(
            userType: 'pelajar',
            userData: pelajarData,
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
                builder: (context) => DashboardPelajar(userData: pelajarData),
              ),
            );
          }
        } else {
          loginAttempts++;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Email atau password salah"),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        loginAttempts++;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Email atau password salah"),
              backgroundColor: Colors.red,
            ),
          );
        }
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
                        MaterialPageRoute(builder: (context) => RegisterPage()),
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
