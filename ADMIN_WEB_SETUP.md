# 🔐 Admin Dashboard Web - Setup Guide

## 📋 Overview

Admin dashboard untuk Mentorly yang di-hosting menggunakan Firebase Hosting. Menggunakan Firebase Realtime Database node `admin` untuk autentikasi yang aman.

## 🏗️ Struktur Node Admin di Firebase

```
admin/
  └── {uid}/
      ├── uid: "user-uid"
      ├── email: "admin@mentorly.com"
      ├── nama: "Nama Admin"
      ├── role: "admin" | "super_admin"
      ├── created_at: "2026-01-08T10:00:00Z"
      └── created_by: "creator-uid"
```

## 🚀 Setup & Deploy

### 1. Persiapan File

Copy file admin ke folder build/web:

```bash
# Di root project Mentorly
cp web/admin.html build/web/
cp web/admin_register.html build/web/
```

### 2. Deploy ke Firebase Hosting

```bash
# Login ke Firebase (jika belum)
firebase login

# Deploy
firebase deploy --only hosting

# Atau deploy semua (hosting, database rules, storage rules)
firebase deploy
```

### 3. Update Database Rules

Database rules sudah diupdate otomatis di `database.rules.json`. Deploy dengan:

```bash
firebase deploy --only database
```

## 📝 Cara Menggunakan

### Registrasi Admin Pertama

1. Buka halaman registrasi admin:
   - Local: `file:///path/to/web/admin_register.html`
   - Hosting: `https://mentorly-66d07.web.app/admin-register`

2. Isi form registrasi:
   - Email admin
   - Password (minimal 6 karakter)
   - Nama lengkap
   - Role (Admin atau Super Admin)

3. Klik "Daftarkan Admin"

4. Admin berhasil terdaftar dan data tersimpan di node `admin` di Firebase

### Login ke Dashboard

1. Buka dashboard admin:
   - Local: `file:///path/to/web/admin.html`
   - Hosting: `https://mentorly-66d07.web.app/admin`

2. Login menggunakan email dan password yang sudah didaftarkan

3. Sistem akan memverifikasi apakah akun terdaftar di node `admin`

4. Jika valid, dashboard akan terbuka

## 🔒 Keamanan

### Database Rules

Node `admin` dilindungi dengan rules:

```json
"admin": {
  ".read": "auth != null",
  "$uid": {
    ".read": "auth != null",
    ".write": "root.child('admin').child(auth.uid).exists()"
  }
}
```

- **Read**: Hanya user yang sudah login yang bisa membaca data admin
- **Write**: Hanya admin yang sudah terdaftar yang bisa menulis/update data admin

### Autentikasi di Web

1. User login dengan Firebase Authentication
2. Sistem check apakah `uid` ada di node `admin`
3. Jika tidak ada, user di-logout otomatis
4. Jika ada dan role = `admin`, akses diberikan

## ✨ Fitur Dashboard Admin

### 1. Dashboard Statistik
- Total mentor pending verification
- Total mentor verified
- Total pelajar terdaftar

### 2. Manajemen Mentor
- **Pending Tab**: Approve/Reject mentor baru
- **Verified Tab**: Lihat mentor verified, bisa revoke
- Detail lengkap mentor termasuk daftar kelas

### 3. Manajemen Pelajar
- Lihat daftar semua pelajar terdaftar
- Informasi lengkap pelajar

### 4. Actions
- ✅ Approve mentor
- ❌ Reject mentor
- 🚫 Revoke verification mentor
- 👁️ Lihat detail lengkap

## 🌐 URL Access

Setelah deploy, admin dashboard bisa diakses di:

- **Dashboard**: `https://mentorly-66d07.web.app/admin`
- **Registrasi**: `https://mentorly-66d07.web.app/admin-register`

## 📱 Responsive Design

Dashboard sudah responsive dan bisa diakses dari:
- 💻 Desktop
- 📱 Mobile
- 🖥️ Tablet

## 🔧 Troubleshooting

### Admin tidak bisa login

1. Cek apakah uid ada di Firebase Database node `admin`
2. Cek apakah role = `admin` atau `super_admin`
3. Pastikan database rules sudah di-deploy
4. Clear browser cache

### Deploy gagal

```bash
# Check Firebase project
firebase projects:list

# Use correct project
firebase use mentorly-66d07

# Deploy lagi
firebase deploy --only hosting
```

### Database rules error

```bash
# Deploy database rules
firebase deploy --only database

# Check rules di Firebase Console
# Database > Rules
```

## 🔄 Update Files

Jika ada perubahan di admin.html atau admin_register.html:

```bash
# 1. Update file di folder web/
# 2. Copy ke build/web
cp web/admin.html build/web/
cp web/admin_register.html build/web/

# 3. Deploy
firebase deploy --only hosting
```

## 📞 Support

Jika ada masalah, check:
1. Firebase Console
2. Browser Developer Tools (Console)
3. Network tab untuk error
4. Database rules di Firebase Console

---

**Built with ❤️ using Firebase**
