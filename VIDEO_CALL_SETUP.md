# Video Call Setup Guide

Fitur video dan voice call sudah berhasil diimplementasikan menggunakan Agora RTC Engine! 🎉

## Status Implementasi

✅ **Sudah Selesai:**
- Package `agora_rtc_engine` dan `permission_handler` terinstall
- UI untuk video call (VideoCallScreen) dengan kontrol lengkap:
  - Toggle kamera on/off
  - Toggle mikrofon mute/unmute
  - Switch kamera depan/belakang
  - Timer durasi panggilan
  - Tombol end call
  - Mode voice-only call
- Dialog incoming call (IncomingCallDialog) dengan tombol accept/reject
- Integrasi dengan Firebase Realtime Database untuk signaling
- Tombol call di chat (hanya untuk mentor):
  - Ikon telepon (voice call)
  - Ikon video (video call)
- Call listener untuk pelajar (otomatis menerima notifikasi)

## Cara Mengaktifkan Agora

### 1. Buat Akun Agora (GRATIS)
1. Kunjungi: https://console.agora.io/
2. Klik "Sign Up" atau gunakan Google/GitHub account
3. Verifikasi email Anda

### 2. Buat Project Baru
1. Setelah login, klik "Create New Project"
2. Nama project: **Mentorly App** (atau bebas)
3. Pilih "Secured mode: APP ID + Token" untuk production
   - Untuk testing, bisa pilih "Testing mode: APP ID only" (lebih mudah)
4. Klik "Submit"

### 3. Dapatkan APP ID
1. Di dashboard, klik project yang baru dibuat
2. Copy **APP ID** yang ditampilkan
3. Simpan APP ID ini

### 4. Konfigurasi di Aplikasi

**PENTING:** Anda perlu menambahkan APP ID ke aplikasi.

Ada 2 cara:

#### Cara 1: Hardcode APP ID (untuk testing/development)
Edit file `lib/common/video_call_screen.dart` pada line 50-60 (fungsi `_initializeAgora`):

```dart
Future<void> _initializeAgora() async {
  // Request permissions
  await [Permission.microphone, Permission.camera].request();

  // Initialize Agora engine
  _engine = createAgoraRtcEngine();
  await _engine.initialize(RtcEngineContext(
    appId: 'PASTE_YOUR_APP_ID_HERE',  // <-- Ganti dengan APP ID Anda
    channelProfile: ChannelProfileType.channelProfileCommunication,
  ));
```

#### Cara 2: Environment Variable (recommended untuk production)
1. Buat file `.env` di root project
2. Tambahkan: `AGORA_APP_ID=your_app_id_here`
3. Install package `flutter_dotenv`
4. Load di `main.dart` dan pass ke VideoCallScreen

## Cara Testing

### Test sebagai Mentor:
1. Buka chat dengan seorang pelajar
2. Klik ikon video (untuk video call) atau ikon telepon (untuk voice call) di AppBar
3. Aplikasi akan meminta permission kamera/mikrofon (izinkan)
4. VideoCallScreen akan muncul dan menunggu pelajar join

### Test sebagai Pelajar:
1. Saat mentor memulai call, dialog incoming call akan muncul otomatis
2. Klik "Accept" untuk menerima atau "Reject" untuk menolak
3. Jika accept, VideoCallScreen akan muncul dan call dimulai

### Fitur yang Bisa Ditest:
- ✅ Video call (mentor → pelajar)
- ✅ Voice call (mentor → pelajar)
- ✅ Toggle kamera on/off
- ✅ Toggle mikrofon mute/unmute
- ✅ Switch kamera depan/belakang
- ✅ Timer durasi call
- ✅ End call
- ✅ Accept/Reject incoming call
- ✅ Call state management via Firebase

## Firebase Database Structure

Call data disimpan di:
```
/calls/{roomId}/
  - caller_id: "uid_mentor"
  - channel_id: "call_roomId_timestamp"
  - is_video: true/false
  - state: "pending" | "accepted" | "rejected" | "ended"
  - timestamp: 1234567890
```

## Troubleshooting

### Problem: "Permission denied"
**Solusi:** Pastikan user mengizinkan akses kamera dan mikrofon saat diminta.

### Problem: "Unable to join channel"
**Solusi:** 
1. Periksa APP ID sudah benar
2. Pastikan internet connection stabil
3. Cek Firebase rules mengizinkan read/write ke `/calls/`

### Problem: "Video tidak muncul"
**Solusi:** 
1. Periksa permission kamera sudah diizinkan
2. Test di real device (emulator kadang bermasalah)
3. Pastikan kamera tidak digunakan aplikasi lain

### Problem: "Incoming call tidak muncul"
**Solusi:** 
1. Pastikan pelajar membuka chat yang sama
2. Cek Firebase connection (internet)
3. Periksa console log untuk error

## Platform Support

- ✅ Android (fully supported)
- ✅ iOS (fully supported)
- ⚠️ Web (limited - needs web RTC configuration)
- ❌ Desktop (not tested)

## Limits Agora Free Tier

- 10,000 menit gratis per bulan
- Unlimited projects
- Max 17 concurrent users per channel
- Cukup untuk development dan testing!

## Next Steps (Optional Enhancements)

1. **Call History**: Simpan riwayat panggilan di Firebase
2. **Call Recording**: Gunakan Agora Cloud Recording
3. **Group Call**: Support multiple participants
4. **Push Notifications**: Notifikasi call saat app di background
5. **Network Quality Indicator**: Tampilkan kualitas koneksi
6. **Screen Sharing**: Share screen during call

## Helpful Links

- [Agora Documentation](https://docs.agora.io/en/)
- [Agora Flutter Quickstart](https://docs.agora.io/en/voice-calling/get-started/get-started-sdk?platform=flutter)
- [Agora Console](https://console.agora.io/)

---

**Selamat! Fitur video call sudah siap digunakan! 🚀**

Jika ada pertanyaan atau masalah, jangan ragu untuk bertanya.
