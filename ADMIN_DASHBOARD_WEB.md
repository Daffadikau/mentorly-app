# Dashboard Admin Web - Mentorly

Dashboard admin sekarang telah dipindahkan ke web untuk akses yang lebih aman dan terpisah dari aplikasi mobile.

## 📍 Lokasi File

File dashboard admin web berada di: `/web/admin.html`

## 🚀 Cara Menggunakan

### 1. Konfigurasi Firebase

Sebelum menggunakan, Anda harus mengganti konfigurasi Firebase di file `admin.html`:

```javascript
const firebaseConfig = {
    apiKey: "YOUR_API_KEY",
    authDomain: "YOUR_PROJECT_ID.firebaseapp.com",
    databaseURL: "https://YOUR_PROJECT_ID-default-rtdb.firebaseio.com",
    projectId: "YOUR_PROJECT_ID",
    storageBucket: "YOUR_PROJECT_ID.appspot.com",
    messagingSenderId: "YOUR_SENDER_ID",
    appId: "YOUR_APP_ID"
};
```

Ganti semua nilai `YOUR_*` dengan konfigurasi Firebase Anda yang bisa didapatkan dari Firebase Console.

### 2. Menjalankan Dashboard

Ada beberapa cara untuk menjalankan dashboard admin:

#### Opsi 1: Lokal dengan Live Server (Rekomendasi untuk Development)

1. Install extension "Live Server" di VS Code
2. Klik kanan pada file `web/admin.html`
3. Pilih "Open with Live Server"
4. Dashboard akan terbuka di browser di `http://localhost:5500/web/admin.html`

#### Opsi 2: Deploy ke Firebase Hosting

1. Install Firebase CLI:
   ```bash
   npm install -g firebase-tools
   ```

2. Login ke Firebase:
   ```bash
   firebase login
   ```

3. Initialize Firebase Hosting (jika belum):
   ```bash
   firebase init hosting
   ```
   - Pilih direktori `web` sebagai public directory
   - Pilih "No" untuk single-page app
   - Jangan overwrite file yang sudah ada

4. Deploy:
   ```bash
   firebase deploy --only hosting
   ```

5. Akses dashboard di URL yang diberikan (biasanya `https://your-project-id.web.app/admin.html`)

#### Opsi 3: Upload ke Web Hosting Lain

Upload file `admin.html` ke hosting web pilihan Anda (seperti Netlify, Vercel, atau hosting lainnya).

### 3. Login ke Dashboard

1. Buka `admin.html` di browser
2. Login menggunakan email dan password admin yang terdaftar di Firebase Authentication
3. Anda akan melihat dashboard dengan statistik dan daftar mentor

## 🔐 Keamanan

### Sistem Whitelist Email Admin

Dashboard menggunakan sistem **whitelist email** untuk keamanan maksimal. Hanya email yang terdaftar di whitelist yang bisa mengakses dashboard.

#### Cara Menambahkan Admin Baru:

1. **Edit Whitelist** di `web/admin.html`:
```javascript
// ⚠️ WHITELIST EMAIL ADMIN - Hanya email ini yang bisa akses dashboard
const ADMIN_EMAILS = [
    'admin@mentorly.com',
    'admin@gmail.com',
    'your-email@example.com',  // Tambahkan email baru di sini
    // Tambahkan email admin lainnya di sini
];
```

2. **Buat User di Firebase Authentication**:
   - Buka Firebase Console → Authentication
   - Klik "Add user"
   - Masukkan email yang **sama persis** dengan yang ada di whitelist
   - Set password
   - Save

3. **Test Login**:
   - Buka dashboard admin
   - Login dengan email dan password yang baru dibuat
   - Jika email tidak di whitelist, akan otomatis logout dengan pesan error

### Keamanan Berlapis

Dashboard memiliki 3 layer keamanan:

1. ✅ **Whitelist Email** - Hanya email tertentu yang bisa akses
2. ✅ **Firebase Authentication** - Password protection
3. ✅ **Firebase Database Rules** - Proteksi data level database

### Membuat Admin Account

1. Buka Firebase Console → Authentication
2. Tambahkan user baru dengan email dan password
3. Gunakan credentials ini untuk login ke dashboard admin

### Mengamankan Akses

Untuk keamanan maksimal, disarankan untuk:

1. **Gunakan Firebase Security Rules** yang membatasi akses hanya untuk admin:

```json
{
  "rules": {
    "mentors": {
      ".read": "auth != null",
      ".write": "auth != null && auth.token.admin === true"
    },
    "pelajar": {
      ".read": "auth != null && auth.token.admin === true",
      ".write": "auth.uid === $uid || (auth != null && auth.token.admin === true)"
    }
  }
}
```

2. **Set Custom Claims untuk Admin** menggunakan Firebase Admin SDK atau Cloud Functions:

```javascript
// Contoh menggunakan Firebase Admin SDK
admin.auth().setCustomUserClaims(uid, { admin: true });
```

3. **Batasi akses ke file admin.html** menggunakan:
   - `.htaccess` jika menggunakan Apache
   - Nginx configuration jika menggunakan Nginx
   - Firebase Hosting rewrite rules

## ✨ Fitur Dashboard

### 1. Statistik
- Total Mentor Pending
- Total Mentor Verified
- Total Pelajar

### 2. Manajemen Mentor Pending
- Lihat daftar mentor yang menunggu verifikasi
- Approve mentor (mengubah status jadi 'verified')
- Reject mentor (mengubah status jadi 'rejected')
- Lihat detail lengkap mentor

### 3. Manajemen Mentor Verified
- Lihat daftar mentor yang sudah diverifikasi
- Revoke verifikasi (mengembalikan ke status 'pending')
- Lihat detail lengkap mentor

### 4. Lihat Daftar Pelajar
- Melihat semua pelajar yang terdaftar
- Informasi kontak dan detail pelajar

## 🔧 Fitur Firebase yang Digunakan

Dashboard ini menggunakan:
- ✅ Firebase Authentication - untuk login admin
- ✅ Firebase Realtime Database - untuk membaca dan update data
- ✅ Real-time updates - otomatis reload setelah update data

## 🚫 Perubahan di Aplikasi Mobile

Tombol "Admin" telah dihilangkan dari halaman welcome aplikasi mobile. Admin sekarang hanya bisa akses dashboard melalui web.

File yang diubah:
- `/lib/common/welcome_page.dart` - Menghapus button dan import admin

## 📝 Troubleshooting

### Dashboard tidak bisa login
- Pastikan konfigurasi Firebase sudah benar
- Pastikan email dan password admin sudah terdaftar di Firebase Authentication
- Cek console browser untuk error message

### Data tidak muncul
- Pastikan Firebase Realtime Database rules mengizinkan read access
- Cek apakah data sudah ada di Firebase Console
- Lihat console browser untuk error

### CORS Error
- Jika menjalankan lokal dengan file:// protocol, gunakan Live Server
- Atau deploy ke hosting yang proper

## 📞 Support

Jika ada masalah atau pertanyaan, silakan hubungi developer atau buat issue di repository.
