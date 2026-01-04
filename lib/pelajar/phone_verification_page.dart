import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class PhoneVerificationPage extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;
  final String email;
  final String password;
  final Map<String, dynamic> additionalData;

  const PhoneVerificationPage({
    Key? key,
    required this.phoneNumber,
    required this.verificationId,
    required this.email,
    required this.password,
    required this.additionalData,
  }) : super(key: key);

  @override
  _PhoneVerificationPageState createState() => _PhoneVerificationPageState();
}

class _PhoneVerificationPageState extends State<PhoneVerificationPage> {
  final TextEditingController _codeController = TextEditingController();
  bool _isVerifying = false;
  bool _canResend = false;
  int _resendCountdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _canResend = false;
      _resendCountdown = 60;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.isEmpty || _codeController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan kode 6 digit')),
      );
      return;
    }

    setState(() => _isVerifying = true);

    try {
      // Create credential from verification code
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: _codeController.text,
      );

      // Verify phone credential (tanpa sign in)
      print('📱 Verifying phone credential...');

      // Just verify the code is correct by trying to sign in temporarily
      final tempAuth =
          await FirebaseAuth.instance.signInWithCredential(credential);
      print('✅ Phone verified successfully!');

      // Sign out immediately - we don't want phone auth session
      await FirebaseAuth.instance.signOut();

      // Return success - will create email/password account in register page
      if (mounted) {
        Navigator.pop(context, {
          'success': true,
          'phoneVerified': true,
          'phoneNumber': widget.phoneNumber,
          'phoneUid': tempAuth.user?.uid, // Save this for reference
        });
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Verifikasi gagal';

      if (e.code == 'invalid-verification-code') {
        errorMessage = 'Kode verifikasi salah';
      } else if (e.code == 'session-expired') {
        errorMessage = 'Kode expired, silakan minta kode baru';
      } else {
        errorMessage = 'Error: ${e.message}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      print('❌ Unexpected error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  Future<void> _resendCode() async {
    if (!_canResend) return;

    setState(() => _isVerifying = true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification (Android only)
          print('✅ Auto verification completed');
        },
        verificationFailed: (FirebaseAuthException e) {
          print('❌ Verification failed: ${e.message}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal mengirim kode: ${e.message}')),
            );
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          print('📨 Code resent successfully');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Kode baru telah dikirim!')),
            );
            _startResendTimer();
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('⏱️ Auto retrieval timeout');
        },
      );
    } catch (e) {
      print('❌ Error resending code: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim ulang kode: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        title: const Text('Verifikasi Nomor Telepon',
            style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Icon(
                Icons.phone_android,
                size: 80,
                color: Colors.blue[700],
              ),
              const SizedBox(height: 30),
              const Text(
                "Masukkan Kode Verifikasi",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              Text(
                "Kode verifikasi telah dikirim ke\n${widget.phoneNumber}",
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 10,
                ),
                decoration: InputDecoration(
                  hintText: "000000",
                  hintStyle: TextStyle(
                    color: Colors.grey[300],
                    letterSpacing: 10,
                  ),
                  border: const OutlineInputBorder(),
                  counterText: "",
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _verifyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isVerifying
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Verifikasi",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Tidak menerima kode? "),
                  TextButton(
                    onPressed: _canResend && !_isVerifying ? _resendCode : null,
                    child: Text(
                      _canResend
                          ? "Kirim Ulang"
                          : "Kirim ulang dalam $_resendCountdown detik",
                      style: TextStyle(
                        color: _canResend ? Colors.blue[700] : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  "Ubah Nomor Telepon",
                  style: TextStyle(
                    color: Colors.blue[700],
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
