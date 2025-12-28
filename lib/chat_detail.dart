import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

class DetailChatPage extends StatefulWidget {
  final Map<String, dynamic> mentorData;
  final Map<String, dynamic> pelajarData;

  const DetailChatPage({super.key, required this.mentorData, required this.pelajarData});

  @override
  _DetailChatPageState createState() => _DetailChatPageState();
}

class _DetailChatPageState extends State<DetailChatPage> {
  List messageList = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;
  bool isLoading = true;
  bool isSending = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() {
    // Validasi data mentor dan pelajar
    if (widget.mentorData['mentor_id'] == null ||
        widget.pelajarData['id'] == null) {
      setState(() {
        errorMessage = "Data tidak valid";
        isLoading = false;
      });
      return;
    }

    loadMessages();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      loadMessages(silent: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> loadMessages({bool silent = false}) async {
    if (!silent) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final ref = FirebaseDatabase.instance.ref('pesan');
      final query = ref
          .orderByChild('pelajar_id')
          .equalTo(widget.pelajarData['id'].toString());
      
      final snapshot = await query.get().timeout(const Duration(seconds: 10));

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final messages = <Map<String, dynamic>>[];
        
        data.forEach((key, value) {
          final msg = Map<String, dynamic>.from(value as Map);
          // Filter by mentor_id if needed
          if (msg['mentor_id'].toString() == widget.mentorData['mentor_id'].toString()) {
            messages.add(msg);
          }
        });
        
        // Sort by timestamp
        messages.sort((a, b) {
          final timeA = DateTime.tryParse(a['timestamp'] ?? '') ?? DateTime.now();
          final timeB = DateTime.tryParse(b['timestamp'] ?? '') ?? DateTime.now();
          return timeA.compareTo(timeB);
        });

        if (mounted) {
          setState(() {
            messageList = messages;
            if (!silent) {
              isLoading = false;
            }
          });
          _scrollToBottom();
        }
      } else {
        if (mounted) {
          setState(() {
            messageList = [];
            if (!silent) {
              isLoading = false;
            }
          });
        }
      }
    } catch (e) {
      print("Error loading messages: $e");
      if (!silent && mounted) {
        setState(() {
          errorMessage = "Gagal memuat pesan";
          isLoading = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> sendMessage() async {
    String message = _messageController.text.trim();

    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pesan tidak boleh kosong")),
      );
      return;
    }

    if (message.length > 5000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pesan terlalu panjang (max 5000 karakter)")),
      );
      return;
    }

    _messageController.clear();

    setState(() {
      isSending = true;
    });

    try {
      final ref = FirebaseDatabase.instance.ref('pesan');
      final newRef = ref.push();

      final pesan = {
        'pelajar_id': widget.pelajarData['id'].toString(),
        'mentor_id': widget.mentorData['mentor_id'].toString(),
        'message': message,
        'sender': 'pelajar',
        'timestamp': DateTime.now().toIso8601String(),
      };

      await newRef.set(pesan).timeout(const Duration(seconds: 10));
      await loadMessages(silent: true);
    } catch (e) {
      print("Error sending message: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Gagal mengirim pesan"),
            action: SnackBarAction(
              label: "Coba Lagi",
              onPressed: () {
                _messageController.text = message;
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD),
      appBar: _buildAppBar(),
      body: errorMessage != null
          ? _buildErrorState()
          : Column(
              children: [
                if (isLoading)
                  LinearProgressIndicator(
                    backgroundColor: Colors.blue[100],
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
                  ),
                Expanded(
                  child: messageList.isEmpty
                      ? _buildEmptyState()
                      : _buildMessageList(),
                ),
                _buildMessageInput(),
              ],
            ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.blue[700],
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: Colors.blue[700], size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.mentorData['nama_mentor'] ?? 'Mentor',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(
                  "Online",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        PopupMenuButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          itemBuilder: (context) => [
            const PopupMenuItem(
              child: ListTile(
                leading: Icon(Icons.person, size: 20),
                title: Text("Lihat Profil", style: TextStyle(fontSize: 14)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              child: ListTile(
                leading: const Icon(Icons.refresh, size: 20),
                title: const Text("Refresh Chat", style: TextStyle(fontSize: 14)),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  Navigator.pop(context);
                  loadMessages();
                },
              ),
            ),
          ],
        ),
      ],
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
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => loadMessages(),
            icon: const Icon(Icons.refresh),
            label: const Text("Coba Lagi"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700]),
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 60,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Belum ada pesan",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Mulai percakapan dengan\n${widget.mentorData['nama_mentor'] ?? 'mentor'}",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      itemCount: messageList.length,
      itemBuilder: (context, index) {
        var message = messageList[index];
        bool isMe = message['sender_type'] == 'pelajar';

        bool showDate = false;
        if (index == 0) {
          showDate = true;
        } else {
          String currentDate = _formatDateOnly(message['created_at']);
          String previousDate =
              _formatDateOnly(messageList[index - 1]['created_at']);
          showDate = currentDate != previousDate;
        }

        return Column(
          children: [
            if (showDate) _buildDateHeader(message['created_at']),
            _buildMessageBubble(message, isMe),
          ],
        );
      },
    );
  }

  Widget _buildDateHeader(String timestamp) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
            ),
          ],
        ),
        child: Text(
          _formatDateOnly(timestamp),
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 4,
          left: isMe ? 60 : 8,
          right: isMe ? 8 : 60,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFDCF8C6) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isMe ? const Radius.circular(12) : const Radius.circular(0),
            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message['message'] ?? '',
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message['created_at']),
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.done_all, size: 16, color: Colors.blue[700]),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      maxLines: null,
                      maxLength: 5000,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: "Ketik pesan",
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        border: InputBorder.none,
                        counterText: "",
                      ),
                      onSubmitted: (_) => sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            onPressed: isSending ? null : sendMessage,
            backgroundColor: isSending ? Colors.grey : Colors.blue[700],
            mini: true,
            elevation: 2,
            child: isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.send, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return "";
    try {
      DateTime dateTime = DateTime.parse(timestamp);
      return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return "";
    }
  }

  String _formatDateOnly(String? timestamp) {
    if (timestamp == null) return "";
    try {
      DateTime dateTime = DateTime.parse(timestamp);
      DateTime now = DateTime.now();
      DateTime yesterday = now.subtract(const Duration(days: 1));

      if (dateTime.year == now.year &&
          dateTime.month == now.month &&
          dateTime.day == now.day) {
        return "Hari Ini";
      } else if (dateTime.year == yesterday.year &&
          dateTime.month == yesterday.month &&
          dateTime.day == yesterday.day) {
        return "Kemarin";
      } else {
        List<String> months = [
          '',
          'Januari',
          'Februari',
          'Maret',
          'April',
          'Mei',
          'Juni',
          'Juli',
          'Agustus',
          'September',
          'Oktober',
          'November',
          'Desember',
        ];
        return "${dateTime.day} ${months[dateTime.month]} ${dateTime.year}";
      }
    } catch (e) {
      return "";
    }
  }
}
