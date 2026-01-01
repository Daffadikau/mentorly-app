import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'video_call_screen.dart';
import 'incoming_call_dialog.dart';
import 'dart:async';
import '../services/notification_service.dart';

// Conditional imports for web
import 'chat_room_web.dart' if (dart.library.io) 'chat_room_stub.dart';

class ChatRoom extends StatefulWidget {
  final String roomId;
  final Map<String, dynamic> currentUser;
  final Map<String, dynamic> otherUser;
  final String userType; // 'mentor' or 'pelajar'

  const ChatRoom({
    super.key,
    required this.roomId,
    required this.currentUser,
    required this.otherUser,
    required this.userType,
  });

  @override
  State<ChatRoom> createState() => _ChatRoomState();
}

class _ChatRoomState extends State<ChatRoom> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> messages = [];
  bool isLoading = true;
  bool isSending = false;
  bool isUploading = false;
  double uploadProgress = 0.0;
  StreamSubscription? _callSubscription;
  Map<String, dynamic>? bookingData;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _listenToNewMessages();
    _listenToIncomingCalls();
    _loadBookingData();
  }

  Future<void> _loadBookingData() async {
    try {
      final snapshot = await _database
          .child('bookings')
          .orderByChild('pelajar_id')
          .equalTo(widget.userType == 'pelajar' 
              ? (widget.currentUser['uid'] ?? widget.currentUser['id'].toString())
              : (widget.otherUser['uid'] ?? widget.otherUser['id'].toString()))
          .get();

      if (snapshot.exists) {
        Map<dynamic, dynamic> bookings = snapshot.value as Map<dynamic, dynamic>;
        for (var booking in bookings.values) {
          Map<String, dynamic> bookingMap = Map<String, dynamic>.from(booking);
          // Find booking for this chat room
          String mentorId = bookingMap['mentor_id'] ?? '';
          String currentMentorId = widget.userType == 'mentor'
              ? (widget.currentUser['uid'] ?? widget.currentUser['id'].toString())
              : (widget.otherUser['uid'] ?? widget.otherUser['id'].toString());
          
          if (mentorId == currentMentorId && bookingMap['status'] == 'confirmed') {
            setState(() {
              bookingData = bookingMap;
            });
            print('📅 Booking loaded: ${bookingMap['jam_mulai']} - ${bookingMap['jam_selesai']}');
            break;
          }
        }
      }
    } catch (e) {
      print('Error loading booking data: $e');
    }
  }

  void _listenToNewMessages() {
    _database
        .child('messages')
        .child(widget.roomId)
        .onChildAdded
        .listen((event) {
      if (!isLoading && event.snapshot.value != null) {
        Map<String, dynamic> message = Map<String, dynamic>.from(
          event.snapshot.value as Map<dynamic, dynamic>,
        );
        message['id'] = event.snapshot.key;

        setState(() {
          messages.add(message);
          messages.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
        });

        _scrollToBottom();
      }
    });
  }

  Future<void> _loadMessages() async {
    setState(() => isLoading = true);

    try {
      final snapshot =
          await _database.child('messages').child(widget.roomId).get();

      if (snapshot.exists) {
        List<Map<String, dynamic>> loadedMessages = [];
        Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;

        data.forEach((key, value) {
          Map<String, dynamic> message = Map<String, dynamic>.from(value);
          message['id'] = key;
          loadedMessages.add(message);

          // Debug logging for each message
          print('📋 Message loaded: ${message.toString()}');
          print('   File type: ${message['file_type']}');
          print('   File URL: ${message['file_url']}');
        });

        // Sort by timestamp in Dart (no index needed)
        loadedMessages.sort(
            (a, b) => (a['timestamp'] ?? 0).compareTo(b['timestamp'] ?? 0));

        setState(() {
          messages = loadedMessages;
          isLoading = false;
        });

        _scrollToBottom();
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error loading messages: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || isSending) return;

    String messageText = _messageController.text.trim();
    _messageController.clear();

    setState(() => isSending = true);

    try {
      String currentUserId =
          widget.currentUser['uid'] ?? widget.currentUser['id'].toString();
      int timestamp = DateTime.now().millisecondsSinceEpoch;

      await _database.child('messages').child(widget.roomId).push().set({
        'sender_id': currentUserId,
        'sender_type': widget.userType,
        'message': messageText,
        'timestamp': timestamp,
        'read': false,
      });

      // Update chat room last activity
      await _database.child('chat_rooms').child(widget.roomId).update({
        'last_message': messageText,
        'last_message_time': timestamp,
        'last_sender_id': currentUserId,
      });

      // Send notification to recipient
      try {
        String recipientId = widget.otherUser['uid'] ?? widget.otherUser['id'].toString();
        String senderName = widget.currentUser['nama_lengkap'] ?? 'User';
        
        await NotificationService.sendChatNotification(
          recipientId: recipientId,
          senderName: senderName,
          message: messageText,
          roomId: widget.roomId,
        );
      } catch (e) {
        print('Error sending notification: $e');
        // Don't show error to user for notification failure
      }

      setState(() => isSending = false);
    } catch (e) {
      print('Error sending message: $e');
      setState(() => isSending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim pesan: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
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

  Future<void> _pickAndSendImage() async {
    if (isUploading) return;

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        await _uploadAndSendFile(image, 'image');
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih gambar: $e')),
        );
      }
    }
  }

  Future<void> _pickAndSendFile() async {
    if (isUploading) return;

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'xls',
          'xlsx',
          'ppt',
          'pptx',
          'txt'
        ],
      );

      if (result != null && result.files.isNotEmpty) {
        await _uploadAndSendFile(result.files.first, 'file');
      }
    } catch (e) {
      print('Error picking file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih file: $e')),
        );
      }
    }
  }

  Future<void> _uploadAndSendFile(dynamic file, String type) async {
    setState(() {
      isUploading = true;
      uploadProgress = 0.0;
    });

    try {
      String currentUserId =
          widget.currentUser['uid'] ?? widget.currentUser['id'].toString();
      int timestamp = DateTime.now().millisecondsSinceEpoch;

      String fileName;
      Uint8List fileBytes;

      if (type == 'image' && file is XFile) {
        fileName = file.name;
        fileBytes = Uint8List.fromList(await file.readAsBytes());
      } else if (file is PlatformFile) {
        fileName = file.name;
        if (kIsWeb) {
          fileBytes = file.bytes!;
        } else {
          fileBytes = await File(file.path!).readAsBytes();
        }
      } else {
        throw Exception('Invalid file type');
      }

      // Create storage reference
      String storagePath = 'chat_files/${widget.roomId}/$timestamp\_$fileName';
      final storageRef = FirebaseStorage.instance.ref().child(storagePath);

      // Upload file
      UploadTask uploadTask = storageRef.putData(
        fileBytes,
        SettableMetadata(
            contentType:
                type == 'image' ? 'image/jpeg' : 'application/octet-stream'),
      );

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (mounted) {
          setState(() {
            uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
          });
        }
      });

      // Wait for upload to complete
      await uploadTask;

      // Get download URL
      String downloadUrl = await storageRef.getDownloadURL();

      // Send message with file URL
      await _database.child('messages').child(widget.roomId).push().set({
        'sender_id': currentUserId,
        'sender_type': widget.userType,
        'message': type == 'image' ? '📷 Gambar' : '📎 $fileName',
        'file_url': downloadUrl,
        'file_name': fileName,
        'file_type': type,
        'timestamp': timestamp,
        'read': false,
      });

      // Update chat room last activity
      await _database.child('chat_rooms').child(widget.roomId).update({
        'last_message': type == 'image' ? '📷 Gambar' : '📎 File',
        'last_message_time': timestamp,
        'last_sender_id': currentUserId,
      });

      if (mounted) {
        setState(() {
          isUploading = false;
          uploadProgress = 0.0;
        });
      }
    } catch (e) {
      print('Error uploading file: $e');
      if (mounted) {
        setState(() {
          isUploading = false;
          uploadProgress = 0.0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim file: $e')),
        );
      }
    }
  }

  String _formatMessageTime(int timestamp) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    DateTime now = DateTime.now();

    if (date.day == now.day &&
        date.month == now.month &&
        date.year == now.year) {
      // Today - show time only
      return DateFormat('HH:mm').format(date);
    } else if (date.year == now.year) {
      // This year - show date and time
      return DateFormat('dd MMM, HH:mm').format(date);
    } else {
      // Different year - show full date and time
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    }
  }

  Future<void> _showPelajarProfile() async {
    try {
      // Load full pelajar data from Firebase
      final snapshot = await _database
          .child('pelajar')
          .child(widget.otherUser['uid'] ?? widget.otherUser['id'].toString())
          .get();

      if (snapshot.exists) {
        final pelajarData = Map<String, dynamic>.from(snapshot.value as Map);
        
        if (!mounted) return;
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Profile Pelajar'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue[700],
                      backgroundImage: pelajarData['profile_photo_url'] != null
                          ? NetworkImage(pelajarData['profile_photo_url'])
                          : null,
                      child: pelajarData['profile_photo_url'] == null
                          ? Text(
                              (pelajarData['nama_lengkap'] ?? 'P')[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 40,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildProfileRow(Icons.person, 'Nama', pelajarData['nama_lengkap'] ?? '-'),
                  _buildProfileRow(Icons.email, 'Email', pelajarData['email'] ?? '-'),
                  _buildProfileRow(Icons.phone, 'Telepon', pelajarData['phone'] ?? '-'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Error loading pelajar profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat profile pelajar')),
        );
      }
    }
  }

  Future<void> _showMentorProfile() async {
    try {
      // Load full mentor data from Firebase
      final snapshot = await _database
          .child('mentors')
          .child(widget.otherUser['uid'] ?? widget.otherUser['id'].toString())
          .get();

      if (snapshot.exists) {
        final mentorData = Map<String, dynamic>.from(snapshot.value as Map);
        
        if (!mounted) return;
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Profile Mentor'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue[700],
                      backgroundImage: mentorData['profile_photo_url'] != null
                          ? NetworkImage(mentorData['profile_photo_url'])
                          : null,
                      child: mentorData['profile_photo_url'] == null
                          ? Text(
                              (mentorData['nama_lengkap'] ?? 'M')[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 40,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildProfileRow(Icons.person, 'Nama', mentorData['nama_lengkap'] ?? '-'),
                  _buildProfileRow(Icons.email, 'Email', mentorData['email'] ?? '-'),
                  _buildProfileRow(Icons.phone, 'Telepon', mentorData['phone'] ?? '-'),
                  _buildProfileRow(Icons.school, 'Bidang Keahlian', mentorData['bidang_keahlian'] ?? '-'),
                  _buildProfileRow(Icons.work, 'Pengalaman', '${mentorData['pengalaman'] ?? '-'} tahun'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Error loading mentor profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat profile mentor')),
        );
      }
    }
  }

  Widget _buildProfileRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
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
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String currentUserId =
        widget.currentUser['uid'] ?? widget.currentUser['id'].toString();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                if (widget.userType == 'mentor') {
                  // Mentor melihat profile pelajar
                  _showPelajarProfile();
                } else {
                  // Pelajar melihat profile mentor
                  _showMentorProfile();
                }
              },
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                backgroundImage: widget.otherUser['profile_photo_url'] != null
                    ? NetworkImage(widget.otherUser['profile_photo_url'])
                    : null,
                child: widget.otherUser['profile_photo_url'] == null
                    ? Text(
                        widget.otherUser['nama_lengkap'][0].toUpperCase(),
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.otherUser['nama_lengkap'] ?? 'User',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        actions: widget.userType == 'mentor'
            ? [
                // Voice call button
                IconButton(
                  icon: const Icon(Icons.call, color: Colors.white),
                  onPressed: () => _startCall(false),
                  tooltip: 'Voice Call',
                ),
                // Video call button
                IconButton(
                  icon: const Icon(Icons.videocam, color: Colors.white),
                  onPressed: () => _startCall(true),
                  tooltip: 'Video Call',
                ),
                const SizedBox(width: 8),
              ]
            : null,
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Mulai percakapan',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          return _buildMessageBubble(
                            messages[index],
                            currentUserId,
                          );
                        },
                      ),
          ),

          // Message Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Upload progress indicator
                  if (isUploading)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Column(
                        children: [
                          LinearProgressIndicator(
                            value: uploadProgress,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue[700]!),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Mengirim file... ${(uploadProgress * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      // Attachment button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.attach_file,
                            color: isUploading ? Colors.grey : Colors.blue[700],
                          ),
                          onPressed: isUploading
                              ? null
                              : () {
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (context) {
                                      return SafeArea(
                                        child: Wrap(
                                          children: [
                                            ListTile(
                                              leading: Icon(Icons.image,
                                                  color: Colors.blue[700]),
                                              title: const Text(
                                                  'Gambar dari Galeri'),
                                              onTap: () {
                                                Navigator.pop(context);
                                                _pickAndSendImage();
                                              },
                                            ),
                                            ListTile(
                                              leading: Icon(
                                                  Icons.insert_drive_file,
                                                  color: Colors.blue[700]),
                                              title: const Text('Dokumen'),
                                              onTap: () {
                                                Navigator.pop(context);
                                                _pickAndSendFile();
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: _messageController,
                            maxLines: null,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: 'Ketik pesan...',
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              hintStyle: TextStyle(color: Colors.grey[500]),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.blue[700],
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: isSending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.send,
                                  color: Colors.white,
                                  size: 20,
                                ),
                          onPressed: isSending ? null : _sendMessage,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
      Map<String, dynamic> message, String currentUserId) {
    bool isMe = message['sender_id'] == currentUserId;

    // Debug logging
    print('📋 Message data: ${message.toString()}');
    print('📸 File type: ${message['file_type']}');
    print('🔗 File URL: ${message['file_url']}');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue[100],
              backgroundImage: widget.otherUser['profile_photo_url'] != null
                  ? NetworkImage(widget.otherUser['profile_photo_url'])
                  : null,
              child: widget.otherUser['profile_photo_url'] == null
                  ? Text(
                      widget.otherUser['nama_lengkap'][0].toUpperCase(),
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  decoration: BoxDecoration(
                    color: message['file_type'] == 'image'
                        ? Colors.transparent
                        : (isMe ? Colors.blue[700] : Colors.white),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    boxShadow: message['file_type'] == 'image'
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 2,
                            ),
                          ],
                  ),
                  child: message['file_type'] == 'image'
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: 250,
                              maxHeight: 400,
                            ),
                            child: kIsWeb
                                ? _buildWebImage(
                                    message['file_url'] ?? '',
                                    onTap: () => _showImagePreview(
                                        context, message['file_url'] ?? ''),
                                  )
                                : GestureDetector(
                                    onTap: () => _showImagePreview(
                                        context, message['file_url'] ?? ''),
                                    child: Image.network(
                                      message['file_url'] ?? '',
                                      fit: BoxFit.contain,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }
                                        return Container(
                                          width: 250,
                                          height: 250,
                                          color: Colors.grey[200],
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress
                                                          .expectedTotalBytes !=
                                                      null
                                                  ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                  : null,
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        print('❌ Image load error: $error');
                                        return Container(
                                          width: 250,
                                          padding: const EdgeInsets.all(16),
                                          color: Colors.grey[200],
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.broken_image,
                                                  size: 48, color: Colors.grey),
                                              const SizedBox(height: 8),
                                              const Text(
                                                'Gagal memuat gambar',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                          ),
                        )
                      : message['file_type'] == 'file'
                          ? InkWell(
                              onTap: () async {
                                // Open file in browser
                                final url = message['file_url'];
                                if (url != null) {
                                  if (kIsWeb) {
                                    // For web, use window.open
                                    // ignore: avoid_web_libraries_in_flutter
                                    // You may need to add url_launcher package
                                    print('Opening file: $url');
                                  }
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.insert_drive_file,
                                      color: isMe
                                          ? Colors.white
                                          : Colors.blue[700],
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            message['file_name'] ?? 'File',
                                            style: TextStyle(
                                              color: isMe
                                                  ? Colors.white
                                                  : Colors.black87,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            'Tap untuk membuka',
                                            style: TextStyle(
                                              color: isMe
                                                  ? Colors.white70
                                                  : Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              child: Text(
                                message['message'] ?? '',
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black87,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatMessageTime(message['timestamp']),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Listen for incoming calls
  void _listenToIncomingCalls() {
    // Both mentor and pelajar can receive calls
    String currentUserId = widget.currentUser['uid'] ?? widget.currentUser['id'].toString();
    
    _callSubscription = _database
        .child('calls')
        .child(widget.roomId)
        .onValue
        .listen((event) {
      if (event.snapshot.value != null) {
        Map<String, dynamic> callData = Map<String, dynamic>.from(
          event.snapshot.value as Map<dynamic, dynamic>,
        );

        String callState = callData['state'] ?? '';
        String callerId = callData['caller_id'] ?? '';

        print('📞 Call state changed: $callState, caller: $callerId, me: $currentUserId');

        // Only show dialog for incoming calls (not my own calls)
        if (callState == 'pending' && callerId != currentUserId) {
          print('📞 Showing incoming call dialog');
          _showIncomingCallDialog(callData);
        }
      }
    });
  }

  // Show incoming call dialog
  void _showIncomingCallDialog(Map<String, dynamic> callData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => IncomingCallDialog(
        callerName: widget.otherUser['nama_lengkap'] ?? 'Unknown',
        isVideoCall: callData['is_video'] ?? true,
        roomId: widget.roomId,
        onAccept: () {
          Navigator.of(context).pop();
          _acceptCall(callData);
        },
        onReject: () {
          Navigator.of(context).pop();
          _rejectCall(callData);
        },
      ),
    );
  }

  // Accept incoming call
  Future<void> _acceptCall(Map<String, dynamic> callData) async {
    try {
      // Update call state
      await _database.child('calls').child(widget.roomId).update({
        'state': 'accepted',
      });

      // Navigate to video call screen
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoCallScreen(
            channelName: callData['channel_id'] ?? '',
            token: '', // Empty token for Agora (will work for testing)
            currentUserId: widget.currentUser['uid'] ?? widget.currentUser['id'].toString(),
            currentUserName: widget.currentUser['nama_lengkap'] ?? 'User',
            otherUserName: widget.otherUser['nama_lengkap'] ?? 'User',
            isVideoCall: callData['is_video'] ?? true,
            roomId: widget.roomId,
            bookingEndTime: bookingData?['jam_selesai'],
          ),
        ),
      );
    } catch (e) {
      print('Error accepting call: $e');
    }
  }

  // Reject incoming call
  Future<void> _rejectCall(Map<String, dynamic> callData) async {
    try {
      await _database.child('calls').child(widget.roomId).update({
        'state': 'rejected',
      });
    } catch (e) {
      print('Error rejecting call: $e');
    }
  }

  // Start a new call
  Future<void> _startCall(bool isVideoCall) async {
    try {
      // Generate channel ID
      String channelId = 'call_${widget.roomId}_${DateTime.now().millisecondsSinceEpoch}';
      String currentUserId = widget.currentUser['uid'] ?? widget.currentUser['id'].toString();

      // Create call in Firebase
      await _database.child('calls').child(widget.roomId).set({
        'caller_id': currentUserId,
        'channel_id': channelId,
        'is_video': isVideoCall,
        'state': 'pending',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      // Send call notification to recipient
      try {
        String recipientId = widget.otherUser['uid'] ?? widget.otherUser['id'].toString();
        String callerName = widget.currentUser['nama_lengkap'] ?? 'User';
        
        await NotificationService.sendCallNotification(
          recipientId: recipientId,
          callerName: callerName,
          isVideo: isVideoCall,
          roomId: widget.roomId,
          channelId: channelId,
        );
      } catch (e) {
        print('Error sending call notification: $e');
        // Don't show error to user for notification failure
      }

      // Navigate to video call screen
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoCallScreen(
            channelName: channelId,
            token: '', // Empty token for Agora (will work for testing)
            currentUserId: widget.currentUser['uid'] ?? widget.currentUser['id'].toString(),
            currentUserName: widget.currentUser['nama_lengkap'] ?? 'User',
            otherUserName: widget.otherUser['nama_lengkap'] ?? 'User',
            isVideoCall: isVideoCall,
            roomId: widget.roomId,
            bookingEndTime: bookingData?['jam_selesai'],
          ),
        ),
      );
    } catch (e) {
      print('Error starting call: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start call: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _callSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Web-specific image widget using HTML img element
  Widget _buildWebImage(String url, {VoidCallback? onTap}) {
    return buildWebImage(url, onTap: onTap);
  }

  // Show full-screen image preview
  void _showImagePreview(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      barrierDismissible: true,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(16),
          child: Stack(
            children: [
              // Full image
              Center(
                child: GestureDetector(
                  onTap: () {}, // Prevent closing when tapping image
                  child: InteractiveViewer(
                    maxScale: 5.0,
                    minScale: 0.5,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 200,
                          height: 200,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              value: loadingProgress.expectedTotalBytes !=
                                      null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              // Close button - positioned at top right with high z-index
              Positioned(
                top: 0,
                right: 0,
                child: Material(
                  color: Colors.transparent,
                  child: IconButton(
                    icon: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 24),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
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
