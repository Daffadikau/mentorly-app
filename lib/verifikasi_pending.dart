import 'package:flutter/material.dart';

class VerifikasiPending extends StatelessWidget {
  const VerifikasiPending({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.schedule,
                    size: 80,
                    color: Colors.blue[700],
                  ),
                ),
                const SizedBox(height: 40),

                const Text(
                  "Verifikasi Sedang Berlangsung",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                Text(
                  "Terima kasih telah mengirimkan biodata dan kredensial Anda! Saat ini, tim kami sedang meninjau dokumen untuk memastikan kualitas dan keaslian data yang Anda kirimkan. Proses ini dilakukan untuk menjaga kepercayaan dan keamanan dalam platform Mentorly.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[700],
                        size: 40,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Anda akan menerima notifikasi melalui email atau aplikasi setelah verifikasi selesai. Biasanya proses ini memakan waktu 1-3 hari kerja.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.blue[700]!, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      "Kembali ke Halaman Utama",
                      style: TextStyle(fontSize: 16, color: Colors.blue[700]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
