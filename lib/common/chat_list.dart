import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../widgets/cached_circle_avatar.dart';
import 'chat_room.dart';

class ChatListPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String userType; // 'mentor' or 'pelajar'

  const ChatListPage({
    super.key,
    required this.userData,
    required this.userType,
  });

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> chatRooms = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChatRooms();
  }

  Future<void> _loadChatRooms() async {
    setState(() => isLoading = true);

    try {
      String userId =
          widget.userData['uid'] ?? widget.userData['id'].toString();

      print('🔍 Loading chat rooms for ${widget.userType}: $userId');
      print('📋 User data: ${widget.userData}');

      // Load all chat rooms and filter by user ID
      final snapshot = await _database.child('chat_rooms').get();

      if (snapshot.exists) {
        List<Map<String, dynamic>> rooms = [];
        Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;

        print('📊 Found ${data.length} total chat rooms');

        for (var entry in data.entries) {
          Map<String, dynamic> room = Map<String, dynamic>.from(entry.value);

          // Debug: print room details
          print('\n🔍 Checking room: ${entry.key}');
          print('   - pelajar_id: ${room['pelajar_id']} (${room['pelajar_id'].runtimeType})');
          print('   - mentor_id: ${room['mentor_id']} (${room['mentor_id'].runtimeType})');
          print('   - Current user: $userId (${userId.runtimeType}) (${widget.userType})');

          // Check if this room belongs to current user - convert all to string for comparison
          String roomPelajarId = (room['pelajar_id'] ?? '').toString();
          String roomMentorId = (room['mentor_id'] ?? '').toString();
          String currentUserId = userId.toString();

          bool isUserRoom = false;
          if (widget.userType == 'pelajar') {
            isUserRoom = (roomPelajarId == currentUserId);
            print('   - Pelajar check: "$roomPelajarId" == "$currentUserId" ? $isUserRoom');
          } else if (widget.userType == 'mentor') {
            isUserRoom = (roomMentorId == currentUserId);
            print('   - Mentor check: "$roomMentorId" == "$currentUserId" ? $isUserRoom');
          }

          if (!isUserRoom) {
            print('   ❌ Skipping room (not for this user)\n');
            continue;
          }

          print('  ✅ Found matching room: ${entry.key}\n');
          room['room_id'] = entry.key;

          // Load last message - get all messages and find the latest one
          try {
            final lastMsgSnapshot = await _database
                .child('messages')
                .child(entry.key)
                .get();

            if (lastMsgSnapshot.exists && lastMsgSnapshot.value != null) {
              Map<dynamic, dynamic> messages =
                  lastMsgSnapshot.value as Map<dynamic, dynamic>;
              
              if (messages.isNotEmpty) {
                // Find message with highest timestamp
                var lastMsg = messages.values.reduce((a, b) {
                  int timestampA = a['timestamp'] ?? 0;
                  int timestampB = b['timestamp'] ?? 0;
                  return timestampA > timestampB ? a : b;
                });
                
                room['last_message'] = lastMsg['message'] ?? 'Chat dimulai';
                room['last_message_time'] = lastMsg['timestamp'] ?? room['created_at'];
                room['last_sender_id'] = lastMsg['sender_id'];
              } else {
                // Messages empty
                room['last_message'] = room['last_message'] ?? 'Chat dimulai';
                room['last_message_time'] =
                    room['created_at'] ?? DateTime.now().millisecondsSinceEpoch;
              }
            } else {
              // Use default from room creation
              room['last_message'] = room['last_message'] ?? 'Chat dimulai';
              room['last_message_time'] =
                  room['created_at'] ?? DateTime.now().millisecondsSinceEpoch;
            }
          } catch (e) {
            print('⚠️ Error loading last message for ${entry.key}: $e');
            // Use default from room creation
            room['last_message'] = room['last_message'] ?? 'Chat dimulai';
            room['last_message_time'] =
                room['created_at'] ?? DateTime.now().millisecondsSinceEpoch;
          }

          // Load other user's info
          String otherUserId =
              widget.userType == 'mentor' ? roomPelajarId : roomMentorId;
          String otherUserNode =
              widget.userType == 'mentor' ? 'pelajar' : 'mentors';

          final userSnapshot =
              await _database.child(otherUserNode).child(otherUserId).get();

          if (userSnapshot.exists) {
            room['other_user'] = Map<String, dynamic>.from(
              userSnapshot.value as Map<dynamic, dynamic>,
            );
            room['other_user']['uid'] = otherUserId;
            room['other_user']['id'] = otherUserId;
          } else {
            // Use name from chat room if user data not found
            room['other_user'] = {
              'uid': otherUserId,
              'id': otherUserId,
              'nama_lengkap': widget.userType == 'mentor'
                  ? room['pelajar_name']
                  : room['mentor_name'],
            };
          }

          // Load booking info to get mata_pelajaran and session details
          try {
            final bookingSnapshot = await _database
                .child('bookings')
                .orderByChild(widget.userType == 'mentor' ? 'mentor_id' : 'pelajar_id')
                .equalTo(currentUserId)
                .get();

            if (bookingSnapshot.exists) {
              Map<dynamic, dynamic> bookings = bookingSnapshot.value as Map<dynamic, dynamic>;
              // Find booking between current user and other user
              for (var bookingEntry in bookings.entries) {
                var booking = bookingEntry.value;
                String bookingOtherUserId = widget.userType == 'mentor' 
                    ? booking['pelajar_id'].toString()
                    : booking['mentor_id'].toString();
                
                if (bookingOtherUserId == otherUserId) {
                  // Load jadwal info to get mata_pelajaran
                  String jadwalId = booking['jadwal_id'].toString();
                  String jadwalMentorId = booking['mentor_id'].toString();
                  
                  final jadwalSnapshot = await _database
                      .child('jadwal')
                      .child(jadwalMentorId)
                      .child(jadwalId)
                      .get();
                  
                  if (jadwalSnapshot.exists) {
                    var jadwalData = jadwalSnapshot.value as Map<dynamic, dynamic>;
                    room['mata_pelajaran'] = jadwalData['mata_pelajaran'] ?? 'Sesi Mentoring';
                    room['tanggal'] = booking['tanggal'] ?? '';
                    room['jam_mulai'] = booking['jam_mulai'] ?? '';
                    room['jam_selesai'] = booking['jam_selesai'] ?? '';
                    print('📚 Loaded mata pelajaran: ${room['mata_pelajaran']}');
                  }
                  break; // Use first matching booking
                }
              }
            }
          } catch (e) {
            print('⚠️ Error loading booking info: $e');
            // Continue without booking info
          }

          rooms.add(room);
        }

        print('✅ Loaded ${rooms.length} chat rooms for user');

        // Sort by last message time
        rooms.sort((a, b) {
          int timeA = a['last_message_time'] ?? 0;
          int timeB = b['last_message_time'] ?? 0;
          return timeB.compareTo(timeA);
        });

        setState(() {
          chatRooms = rooms;
          isLoading = false;
        });
      } else {
        print('⚠️ No chat rooms found in Firebase');
        setState(() {
          chatRooms = [];
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading chat rooms: $e');
      setState(() => isLoading = false);
    }
  }

  String _formatTime(int timestamp) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    DateTime now = DateTime.now();
    Duration diff = now.difference(date);

    if (diff.inDays == 0) {
      // Today - show time
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Kemarin';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} hari lalu';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Pesan',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : chatRooms.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada percakapan',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (widget.userType == 'pelajar')
                        Text(
                          'Mulai chat setelah booking mentor',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadChatRooms,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: chatRooms.length,
                    itemBuilder: (context, index) {
                      return _buildChatTile(chatRooms[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildChatTile(Map<String, dynamic> chatRoom) {
    Map<String, dynamic>? otherUser = chatRoom['other_user'];
    if (otherUser == null) return const SizedBox.shrink();

    String name = otherUser['nama_lengkap'] ?? 'User';
    String lastMessage = chatRoom['last_message'] ?? '';
    int lastMessageTime = chatRoom['last_message_time'] ?? 0;
    String lastSenderId = chatRoom['last_sender_id'] ?? '';
    String currentUserId =
        widget.userData['uid'] ?? widget.userData['id'].toString();

    bool isMe = lastSenderId == currentUserId;
    String displayMessage = isMe ? 'Anda: $lastMessage' : lastMessage;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: FutureBuilder<String>(
          future: _getOtherUserPhotoUrl(chatRoom),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircleAvatar(
                radius: 28,
                backgroundColor: Colors.grey[300],
                child: const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                  ),
                ),
              );
            }
            
            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              return CachedCircleAvatar(
                imageUrl: snapshot.data!,
                radius: 28,
                fallbackIcon: Icons.person,
              );
            }
            
            // Fallback to first letter
            return CircleAvatar(
              radius: 28,
              backgroundColor: Colors.blue[100],
              child: Text(
                name[0].toUpperCase(),
                style: TextStyle(
                  color: Colors.blue[700],
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Show mata pelajaran for mentor to differentiate students
              if (widget.userType == 'mentor' && chatRoom['mata_pelajaran'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.book, size: 14, color: Colors.blue[700]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          chatRoom['mata_pelajaran'],
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              Text(
                displayMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatTime(lastMessageTime),
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: 20,
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatRoom(
                roomId: chatRoom['room_id'],
                currentUser: widget.userData,
                otherUser: otherUser,
                userType: widget.userType,
              ),
            ),
          ).then((_) => _loadChatRooms());
        },
      ),
    );
  }

  // Get other user's photo URL from database
  Future<String> _getOtherUserPhotoUrl(Map<String, dynamic> chatRoom) async {
    try {
      // Get other user data that was loaded in _loadChatRooms
      final otherUser = chatRoom['other_user'];
      if (otherUser == null) {
        print('⚠️ Other user data not found in chat room');
        return '';
      }

      // Check if profile_photo_url exists
      final photoUrl = otherUser['profile_photo_url'];
      if (photoUrl != null && photoUrl.toString().isNotEmpty) {
        print('✅ Photo URL found for ${otherUser['nama_lengkap']}: $photoUrl');
        return photoUrl.toString();
      }

      print('⚠️ No photo URL for ${otherUser['nama_lengkap']}');
      return '';
    } catch (e) {
      print('❌ Error getting photo URL: $e');
      return '';
    }
  }
}
