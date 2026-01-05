# 🚀 Quick Start - Admin Dashboard

## Cara Akses Dashboard Admin

### 1. Jalankan dengan Live Server (Paling Mudah)

1. Buka VS Code
2. Klik kanan pada file `web/admin.html`
3. Pilih **"Open with Live Server"**
4. Dashboard akan terbuka di browser

**URL Lokal:** `http://localhost:5500/web/admin.html`

### 2. Atau Jalankan Flutter Web

```bash
flutter run -d chrome --web-renderer html
```

Kemudian akses: `http://localhost:XXXX/admin.html`

### 3. Login ke Dashboard

**Email Admin:** (buat di Firebase Console → Authentication)
**Password:** (password yang Anda set)

## 🔐 Membuat Admin Account

### Step 1: Tambahkan Email ke Whitelist

Buka file `web/admin.html` dan cari bagian ini:

```javascript
// ⚠️ WHITELIST EMAIL ADMIN - Hanya email ini yang bisa akses dashboard
const ADMIN_EMAILS = [
    'admin@mentorly.com',
    'admin@gmail.com',
    // Tambahkan email admin lainnya di sini
];
```

**Tambahkan email admin Anda ke array ini!**

### Step 2: Buat User di Firebase

1. Buka [Firebase Console](https://console.firebase.google.com)
2. Pilih project **mentorly-66d07**
3. Klik **Authentication** di menu kiri
4. Klik **Add user**
5. Masukkan email yang **SAMA** dengan yang ada di whitelist
6. Set password untuk admin
7. Gunakan credentials ini untuk login

**⚠️ PENTING:** Email yang dibuat di Firebase **HARUS** ada di whitelist, jika tidak akses akan ditolak!

## ✅ Yang Sudah Dikonfigurasi

- ✅ Firebase configuration sudah dimasukkan
- ✅ Koneksi ke Realtime Database: `mentorly-66d07`
- ✅ Semua fitur CRUD mentor dan pelajar
- ✅ Approve/Reject mentor
- ✅ Real-time statistics
- ✅ **Whitelist email admin** - Hanya email tertentu yang bisa akses
- ✅ **Proteksi akses** - User lain tidak bisa login meskipun punya akun Firebase

## 📱 Perubahan di Aplikasi Mobile

Tombol **"Admin"** sudah dihilangkan dari aplikasi mobile. 
Admin hanya bisa akses lewat web dashboard.

## 🎯 Fitur Dashboard

- 📊 Statistik real-time (Pending, Verified, Pelajar)
- ✅ Approve mentor pending
- ❌ Reject mentor
- 🔄 Revoke verified mentor
- 👁️ View detail lengkap
- 🔐 Secure login dengan Firebase Auth

## 🆘 Troubleshooting

**Dashboard tidak bisa dibuka?**
- Install extension "Live Server" di VS Code
- Atau gunakan `flutter run -d chrome`

**Tidak bisa login / Akses ditolak?**
- Pastikan email Anda ada di **whitelist** (`ADMIN_EMAILS` di admin.html)
- Buka `web/admin.html`, tambahkan email Anda ke array `ADMIN_EMAILS`
- Email di Firebase harus sama persis dengan yang di whitelist
- Check Console browser untuk error message

**Data tidak muncul?**
- Check Firebase Realtime Database rules
- Pastikan ada data di Firebase Console
- Lihat console browser untuk error

---

📚 Untuk dokumentasi lengkap, baca: **ADMIN_DASHBOARD_WEB.md**
