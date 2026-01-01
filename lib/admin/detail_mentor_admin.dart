import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_database/firebase_database.dart';
import '../common/api_config.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

class DetailMentorAdmin extends StatelessWidget {
  final Map<String, dynamic> mentorData;

  const DetailMentorAdmin({super.key, required this.mentorData});

  Future<void> verifyMentor(BuildContext context, String status) async {
    print("🔄 Starting verification process...");
    print("📋 Mentor data: $mentorData");

    // Update Firebase RTDB if this is a Firebase mentor
    if (mentorData['source'] == 'firebase') {
      try {
        print("🔥 Updating Firebase RTDB...");
        final uid = mentorData['uid'];
        final firebaseIndex = mentorData['firebase_index'];

        DatabaseReference ref;
        if (uid != null) {
          // Data stored as Map with UID keys
          ref = FirebaseDatabase.instance.ref('mentors/$uid');
        } else if (firebaseIndex != null) {
          // Data stored as List with index
          ref = FirebaseDatabase.instance.ref('mentors/$firebaseIndex');
        } else {
          throw Exception("No UID or index found for Firebase mentor");
        }

        await ref.update({
          'status_verifikasi': status,
          'verified_at': DateTime.now().toIso8601String(),
        });
        print("✅ Firebase updated successfully");

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "Mentor berhasil ${status == 'verified' ? 'diverifikasi' : 'ditolak'}"),
              backgroundColor: status == 'verified' ? Colors.green : Colors.red,
            ),
          );
          Navigator.pop(context, true);
        }
        return;
      } catch (e) {
        print("❌ Error updating Firebase: $e");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
          );
        }
        return;
      }
    }

    // Update PHP database for PHP mentors
    print("🔄 Updating PHP database...");
    final uri = ApiConfig.getUrl('verify_mentor.php');

    var response = await http.post(
      Uri.parse(uri),
      body: {
        "itemid": mentorData['id'].toString(),
        "itemstatus": status,
      },
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Mentor berhasil ${status == 'verified' ? 'diverifikasi' : 'ditolak'}")),
        );
        Navigator.pop(context, true); // Return true untuk refresh list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'])),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        elevation: 0,
        title: const Text(
          "Verifikasi Pengajar",
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.blue[700],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    mentorData['nama_lengkap'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    decoration: BoxDecoration(
                      color: mentorData['status_verifikasi'] == 'pending'
                          ? Colors.orange
                          : mentorData['status_verifikasi'] == 'verified'
                              ? Colors.green
                              : Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      mentorData['status_verifikasi'] == 'pending'
                          ? 'Menunggu Verifikasi'
                          : mentorData['status_verifikasi'] == 'verified'
                              ? 'Terverifikasi'
                              : 'Ditolak',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Informasi Pribadi",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildInfoRow("Email", mentorData['email'], Icons.email),
                  _buildInfoRow("NIK", mentorData['nik'], Icons.badge),
                  _buildInfoRow("Jenis Kelamin", mentorData['kelamin'],
                      Icons.person_outline),
                  const SizedBox(height: 25),
                  Text(
                    "Keahlian & Kompetensi",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildInfoCard(
                    "Keahlian Utama",
                    mentorData['keahlian'],
                    Icons.school,
                    Colors.blue,
                  ),
                  if (mentorData['keahlian_lain'] != null &&
                      mentorData['keahlian_lain'].toString().isNotEmpty)
                    _buildInfoCard(
                      "Keahlian Lain",
                      mentorData['keahlian_lain'],
                      Icons.lightbulb_outline,
                      Colors.orange,
                    ),
                  const SizedBox(height: 25),
                  Text(
                    "Dokumen Pendukung",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildDocumentCard(
                    context,
                    "KTP",
                    Icons.credit_card,
                    Colors.green,
                    mentorData['url_ktp'] as String?,
                  ),
                  _buildDocumentCard(
                    context,
                    "Ijazah Terakhir",
                    Icons.description,
                    Colors.blue,
                    mentorData['url_pendidikan'] as String?,
                  ),
                  _buildDocumentCard(
                    context,
                    "SKCK",
                    Icons.verified_user,
                    Colors.purple,
                    mentorData['url_skck'] as String?,
                  ),
                  _buildDocumentCard(
                    context,
                    "Sertifikat",
                    Icons.card_membership,
                    Colors.amber,
                    mentorData['url_sertifikat'] as String?,
                  ),
                  const SizedBox(height: 25),
                  Text(
                    "Informasi Tambahan",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 15),
                  if (mentorData['link_linkedin'] != null &&
                      mentorData['link_linkedin'].toString().isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  "Membuka: ${mentorData['link_linkedin']}")),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.link, color: Colors.blue[700]),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "LinkedIn Profile",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    mentorData['link_linkedin'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue[700],
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.open_in_new, color: Colors.blue[700]),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 30),
                  if (mentorData['status_verifikasi'] == 'pending')
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () =>
                                  verifyMentor(context, 'rejected'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.close, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    "Tolak",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () =>
                                  verifyMentor(context, 'verified'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    "Verifikasi",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (mentorData['status_verifikasi'] == 'verified')
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: Colors.green, size: 30),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              "Mentor ini sudah terverifikasi dan dapat mengajar",
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (mentorData['status_verifikasi'] == 'rejected')
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.cancel, color: Colors.red, size: 30),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              "Mentor ini ditolak dan tidak dapat mengajar",
                              style: TextStyle(
                                color: Colors.red[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
      String title, String content, IconData icon, MaterialColor color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color[700], size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color[900],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPdfPreview(BuildContext context, String title, String fileUrl) async {
    if (kIsWeb) {
      // For web, use iframe with direct URL
      final viewId = 'pdf-${DateTime.now().millisecondsSinceEpoch}';
      
      // Register iframe
      ui_web.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
        return html.IFrameElement()
          ..src = fileUrl
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%';
      });
      
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue[700],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.open_in_new, color: Colors.white),
                        onPressed: () async {
                          final uri = Uri.parse(fileUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        tooltip: 'Buka di Browser',
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: HtmlElementView(viewType: viewId),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // For mobile, use Syncfusion PDF viewer
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue[700],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.open_in_new, color: Colors.white),
                        onPressed: () async {
                          final uri = Uri.parse(fileUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        tooltip: 'Buka di Browser',
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    color: Colors.grey[300],
                    child: SfPdfViewer.network(
                      fileUrl,
                      enableDoubleTapZooming: true,
                      enableTextSelection: true,
                      canShowScrollHead: true,
                      canShowScrollStatus: true,
                      onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                        print("❌ PDF Load Failed: ${details.error}");
                        print("❌ Description: ${details.description}");
                      },
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

  Widget _buildDocumentCard(BuildContext context, String title, IconData icon,
      MaterialColor color, String? fileUrl) {
    bool hasFile = fileUrl != null && fileUrl.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color[700], size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (hasFile)
            InkWell(
              onTap: () {
                _showPdfPreview(context, title, fileUrl);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.visibility, color: Colors.blue[700], size: 16),
                    const SizedBox(width: 5),
                    Text(
                      "Preview",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.close, color: Colors.grey[600], size: 16),
                  const SizedBox(width: 5),
                  Text(
                    "Tidak Ada",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
