import 'package:flutter/material.dart';
import 'register_mentor.dart';

class SyaratKetentuan extends StatefulWidget {
  const SyaratKetentuan({super.key});

  @override
  _SyaratKetentuanState createState() => _SyaratKetentuanState();
}

class _SyaratKetentuanState extends State<SyaratKetentuan> {
  bool isAgreed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        elevation: 0,
        title: const Text(
          "Syarat & Ketentuan Pengajar",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.blue[700], size: 30),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            "Silakan baca dan pahami syarat ketentuan di bawah ini dengan seksama",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue[900],
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  _buildSection(
                    "1. Syarat & Ketentuan Registrasi",
                    [
                      "Pengajar harus berusia minimal 21 tahun dan memiliki identitas yang valid (KTP/Paspor).",
                      "Memiliki latar belakang pendidikan minimal S1 atau sertifikasi kompetensi yang relevan dengan bidang keahlian yang akan diajarkan.",
                      "Menyediakan dokumen pendukung yang lengkap dan valid, termasuk: Ijazah terakhir, KTP, SKCK (Surat Keterangan Catatan Kepolisian), dan sertifikat kompetensi (jika ada).",
                      "Mengisi formulir registrasi dengan data yang benar dan akurat.",
                      "Proses verifikasi akan dilakukan oleh tim Mentorly dalam waktu 1-3 hari kerja.",
                    ],
                  ),
                  _buildSection(
                    "2. Kewajiban Pengajar",
                    [
                      "Memberikan materi pembelajaran yang berkualitas, jelas, dan sesuai dengan kebutuhan siswa.",
                      "Menjaga profesionalisme dalam setiap sesi pembelajaran.",
                      "Hadir tepat waktu sesuai jadwal yang telah ditentukan.",
                      "Memberikan feedback konstruktif kepada siswa.",
                      "Menjaga kerahasiaan data pribadi siswa.",
                      "Tidak menyalahgunakan platform untuk kepentingan pribadi di luar konteks pembelajaran.",
                    ],
                  ),
                  _buildSection(
                    "3. Ketentuan Pembayaran",
                    [
                      "Pengajar akan menerima pembayaran setelah sesi pembelajaran selesai dan dikonfirmasi oleh siswa.",
                      "Mentorly akan memotong biaya administrasi sebesar 15% dari setiap transaksi.",
                      "Penarikan dana dapat dilakukan minimal Rp 50.000 dan akan diproses dalam waktu 1-3 hari kerja.",
                      "Pengajar bertanggung jawab atas pajak penghasilan sesuai dengan peraturan perpajakan yang berlaku.",
                    ],
                  ),
                  _buildSection(
                    "4. Pembatalan & Pengembalian Dana",
                    [
                      "Jika pembatalan dilakukan oleh pengajar kurang dari 24 jam sebelum sesi, akan dikenakan denda 50% dari nilai sesi.",
                      "Pembatalan karena force majeure tidak akan dikenakan denda dengan bukti yang valid.",
                      "Pengajar wajib memberikan kompensasi atau reschedule untuk sesi yang dibatalkan.",
                    ],
                  ),
                  _buildSection(
                    "5. Pelanggaran & Sanksi",
                    [
                      "Pelanggaran terhadap syarat dan ketentuan dapat mengakibatkan penangguhan atau penutupan akun.",
                      "Pengajar yang terbukti melakukan tindakan tidak profesional, pelecehan, atau diskriminasi akan langsung diblokir dari platform.",
                      "Mentorly berhak menahan pembayaran jika terdapat laporan atau indikasi pelanggaran.",
                    ],
                  ),
                  _buildSection(
                    "6. Privasi & Keamanan Data",
                    [
                      "Mentorly berkomitmen menjaga keamanan dan privasi data pengajar.",
                      "Data pribadi hanya akan digunakan untuk keperluan verifikasi dan operasional platform.",
                      "Pengajar bertanggung jawab menjaga kerahasiaan akun dan password.",
                    ],
                  ),
                  _buildSection(
                    "7. Perubahan Ketentuan",
                    [
                      "Mentorly berhak mengubah syarat dan ketentuan sewaktu-waktu.",
                      "Pengajar akan diberitahu melalui email atau notifikasi aplikasi jika terdapat perubahan.",
                      "Dengan melanjutkan penggunaan platform setelah perubahan, pengajar dianggap menyetujui ketentuan baru.",
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: isAgreed,
                      onChanged: (value) {
                        setState(() {
                          isAgreed = value!;
                        });
                      },
                      activeColor: Colors.blue[700],
                    ),
                    const Expanded(
                      child: Text(
                        "Saya telah membaca dan menyetujui semua syarat dan ketentuan di atas",
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isAgreed
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RegisterMentor(),
                              ),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isAgreed ? Colors.blue[700] : Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Setuju & Lanjutkan",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<String> points) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue[900],
          ),
        ),
        const SizedBox(height: 10),
        ...points.map((point) => Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "• ",
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  Expanded(
                    child: Text(
                      point,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            )),
        const SizedBox(height: 20),
      ],
    );
  }
}
