# 🔐 Konfigurasi Admin Dashboard

## Langkah-langkah Setup Admin

### 1. Edit Whitelist Email (WAJIB!)

Buka file: `web/admin.html`

Cari baris ini (sekitar baris 560-565):

```javascript
// ⚠️ WHITELIST EMAIL ADMIN - Hanya email ini yang bisa akses dashboard
const ADMIN_EMAILS = [
    'admin@mentorly.com',
    'admin@gmail.com',
    // Tambahkan email admin lainnya di sini
];
```

**Ganti dengan email Anda sendiri:**

```javascript
const ADMIN_EMAILS = [
    'yourname@gmail.com',           // Email admin utama
    'admin@yourdomain.com',         // Email admin kedua (opsional)
    'superadmin@example.com',       // Tambahkan sebanyak yang dibutuhkan
];
```

### 2. Buat User di Firebase Authentication

1. Buka: https://console.firebase.google.com
2. Pilih project: **mentorly-66d07**
3. Klik menu **Authentication** di kiri
4. Tab **Users**, klik **Add user**
5. Isi formulir:
   - **Email:** `yourname@gmail.com` (HARUS sama dengan whitelist!)
   - **Password:** Buat password yang kuat
6. Klik **Add user**

### 3. Test Login

1. Jalankan dashboard (Live Server atau Flutter web)
2. Login dengan email dan password yang baru dibuat
3. Jika berhasil → Anda akan masuk ke dashboard
4. Jika gagal → Check apakah email sudah ditambahkan ke whitelist

## ⚠️ Penting!

### Email HARUS Sama Persis

❌ **SALAH:**
- Whitelist: `admin@gmail.com`
- Firebase: `Admin@gmail.com` (huruf besar)

✅ **BENAR:**
- Whitelist: `admin@gmail.com`
- Firebase: `admin@gmail.com` (sama persis)

### Proteksi Otomatis

Jika seseorang mencoba login dengan akun yang tidak ada di whitelist:
1. Login akan berhasil sejenak
2. Sistem akan cek email vs whitelist
3. Jika tidak match → **otomatis logout**
4. Error ditampilkan: "⛔ Akses ditolak! Akun ini tidak memiliki izin admin."

## 🔒 Keamanan

### Layer 1: Whitelist Email
- Hanya email tertentu yang bisa akses
- Dikontrol lewat array `ADMIN_EMAILS`
- Edit whitelist = edit `admin.html`

### Layer 2: Firebase Authentication  
- Password protection
- Managed oleh Firebase
- Reset password via Firebase Console

### Layer 3: Database Rules
- Proteksi data di level database
- Set di Firebase Console → Realtime Database → Rules

## 📝 Contoh Multiple Admin

```javascript
const ADMIN_EMAILS = [
    // Admin utama
    'owner@mentorly.com',
    
    // Admin IT
    'it@mentorly.com',
    'developer@mentorly.com',
    
    // Admin operasional
    'operations@mentorly.com',
    
    // Emergency access
    'emergency@mentorly.com',
];
```

## 🔄 Cara Menghapus Admin

### Hapus dari Whitelist
Edit `web/admin.html`, hapus email dari array `ADMIN_EMAILS`

### Hapus dari Firebase (Opsional)
1. Firebase Console → Authentication
2. Cari user yang mau dihapus
3. Klik ⋮ (titik tiga) → Delete user

## 🆘 Troubleshooting

### Problem: "Akses ditolak" setelah login
**Solusi:** 
- Email belum ada di whitelist
- Tambahkan email ke `ADMIN_EMAILS` di `admin.html`

### Problem: "User not found"
**Solusi:**
- User belum dibuat di Firebase Authentication
- Buat user baru dengan email yang sama dengan whitelist

### Problem: "Wrong password"
**Solusi:**
- Password salah
- Reset password di Firebase Console → Authentication

### Problem: Dashboard blank setelah login
**Solusi:**
- Check Console browser (F12) untuk error
- Pastikan Firebase config sudah benar
- Check Firebase Database rules

## 📞 Need Help?

Jika masih ada masalah:
1. Check Console browser (F12) untuk error detail
2. Pastikan semua langkah sudah diikuti dengan benar
3. Verify email whitelist vs Firebase email (case sensitive!)

---

✅ Setelah setup selesai, dashboard Anda aman dan hanya bisa diakses oleh admin yang terdaftar!
