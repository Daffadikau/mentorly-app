import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dashboard_admin.dart';
import '../utils/session_manager.dart';

class LoginAdmin extends StatefulWidget {
  const LoginAdmin({super.key});

  @override
  _LoginAdminState createState() => _LoginAdminState();
}

class _LoginAdminState extends State<LoginAdmin> {
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();

  String? errorUsername;
  String? errorPassword;
  bool isLoading = false;
  bool _obscurePassword = true;
  int loginAttempts = 0;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  bool validasi() {
    bool isValid = true;

    setState(() {
      if (_username.text.isEmpty) {
        errorUsername = "Username tidak boleh kosong";
        isValid = false;
      } else if (_username.text.length < 3) {
        errorUsername = "Username minimal 3 karakter";
        isValid = false;
      } else {
        errorUsername = null;
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
      final candidatePaths = [
        'admin',
        'admins',
        'users',
        'user',
        'administrator',
        'admins_list'
      ];
      final normalizedInput = _username.text.trim().toLowerCase();
      final keys = [
        'username',
        'user',
        'name',
        'email',
        'itemusername',
        'nama'
      ];
      MapEntry? matchEntry;
      Map<String, dynamic>? matchDataFromList;
      final triedPaths = <String>[];

      for (var path in candidatePaths) {
        triedPaths.add(path);
        final ref = FirebaseDatabase.instance.ref(path);

        // try keyed queries first (for Map structures)
        for (var key in keys) {
          final query = ref.orderByChild(key).equalTo(normalizedInput);
          try {
            final snapshot =
                await query.get().timeout(const Duration(seconds: 4));
            if (snapshot.exists) {
              final raw = snapshot.value;
              if (raw is Map && raw.isNotEmpty) {
                matchEntry = raw.entries.first;
                break;
              }
            }
          } catch (_) {
            // ignore and try next key
          }
        }
        if (matchEntry != null) break;

        // fallback: scan Map entries and compare any string field
        try {
          final allSnap = await ref.get().timeout(const Duration(seconds: 6));
          if (allSnap.exists && allSnap.value is Map) {
            final allMap = allSnap.value as Map<dynamic, dynamic>;
            for (var e in allMap.entries) {
              final entryVal = e.value;
              if (entryVal is Map) {
                for (var f in entryVal.entries) {
                  final val = f.value;
                  if (val is String &&
                      val.trim().toLowerCase() == normalizedInput) {
                    matchEntry = e;
                    break;
                  }
                }
              }
              if (matchEntry != null) break;
            }
          }
        } catch (_) {
          // ignore
        }

        if (matchEntry != null) break;

        // fallback: handle List structures (iterate and match)
        try {
          final listSnap = await ref.get().timeout(const Duration(seconds: 6));
          if (listSnap.exists && listSnap.value is List) {
            final adminList = listSnap.value as List<dynamic>;
            for (var i = 0; i < adminList.length; i++) {
              final item = adminList[i];
              if (item is Map) {
                for (var f in (item).entries) {
                  final val = f.value;
                  if (val is String &&
                      val.trim().toLowerCase() == normalizedInput) {
                    matchDataFromList = Map<String, dynamic>.from(item);
                    matchDataFromList['_index'] = i;
                    break;
                  }
                }
              }
              if (matchDataFromList != null) break;
            }
          }
        } catch (_) {
          // ignore
        }

        if (matchEntry != null || matchDataFromList != null) break;
      }

      if (matchEntry == null && matchDataFromList == null) {
        // No match found anywhere
        loginAttempts++;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "Username atau password salah. Paths tried: ${triedPaths.join(', ')}"),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } else if (matchEntry != null) {
        // Match found in Map structure
        final adminId = matchEntry.key;
        final adminData = Map<String, dynamic>.from(matchEntry.value as Map);

        final storedPassword =
            (adminData['password'] ?? adminData['itempassword'] ?? '')
                .toString();

        if (storedPassword == _password.text) {
          loginAttempts = 0;
          adminData['id'] = adminId;

          await SessionManager.saveSession(
            userType: 'admin',
            userData: adminData,
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
              MaterialPageRoute(builder: (context) => const DashboardAdmin()),
            );
          }
        } else {
          loginAttempts++;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Username atau password salah"),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // Match found in List structure
        final adminData = matchDataFromList!;
        final index = adminData.remove('_index');

        final storedPassword =
            (adminData['password'] ?? adminData['itempassword'] ?? '')
                .toString();

        if (storedPassword == _password.text) {
          loginAttempts = 0;
          adminData['id'] = index;

          await SessionManager.saveSession(
            userType: 'admin',
            userData: adminData,
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
              MaterialPageRoute(builder: (context) => const DashboardAdmin()),
            );
          }
        } else {
          loginAttempts++;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Username atau password salah"),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Koneksi gagal. Periksa internet Anda."),
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
                "Login Admin",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _username,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: "Username",
                  hintText: "Username admin",
                  errorText: errorUsername,
                  prefixIcon: const Icon(Icons.person_outlined),
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
                  hintText: "••••••••",
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
            ],
          ),
        ),
      ),
    );
  }
}
