import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'register_mentor.dart';
import 'dashboard_mentor.dart';
import '../utils/session_manager.dart';
import '../common/api_config.dart';

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
      User? user;
      String uid;
      bool isPhpAuth = false;

      // Try Firebase Auth login first
      try {
        final userCredential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _email.text.trim().toLowerCase(),
          password: _password.text,
        );

        uid = userCredential.user!.uid;
        user = userCredential.user!;
        print("✅ Firebase Auth login successful");
      } on FirebaseAuthException catch (e) {
        // Firebase Auth failed, check if mentor exists in Firebase RTDB
        print("⚠️ Firebase Auth failed (${e.code}), checking Firebase RTDB...");

        if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
          try {
            // Check all mentors in Firebase RTDB to find by email
            print("🔍 Checking Firebase RTDB for email: ${_email.text.trim().toLowerCase()}");
            
            // First, let's see what's at the root
            print("🔍 Checking root database structure...");
            final rootRef = FirebaseDatabase.instance.ref();
            final rootSnapshot = await rootRef.get();
            
            if (rootSnapshot.exists && rootSnapshot.value != null) {
              print("📊 Root keys: ${(rootSnapshot.value as Map).keys.toList()}");
            } else {
              print("❌ Root is empty");
            }
            
            // Try with unauthenticated read - may require Firebase rules adjustment
            final mentorsRef = FirebaseDatabase.instance.ref('mentors'); // Note: plural!
            
            DataSnapshot snapshot;
            try {
              snapshot = await mentorsRef.get();
              print("✅ Successfully read from Firebase RTDB");
              print("📊 Snapshot exists: ${snapshot.exists}");
              print("📊 Snapshot value type: ${snapshot.value?.runtimeType}");
              print("📊 Snapshot value: ${snapshot.value}");
            } catch (dbError) {
              print("❌ Firebase RTDB read error: $dbError");
              // If we can't read, the user needs to be registered first
              throw Exception('Email tidak terdaftar atau belum terverifikasi. Silakan daftar atau hubungi admin.');
            }
            
            if (snapshot.exists && snapshot.value != null) {
              print("✅ Found mentor node in Firebase RTDB");
              
              String? foundUid;
              Map<String, dynamic>? foundMentor;
              
              // Check if value is a List (array) or Map (object)
              if (snapshot.value is List) {
                print("📊 Data is a List with ${(snapshot.value as List).length} mentors");
                final mentorsList = snapshot.value as List;
                
                // Search through the list
                for (int i = 0; i < mentorsList.length; i++) {
                  if (mentorsList[i] != null) {
                    final mentorData = Map<String, dynamic>.from(mentorsList[i] as Map);
                    final mentorEmail = mentorData['email']?.toString().toLowerCase() ?? '';
                    print("  Checking: $mentorEmail vs ${_email.text.trim().toLowerCase()}");
                    
                    if (mentorEmail == _email.text.trim().toLowerCase()) {
                      foundUid = mentorData['id']?.toString() ?? i.toString();
                      foundMentor = mentorData;
                      print("✅ FOUND MATCH! Index: $i, ID: ${mentorData['id']}");
                      break;
                    }
                  }
                }
              } else if (snapshot.value is Map) {
                print("📊 Data is a Map");
                final mentors = Map<String, dynamic>.from(snapshot.value as Map);
                print("🔍 Searching through ${mentors.length} mentors...");
                
                // Find mentor by email
                mentors.forEach((mentorUid, data) {
                  if (data != null) {
                    final mentorData = Map<String, dynamic>.from(data);
                    final mentorEmail = mentorData['email']?.toString().toLowerCase() ?? '';
                    print("  Checking: $mentorEmail vs ${_email.text.trim().toLowerCase()}");
                    
                    if (mentorEmail == _email.text.trim().toLowerCase()) {
                      foundUid = mentorUid;
                      foundMentor = mentorData;
                      print("✅ FOUND MATCH! UID: $mentorUid");
                    }
                  }
                });
              } else {
                print("❌ Unexpected data type: ${snapshot.value.runtimeType}");
                throw Exception('Format data mentor tidak valid');
              }
              
              if (foundMentor != null && foundUid != null) {
                print("📋 Mentor data: ${foundMentor!['nama_lengkap'] ?? 'No name'}, Status: ${foundMentor!['status_verifikasi'] ?? 'No status'}");
                
                // Mentor exists in RTDB, check if verified
                final verificationStatus = foundMentor!['status_verifikasi'] ?? 'pending';
                if (verificationStatus == 'verified') {
                  print("✅ Mentor is verified, creating Firebase Auth account...");
                  
                  // Create Firebase Auth account with the password they entered
                  try {
                    final newUserCredential = await FirebaseAuth.instance
                        .createUserWithEmailAndPassword(
                      email: _email.text.trim().toLowerCase(),
                      password: _password.text,
                    );
                    
                    uid = newUserCredential.user!.uid;
                    user = newUserCredential.user!;
                    
                    print("✅ Created Firebase Auth UID: $uid");
                    
                    // Update RTDB with new UID if different
                    if (uid != foundUid) {
                      print("🔄 Migrating data from $foundUid to new UID $uid...");
                      foundMentor!['uid'] = uid;
                      await FirebaseDatabase.instance.ref('mentors').child(uid).set(foundMentor);
                      
                      // Try to remove old node (may fail due to permissions)
                      try {
                        await FirebaseDatabase.instance.ref('mentors').child(foundUid!).remove();
                        print("✅ Removed old mentor node");
                      } catch (removeError) {
                        print("⚠️ Could not remove old node: $removeError");
                      }
                      
                      print("✅ Migrated mentor data to new UID: $uid");
                    }
                    
                    // Send verification email
                    try {
                      await user.sendEmailVerification();
                      print("✅ Verification email sent");
                    } catch (emailError) {
                      print("⚠️ Could not send verification email: $emailError");
                    }
                    
                    isPhpAuth = true;
                  } catch (createError) {
                    print("❌ Failed to create Firebase account: $createError");
                    if (createError.toString().contains('email-already-in-use')) {
                      throw Exception('Email sudah terdaftar tapi password salah. Coba reset password atau hubungi admin.');
                    } else if (createError.toString().contains('weak-password')) {
                      throw Exception('Password terlalu lemah. Gunakan minimal 6 karakter.');
                    }
                    throw Exception('Gagal membuat akun: ${createError.toString()}');
                  }
                } else {
                  print("❌ Mentor not verified: $verificationStatus");
                  throw Exception('Akun Anda masih dalam proses verifikasi oleh admin');
                }
              } else {
                print("❌ Mentor not found in RTDB");
                throw Exception('Email tidak terdaftar. Silakan daftar sebagai mentor terlebih dahulu.');
              }
            } else {
              print("❌ No mentor node found in Firebase RTDB or empty");
              throw Exception('Belum ada mentor terdaftar. Silakan daftar terlebih dahulu.');
            }
          } catch (rtdbError) {
            print("❌ Error checking Firebase RTDB: $rtdbError");
            if (rtdbError is Exception) {
              rethrow;
            }
            throw Exception('Gagal memeriksa akun: ${rtdbError.toString()}');
          }
        } else {
          print("❌ Unhandled Firebase error: ${e.code}");
          rethrow;
        }
      }

      // Legacy PHP fallback (if needed) - Commented out, using Firebase RTDB instead
      /*
      try {
          final response = await http.post(
            Uri.parse(ApiConfig.getUrl("login_mentor.php")),
            body: {
              'email': _email.text.trim().toLowerCase(),
              'password': _password.text,
            },
          ).timeout(const Duration(seconds: 10));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);

            if (data['status'] == 'success') {
              // PHP auth successful, create Firebase Auth account
              print("✅ PHP authentication successful, creating Firebase account...");

              try {
                final newUserCredential = await FirebaseAuth.instance
                    .createUserWithEmailAndPassword(
                  email: _email.text.trim().toLowerCase(),
                  password: _password.text,
                );

                uid = newUserCredential.user!.uid;
                user = newUserCredential.user!;

                // Send verification email
                await user.sendEmailVerification();
                print("✅ Firebase Auth account created, verification email sent");

                isPhpAuth = true;
              } catch (createError) {
                print("❌ Failed to create Firebase account: $createError");
                // If account creation fails, we can still proceed with PHP data
                // Generate a temporary UID from email
                uid = _email.text.trim().toLowerCase().hashCode.toString();
                isPhpAuth = true;
              }
            } else {
              // PHP auth also failed
              throw Exception(data['message'] ?? 'Login gagal');
            }
          } else {
            throw Exception('Server error');
          }
        } catch (phpError) {
          print("❌ PHP authentication also failed: $phpError");
          // Re-throw the original Firebase error
          rethrow;
        }
      */

      // Check if email is verified (skip for RTDB-migrated users initially)
      if (user.emailVerified == false && !isPhpAuth) {
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
                      await user?.sendEmailVerification();
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
                    await user?.reload();
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
      final ref = FirebaseDatabase.instance.ref('mentors').child(uid);
      final snapshot = await ref.get();

      Map<String, dynamic> mentorData;
      bool isVerified = false;

      if (!snapshot.exists) {
        // Profile doesn't exist in Firebase RTDB, check PHP backend
        print("⚠️ Mentor profile not found in Firebase RTDB, checking PHP backend...");
        
        try {
          final response = await http.post(
            Uri.parse(ApiConfig.getUrl("check_mentor_status.php")),
            body: {
              'uid': uid,
              'email': _email.text.trim().toLowerCase(),
            },
          ).timeout(const Duration(seconds: 10));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['status'] == 'success' && data['verified'] == true) {
              // Mentor is verified in PHP backend, sync to Firebase RTDB
              mentorData = Map<String, dynamic>.from(data['mentor_data']);
              mentorData['uid'] = uid;
              mentorData['id'] = uid;
              
              // Save to Firebase RTDB for future logins
              await ref.set(mentorData);
              isVerified = true;
              print("✅ Mentor data synced from PHP backend to Firebase");
            } else {
              // Not verified in PHP backend either
              mentorData = {
                'email': _email.text.trim().toLowerCase(),
                'uid': uid,
                'created_at': DateTime.now().toIso8601String(),
                'status_verifikasi': 'pending',
              };
              await ref.set(mentorData);
            }
          } else {
            // PHP backend error, create pending profile
            mentorData = {
              'email': _email.text.trim().toLowerCase(),
              'uid': uid,
              'created_at': DateTime.now().toIso8601String(),
              'status_verifikasi': 'pending',
            };
            await ref.set(mentorData);
          }
        } catch (e) {
          print("❌ Error checking PHP backend: $e");
          // Create pending profile as fallback
          mentorData = {
            'email': _email.text.trim().toLowerCase(),
            'uid': uid,
            'created_at': DateTime.now().toIso8601String(),
            'status_verifikasi': 'pending',
          };
          await ref.set(mentorData);
        }
      } else {
        // Profile exists in Firebase RTDB
        mentorData = Map<String, dynamic>.from(snapshot.value as Map? ?? {});
        mentorData['id'] = uid;
        mentorData['uid'] = uid;
        
        // Check if verified
        if (mentorData['status_verifikasi'] == 'verified') {
          isVerified = true;
        } else {
          // Not verified in Firebase, double-check PHP backend
          print("⚠️ Not verified in Firebase RTDB, checking PHP backend...");
          try {
            final response = await http.post(
              Uri.parse(ApiConfig.getUrl("check_mentor_status.php")),
              body: {
                'uid': uid,
                'email': _email.text.trim().toLowerCase(),
              },
            ).timeout(const Duration(seconds: 10));

            if (response.statusCode == 200) {
              final data = jsonDecode(response.body);
              if (data['status'] == 'success' && data['verified'] == true) {
                // Update Firebase RTDB with verified status
                mentorData['status_verifikasi'] = 'verified';
                // Merge any additional data from PHP backend
                if (data['mentor_data'] != null) {
                  final phpData = Map<String, dynamic>.from(data['mentor_data']);
                  mentorData.addAll(phpData);
                }
                await ref.update({'status_verifikasi': 'verified'});
                isVerified = true;
                print("✅ Mentor status synced from PHP backend");
              }
            }
          } catch (e) {
            print("❌ Error checking PHP backend: $e");
          }
        }
      }

      // Check verification status
      if (!isVerified) {
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
    } catch (e) {
      loginAttempts++;
      
      if (mounted) {
        String errorMessage = "Login gagal. Periksa email dan password Anda.";
        
        if (e is FirebaseAuthException) {
          if (e.code == 'user-not-found') {
            errorMessage = "Akun tidak ditemukan di Firebase";
          } else if (e.code == 'wrong-password') {
            errorMessage = "Password salah";
          } else if (e.code == 'too-many-requests') {
            errorMessage = "Terlalu banyak percobaan. Coba lagi nanti.";
          } else {
            errorMessage = "Email atau password salah";
          }
        } else if (e.toString().contains("timeout")) {
          errorMessage = "Koneksi timeout. Coba lagi.";
        } else if (e.toString().contains("Login gagal")) {
          errorMessage = e.toString().replaceAll("Exception: ", "");
        } else if (e.toString().contains("Email tidak terdaftar")) {
          errorMessage = "Email tidak terdaftar. Silakan daftar terlebih dahulu.";
        } else if (e.toString().contains("Password salah")) {
          errorMessage = "Password salah. Silakan coba lagi.";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
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
