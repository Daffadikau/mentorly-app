import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class PhoneVerificationPage extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;
  final String email;
  final String password;
  final Map<String, dynamic> additionalData;
  final bool isTestMode; // Tambahkan parameter untuk test mode

  const PhoneVerificationPage({
    Key? key,
    required this.phoneNumber,
    required this.verificationId,
    required this.email,
    required this.password,
    required this.additionalData,
    this.isTestMode = false, // Default false
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

  // Test mode configurations dengan nomor dan OTP yang Anda berikan
  static const Map<String, String> TEST_NUMBERS = {
    '+628132063163': '238767',  // +62 813-2063-2163 -> 238767
    '+628121514898': '445421',  // +62 812-1514-4898 -> 445421
  };

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    
    // Jika test mode, pre-fill dengan test code yang sesuai
    final normalizedPhone = _normalizePhoneNumber(widget.phoneNumber);
    if (widget.isTestMode || TEST_NUMBERS.containsKey(normalizedPhone)) {
      final testCode = TEST_NUMBERS[normalizedPhone];
      if (testCode != null) {
        _codeController.text = testCode;
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  // Normalize phone number untuk matching (hapus spasi, strip, dll)
  String _normalizePhoneNumber(String phone) {
    return phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  }

  // Check apakah nomor adalah test number
  bool _isTestNumber(String phoneNumber) {
    final normalized = _normalizePhoneNumber(phoneNumber);
    return TEST_NUMBERS.containsKey(normalized);
  }

  // Get test code untuk nomor tertentu
  String? _getTestCode(String phoneNumber) {
    final normalized = _normalizePhoneNumber(phoneNumber);
    return TEST_NUMBERS[normalized];
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
      // Handle test mode
      if (widget.isTestMode || _isTestNumber(widget.phoneNumber)) {
        await _handleTestModeVerification();
        return;
      }

      // Normal verification untuk production
      await _handleNormalVerification();
      
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

  Future<void> _handleTestModeVerification() async {
    print('🧪 Test mode verification...');
    
    // Simulasi delay untuk UX yang realistis
    await Future.delayed(const Duration(seconds: 1));
    
    final expectedCode = _getTestCode(widget.phoneNumber);
    
    // Validasi test code
    if (_codeController.text == expectedCode) {
      print('✅ Test verification successful!');
      
      if (mounted) {
        Navigator.pop(context, {
          'success': true,
          'phoneVerified': true,
          'phoneNumber': widget.phoneNumber,
          'testMode': true,
        });
      }
    } else {
      // Tampilkan error jika kode salah
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kode salah! Gunakan kode: $expectedCode'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleNormalVerification() async {
    // Create credential from verification code
    final credential = PhoneAuthProvider.credential(
      verificationId: widget.verificationId,
      smsCode: _codeController.text,
    );

    // Verify phone credential (tanpa sign in)
    print('📱 Verifying phone credential...');

    try {
      // Just verify the code is correct by trying to sign in temporarily
      final tempAuth = await FirebaseAuth.instance.signInWithCredential(credential);
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
    }
  }

  Future<void> _resendCode() async {
    if (!_canResend) return;

    // Jika test mode, tidak perlu resend sebenarnya
    if (widget.isTestMode || _isTestNumber(widget.phoneNumber)) {
      final testCode = _getTestCode(widget.phoneNumber);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test mode: Kode untuk nomor ini adalah $testCode'),
            backgroundColor: Colors.orange,
          ),
        );
        _startResendTimer();
      }
      return;
    }
    
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
    // Tampilkan indikator test mode jika aktif
    final isInTestMode = widget.isTestMode || _isTestNumber(widget.phoneNumber);
    final testCode = _getTestCode(widget.phoneNumber);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        title: Text(
          isInTestMode ? 'Verifikasi (Test Mode)' : 'Verifikasi Nomor Telepon',
          style: const TextStyle(color: Colors.white),
        ),
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
              // Test mode banner
              if (isInTestMode)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.science, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'TEST MODE: Gunakan kode $testCode',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
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
                isInTestMode 
                    ? "Test mode untuk nomor:\n${widget.phoneNumber}"
                    : "Kode verifikasi telah dikirim ke\n${widget.phoneNumber}",
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
                  hintText: isInTestMode ? testCode : "000000",
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
