import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'chat_detail.dart';
import 'session_manager.dart';

class ListChatPage extends StatefulWidget {
  final Map<String, dynamic> pelajarData;

  const ListChatPage({super.key, required this.pelajarData});

  @override
  _ListChatPageState createState() => _ListChatPageState();
}

class _ListChatPageState extends State<ListChatPage> {
  List chatList = [];
  List filteredChatList = [];
  bool isLoading = true;
  String? errorMessage;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _validateAndLoadChats();
  }

  Future<void> _validateAndLoadChats() async {
    // Validasi session
    bool isValid = await SessionManager.validateSession();
    if (!isValid && mounted) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    loadChatList();
  }

  Future<void> loadChatList() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    // Validasi pelajar data
    if (widget.pelajarData['id'] == null) {
      setState(() {
        isLoading = false;
        errorMessage = "Data pelajar tidak valid";
      });
      return;
    }

    String uri = "http://localhost/mentorly/get_chat_list.php";

    try {
      var response = await http.post(
        Uri.parse(uri),
        body: {"itempelajarid": widget.pelajarData['id'].toString()},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        // Cek jika ada error dari server
        if (data is Map && data.containsKey('error')) {
          setState(() {
            errorMessage = data['error'];
            isLoading = false;
          });
          return;
        }

        setState(() {
          chatList = data is List ? data : [];
          filteredChatList = chatList;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "Gagal memuat data (${response.statusCode})";
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading chats: $e");
      setState(() {
        errorMessage = "Koneksi gagal. Periksa internet Anda.";
        isLoading = false;
      });
    }
  }

  void filterChats(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredChatList = chatList;
      } else {
        filteredChatList = chatList.where((chat) {
          String mentorName =
              chat['nama_mentor']?.toString().toLowerCase() ?? '';
          return mentorName.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return '';
    try {
      DateTime dateTime = DateTime.parse(timestamp);
      DateTime now = DateTime.now();

      if (dateTime.year == now.year &&
          dateTime.month == now.month &&
          dateTime.day == now.day) {
        return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
      } else {
        return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        elevation: 0,
        title: const Text("Pesan", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: loadChatList,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: TextField(
              controller: searchController,
              onChanged: filterChats,
              decoration: InputDecoration(
                hintText: "Cari mentor",
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: errorMessage != null
                ? _buildErrorState()
                : isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredChatList.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: loadChatList,
                            child: ListView.builder(
                              itemCount: filteredChatList.length,
                              itemBuilder: (context, index) {
                                return _buildChatItem(filteredChatList[index]);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
          const SizedBox(height: 20),
          Text(
            errorMessage ?? "Terjadi kesalahan",
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: loadChatList,
            icon: const Icon(Icons.refresh),
            label: const Text("Coba Lagi"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(
            searchController.text.isEmpty
                ? "Belum ada percakapan"
                : "Mentor tidak ditemukan",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (searchController.text.isEmpty) ...[
            const SizedBox(height: 10),
            Text(
              "Mulai booking untuk chat dengan mentor",
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChatItem(Map<String, dynamic> chat) {
    int unreadCount = 0;
    if (chat['unread_count'] != null) {
      unreadCount = int.tryParse(chat['unread_count'].toString()) ?? 0;
    }

    return Column(
      children: [
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailChatPage(
                  mentorData: chat,
                  pelajarData: widget.pelajarData,
                ),
              ),
            ).then((_) => loadChatList());
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.blue[100],
                      child:
                          Icon(Icons.person, color: Colors.blue[700], size: 28),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              chat['nama_mentor'] ?? 'Unknown',
                              style: TextStyle(
                                fontWeight: unreadCount > 0
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Text(
                            _formatTime(chat['last_message_time']),
                            style: TextStyle(
                              fontSize: 12,
                              color: unreadCount > 0
                                  ? Colors.blue[700]
                                  : Colors.grey[600],
                              fontWeight: unreadCount > 0
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat['last_message'] ?? 'Belum ada pesan',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: unreadCount > 0
                                    ? Colors.black87
                                    : Colors.grey[600],
                                fontWeight: unreadCount > 0
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (unreadCount > 0)
                            Container(
                              margin: const EdgeInsets.only(left: 10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue[700],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                unreadCount > 9 ? '9+' : unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, indent: 80),
      ],
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
