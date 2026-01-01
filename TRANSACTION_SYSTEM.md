# Sistem Transaksi Mentor

## 📋 Overview

Sistem transaksi untuk mentor yang mencakup pelacakan penghasilan dan penarikan dana menggunakan Firebase Realtime Database.

## 🏗️ Struktur Database Firebase

```
firebase-root/
├── mentors/
│   └── {uid}/
│       ├── balance: 0                    // Saldo saat ini
│       ├── dana_proses: 0                // Dana yang sedang diproses
│       ├── last_earning: timestamp       // Waktu pemasukan terakhir
│       └── last_withdrawal: timestamp    // Waktu penarikan terakhir
│
└── transactions/
    └── {mentorUid}/
        └── {transactionId}/
            ├── type: "earning" | "withdrawal"
            ├── amount: 100000
            ├── status: "completed" | "processing" | "pending" | "failed"
            ├── description: "Pembayaran sesi mentoring"
            ├── timestamp: 1234567890
            └── booking_id: "xxx" (optional)
```

## 📱 Fitur yang Tersedia

### 1. **Dashboard Mentor** (`dashboard_mentor.dart`)
- ✅ Tampilan saldo saat ini (Total Penghasilan)
- ✅ Dana yang sedang diproses
- ✅ Tombol "Tarik Dana" dengan konfirmasi
- ✅ Tombol riwayat transaksi (icon history)
- ✅ Auto-reload balance dari Firebase
- ✅ Menu demo untuk testing

### 2. **Riwayat Transaksi** (`transaction_mentor.dart`)
- ✅ Tampilan semua transaksi (pemasukan & penarikan)
- ✅ Filter: Semua, Pemasukan, Penarikan
- ✅ Status transaksi dengan warna:
  - 🟢 Selesai (completed)
  - 🟠 Menunggu (pending)
  - 🔵 Diproses (processing)
  - 🔴 Gagal (failed)
- ✅ Total pemasukan & penarikan
- ✅ Pull to refresh
- ✅ Sorting berdasarkan timestamp (terbaru dulu)

### 3. **Transaction Helper** (`utils/transaction_helper.dart`)
Utility functions untuk mengelola transaksi:

```dart
// Tambah pemasukan mentor
await TransactionHelper.addEarning(
  mentorUid: 'uid-mentor',
  amount: 100000,
  description: 'Pembayaran sesi Matematika',
  bookingId: 'booking-123', // optional
);

// Ambil saldo mentor
double balance = await TransactionHelper.getMentorBalance('uid-mentor');

// Update status transaksi (untuk admin)
await TransactionHelper.updateTransactionStatus(
  mentorUid: 'uid-mentor',
  transactionId: 'trans-123',
  status: 'completed',
);
```

### 4. **Demo Tambah Pemasukan** (`demo_add_earning.dart`)
- ✅ Simulasi pembayaran dari pelajar
- ✅ Input jumlah dan deskripsi
- ✅ Otomatis update saldo mentor
- ✅ Catat transaksi di history

## 🔄 Alur Transaksi

### Alur Pemasukan (Earning)
1. Pelajar membayar untuk sesi mentoring
2. System memanggil `TransactionHelper.addEarning()`
3. Transaksi dicatat dengan status "completed"
4. Balance mentor otomatis bertambah
5. Mentor bisa lihat di dashboard & riwayat

### Alur Penarikan (Withdrawal)
1. Mentor klik tombol "Tarik Dana"
2. Dialog konfirmasi muncul
3. Setelah konfirmasi:
   - Transaksi dicatat dengan status "processing"
   - Balance mentor menjadi 0
   - Dana dipindah ke "dana_proses"
4. Admin memproses penarikan
5. Admin update status menjadi "completed"
6. Dana dikirim ke rekening mentor (1-3 hari kerja)

## 📊 Implementasi di Aplikasi

### Integrasi dengan Booking System

Ketika pelajar membayar untuk booking:

```dart
// Di file booking/payment handler
await TransactionHelper.addEarning(
  mentorUid: booking['mentor_uid'],
  amount: booking['price'],
  description: 'Pembayaran ${booking['subject']} - ${booking['date']}',
  bookingId: booking['id'],
);
```

### Real-time Update Balance

Dashboard mentor auto-reload balance dari Firebase:

```dart
Future<void> _loadMentorBalance() async {
  final snapshot = await _database
      .child('mentors')
      .child(currentMentorData['uid'])
      .child('balance')
      .get();

  if (snapshot.exists) {
    setState(() {
      currentMentorData['total_penghasilan'] = snapshot.value.toString();
    });
  }
}
```

## 🧪 Testing

1. **Login sebagai mentor**
2. **Buka menu (⋮) di dashboard**
3. **Pilih "Demo Tambah Pemasukan"**
4. **Masukkan jumlah (contoh: 100000)**
5. **Klik "Tambah Pemasukan"**
6. **Cek saldo di dashboard (akan bertambah)**
7. **Klik icon history untuk melihat transaksi**
8. **Test "Tarik Dana" untuk simulasi withdrawal**

## 💡 Fitur Masa Depan

- [ ] Admin panel untuk approve/reject withdrawals
- [ ] Notifikasi push saat ada pemasukan
- [ ] Export transaksi ke PDF/Excel
- [ ] Grafik penghasilan bulanan
- [ ] Withdrawal ke multiple bank accounts
- [ ] Minimum withdrawal amount validation
- [ ] Fee calculation for withdrawals
- [ ] Tax calculation and reporting

## 🔒 Security Rules Firebase

Pastikan Firebase Realtime Database rules sudah di-set:

```json
{
  "rules": {
    "mentors": {
      "$uid": {
        ".read": "$uid === auth.uid || root.child('admins').child(auth.uid).exists()",
        ".write": "$uid === auth.uid || root.child('admins').child(auth.uid).exists()"
      }
    },
    "transactions": {
      "$uid": {
        ".read": "$uid === auth.uid || root.child('admins').child(auth.uid).exists()",
        ".write": "$uid === auth.uid || root.child('admins').child(auth.uid).exists()"
      }
    }
  }
}
```

## 📞 Support

Jika ada masalah dengan sistem transaksi, hubungi tim development.
