# Web Admin Dashboard

Dashboard admin untuk mengelola Mentorly App.

## 📁 File-file Penting

- **`admin.html`** - Dashboard admin utama (login di sini)
- **`index_admin.html`** - Landing page portal admin

## 🚀 Quick Start

### 1. Tambahkan Email Anda ke Whitelist

Edit file `admin.html`, cari baris ini dan tambahkan email Anda:

```javascript
const ADMIN_EMAILS = [
    'admin@mentorly.com',
    'your-email@gmail.com',  // ← Tambahkan email Anda di sini
];
```

### 2. Buat User di Firebase

- Buka [Firebase Console](https://console.firebase.google.com)
- Authentication → Add user
- Gunakan **email yang sama** dengan whitelist

### 3. Jalankan Dashboard

**Dengan Live Server:**
```
Klik kanan admin.html → Open with Live Server
```

**Dengan Flutter:**
```bash
flutter run -d chrome
```

Kemudian akses: `http://localhost:PORT/admin.html`

## 📚 Dokumentasi Lengkap

Lihat file-file berikut untuk informasi detail:

- **`ADMIN_SETUP_GUIDE.md`** - Panduan setup detail
- **`ADMIN_QUICK_START.md`** - Quick reference
- **`ADMIN_DASHBOARD_WEB.md`** - Dokumentasi lengkap

## 🔐 Keamanan

✅ Whitelist email - Hanya email tertentu yang bisa akses
✅ Firebase Authentication - Password protection
✅ Database rules - Proteksi data

**PENTING:** Edit whitelist di `admin.html` sebelum digunakan!
