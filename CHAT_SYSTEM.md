# Sistem Chat Mentor-Pelajar

## 📋 Overview

Sistem chat 1-on-1 antara mentor dan pelajar menggunakan Firebase Realtime Database. Chat room hanya dibuat SETELAH pelajar melakukan booking kepada mentor.

## 🏗️ Struktur Database Firebase

```
firebase-root/
├── chat_rooms/
│   └── {roomId}/
│       ├── mentor_id: "uid-mentor"
│       ├── pelajar_id: "uid-pelajar"
│       ├── mentor_name: "Nama Mentor"
│       ├── pelajar_name: "Nama Pelajar"
│       ├── created_at: timestamp
│       ├── last_message: "Pesan terakhir"
│       ├── last_message_time: timestamp
│       └── last_sender_id: "uid-pengirim"
│
└── messages/
    └── {roomId}/
        └── {messageId}/
            ├── sender_id: "uid-pengirim"
            ├── sender_type: "mentor" | "pelajar"
            ├── message: "Isi pesan"
            ├── timestamp: 1234567890
            └── read: false
```

## 📱 Komponen Chat System

### 1. **Chat List Page** (`common/chat_list.dart`)
Halaman daftar percakapan untuk mentor dan pelajar.

**Features:**
- ✅ Menampilkan semua chat rooms user
- ✅ Sortir berdasarkan pesan terakhir
- ✅ Preview pesan terakhir
- ✅ Waktu relatif (Today, Kemarin, dll)
- ✅ Avatar dengan initial nama
- ✅ Pull to refresh
- ✅ Empty state dengan pesan berbeda untuk mentor/pelajar

**Usage:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ChatListPage(
      userData: mentorData, // atau pelajarData
      userType: 'mentor',   // atau 'pelajar'
    ),
  ),
);
```

### 2. **Chat Room Page** (`common/chat_room.dart`)
Halaman percakapan 1-on-1 antara mentor dan pelajar.

**Features:**
- ✅ Real-time messaging dengan Firebase
- ✅ Message bubbles dengan design modern
- ✅ Auto-scroll ke pesan terbaru
- ✅ Timestamp pada setiap pesan
- ✅ Indikator loading saat mengirim
- ✅ Input multiline
- ✅ Send button dengan icon
- ✅ Empty state untuk chat baru

**Styling:**
- Pesan dari user: Bubble biru di kanan
- Pesan dari lawan bicara: Bubble putih di kiri
- Border radius asimetris untuk efek bubble
- Shadow untuk depth
- Timestamp dengan format smart (HH:mm, dd MMM, dll)

### 3. **Auto-Create Chat Room** (`pelajar/konfirmasi_booking.dart`)
Chat room otomatis dibuat saat pelajar berhasil booking mentor.

**Flow:**
1. Pelajar melakukan booking
2. Booking berhasil diproses
3. System cek apakah chat room sudah ada
4. Jika belum ada, buat chat room baru
5. Redirect ke payment success page

**Implementation:**
```dart
Future<void> _createChatRoom() async {
  final database = FirebaseDatabase.instance.ref();
  
  // Check if room exists
  final snapshot = await database
      .child('chat_rooms')
      .orderByChild('pelajar_id')
      .equalTo(pelajarId)
      .get();
  
  // Create if not exists
  if (!roomExists) {
    await database.child('chat_rooms').push().set({
      'mentor_id': mentorId,
      'pelajar_id': pelajarId,
      // ... other fields
    });
  }
}
```

## 🔐 Aturan Akses

### Chat Room Creation Rules
- ❌ **Mentor TIDAK BISA** membuat chat room baru
- ✅ **Pelajar HANYA BISA** membuat setelah booking
- ✅ Chat room otomatis dibuat oleh sistem
- ✅ Duplikasi dicegah dengan checking existing room

### Messaging Rules  
- ✅ **Mentor & Pelajar** bisa mengirim pesan
- ✅ Hanya dalam chat room yang sudah ada
- ✅ Real-time updates untuk kedua belah pihak

## 🎯 User Flow

### Flow Pelajar:
1. **Browse Mentors** → Dashboard Pelajar
2. **Pilih Mentor** → Detail Mentor
3. **Book Session** → Konfirmasi Booking
4. **Payment Success** → Chat Room Auto-Created ✅
5. **Click Chat Icon** → Lihat Daftar Chat
6. **Open Chat** → Mulai Percakapan

### Flow Mentor:
1. **Login** → Dashboard Mentor
2. **Wait for Booking** → Pelajar book session
3. **Chat Room Created** (automatic)
4. **Click Chat Icon** → Lihat Daftar Chat
5. **Open Chat** → Balas Pesan Pelajar

## 📲 Navigation

### Mentor Dashboard
```dart
BottomNavigationBar(
  items: [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
    BottomNavigationBarItem(icon: Icon(Icons.history), label: ''),
    BottomNavigationBarItem(icon: Icon(Icons.chat), label: ''), // ← Chat
    BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
  ],
)
```

### Pelajar Dashboard
```dart
BottomNavigationBar(
  items: [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
    BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
    BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'), // ← Chat
    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
  ],
)
```

## 💡 Features Dijelaskan

### Real-time Messaging
- Menggunakan `onChildAdded` listener
- Pesan langsung muncul tanpa refresh
- Auto-scroll ke pesan terbaru
- Efficient data loading

### Smart Timestamps
```dart
- Hari ini: "14:30"
- Kemarin: "Kemarin"
- < 7 hari: "3 hari lalu"
- > 7 hari: "15/12/2025"
```

### Message Bubbles
- Sender (kanan): Blue background, white text
- Receiver (kiri): White background, black text
- Asymmetric borders untuk efek natural
- Shadow untuk depth
- Avatar untuk receiver

### Empty States
- Chat List Empty:
  - Pelajar: "Mulai chat setelah booking mentor"
  - Mentor: "Belum ada percakapan"
- Chat Room Empty: "Mulai percakapan"

## 🧪 Testing

### Test Scenario 1: Chat Room Creation
1. Login sebagai **Pelajar**
2. Browse dan pilih **Mentor**
3. Lakukan **Booking**
4. Cek di **Firebase Console** → `chat_rooms`
5. Verify chat room dengan `pelajar_id` dan `mentor_id` sudah dibuat

### Test Scenario 2: Send Message (Pelajar)
1. Login sebagai **Pelajar**
2. Click **Chat Icon** → Lihat chat list
3. Open chat dengan mentor
4. Ketik pesan dan send
5. Verify pesan muncul di kanan (blue bubble)

### Test Scenario 3: Receive Message (Mentor)
1. Login sebagai **Mentor** (di device/browser lain)
2. Click **Chat Icon** → Lihat chat list
3. Open chat dengan pelajar
4. Verify pesan dari pelajar muncul (white bubble)
5. Reply pesan
6. Check di device pelajar → pesan auto-muncul

### Test Scenario 4: Multiple Chats
1. Login sebagai **Pelajar**
2. Book **3 mentor berbeda**
3. Click **Chat Icon**
4. Verify ada **3 chat rooms** dalam list
5. Test kirim pesan ke masing-masing

## 🔒 Firebase Security Rules

Update Firebase Realtime Database rules:

```json
{
  "rules": {
    "chat_rooms": {
      "$roomId": {
        ".read": "auth != null && (
          data.child('mentor_id').val() === auth.uid || 
          data.child('pelajar_id').val() === auth.uid
        )",
        ".write": "auth != null"
      }
    },
    "messages": {
      "$roomId": {
        ".read": "auth != null && (
          root.child('chat_rooms').child($roomId).child('mentor_id').val() === auth.uid ||
          root.child('chat_rooms').child($roomId).child('pelajar_id').val() === auth.uid
        )",
        "$messageId": {
          ".write": "auth != null && (
            root.child('chat_rooms').child($roomId).child('mentor_id').val() === auth.uid ||
            root.child('chat_rooms').child($roomId).child('pelajar_id').val() === auth.uid
          )"
        }
      }
    }
  }
}
```

## 🚀 Future Enhancements

- [ ] Image/file sharing
- [ ] Voice messages
- [ ] Read receipts (double check mark)
- [ ] Typing indicators
- [ ] Push notifications untuk pesan baru
- [ ] Delete messages
- [ ] Block/report user
- [ ] Search messages
- [ ] Archive chats
- [ ] Group chat (1 mentor + multiple pelajar)

## 📊 Data Structure Examples

### Chat Room Object
```json
{
  "chat_rooms": {
    "-NxY1234567": {
      "mentor_id": "uid-mentor-abc",
      "pelajar_id": "uid-pelajar-xyz",
      "mentor_name": "John Doe",
      "pelajar_name": "Jane Smith",
      "created_at": 1704067200000,
      "last_message": "Terima kasih atas penjelasannya!",
      "last_message_time": 1704153600000,
      "last_sender_id": "uid-pelajar-xyz"
    }
  }
}
```

### Message Object
```json
{
  "messages": {
    "-NxY1234567": {
      "-NxY1234568": {
        "sender_id": "uid-pelajar-xyz",
        "sender_type": "pelajar",
        "message": "Halo, saya mau tanya tentang materi Matematika",
        "timestamp": 1704153000000,
        "read": false
      },
      "-NxY1234569": {
        "sender_id": "uid-mentor-abc",
        "sender_type": "mentor",
        "message": "Halo! Silakan, ada yang bisa saya bantu?",
        "timestamp": 1704153100000,
        "read": true
      }
    }
  }
}
```

## 📞 Troubleshooting

### Chat room tidak dibuat setelah booking
- Check Firebase Database rules
- Verify user memiliki `uid` field
- Check console log untuk error messages
- Ensure booking berhasil (`status: 'success'`)

### Pesan tidak terkirim
- Verify user authenticated
- Check internet connection
- Verify `roomId` valid
- Check Firebase Database rules

### Chat list kosong
- Verify user pernah booking
- Check query by `pelajar_id` atau `mentor_id`
- Ensure chat room creation successful
- Check Firebase Console manually

### Real-time tidak working
- Verify listener sudah di-setup
- Check Firebase connection
- Ensure `onChildAdded` called dalam `initState`
- Test dengan 2 devices berbeda

---

**Built with ❤️ using Flutter & Firebase**
