# 📋 Mentorly - Feature List untuk Use Case Diagram

## 👨‍🎓 FITUR PELAJAR (Student)

### Authentication & Registration
- ✅ Register Pelajar (Sign Up dengan email/password)
- ✅ Login Pelajar (Sign In)
- ✅ Phone Number Verification (verifikasi nomor telepon saat registrasi)
- ✅ Logout
- ✅ Edit Profile (update nama, email, no telepon, password)
- ✅ Upload Profile Photo

### Dashboard & Browsing
- ✅ View Dashboard (homepage dengan mentor recommendations)
- ✅ Browse Mentor List (daftar semua mentor tersedia)
- ✅ Search Mentor (cari mentor berdasarkan keahlian/nama)
- ✅ Filter Mentor by Category/Keahlian
- ✅ View Mentor Detail Page (lihat profil mentor lengkap, rating, keahlian)

### Jadwal & Booking
- ✅ View Mentor Jadwal (lihat jadwal available mentor)
- ✅ View Mentor Kelas (lihat daftar kelas yang ditawarkan mentor)
- ✅ Select Class & Date (pilih kelas dan tanggal untuk booking)
- ✅ View Available Time Slots (lihat slot waktu yang available)
- ✅ Book Session/Lesson (konfirmasi booking kelas)
- ✅ View Booking Confirmation (lihat detail booking yang sudah dikonfirmasi)
- ✅ Cancel Booking (batalkan booking yang belum dimulai)

### History & Reviews
- ✅ View Booking History (riwayat semua booking pelajar)
- ✅ View Booking Details (lihat detail salah satu booking)
- ✅ Submit Review & Rating (beri rating dan review ke mentor setelah sesi)
- ✅ View Completed Sessions (lihat sesi yang sudah selesai)
- ✅ View Pending Sessions (lihat sesi yang menunggu/ongoing)
- ✅ View Cancelled Sessions (lihat sesi yang dibatalkan)

### Communication
- ✅ Access Chat List (lihat daftar orang yang bisa dihubungi)
- ✅ Open Chat Room with Mentor (buka chat room dengan mentor)
- ✅ Send Message (kirim pesan ke mentor)
- ✅ Receive Message (terima pesan dari mentor)
- ✅ View Chat History (lihat history chat dengan mentor)

### Notifications
- ✅ Receive Session Reminder Notifications
- ✅ Receive Booking Confirmation Notification
- ✅ Receive Message Notifications
- ✅ Push Notifications (FCM)

### Payment (Implicit)
- ✅ Make Payment (via booking confirmation)
- ✅ View Payment Status
- ✅ View Transaction History

---

## 👨‍🏫 FITUR MENTOR (Instructor)

### Authentication & Registration
- ✅ Register Mentor (Sign Up dengan email/password)
- ✅ Login Mentor (Sign In)
- ✅ Logout
- ✅ Edit Profile (update nama, email, keahlian, deskripsi, harga)
- ✅ Upload Profile Photo
- ✅ Set Availability Status (active/inactive)

### Class Management
- ✅ Create Class (tambah kelas baru)
- ✅ Edit Class (ubah detail kelas: nama, deskripsi, level)
- ✅ Delete Class (hapus kelas)
- ✅ View Class List (lihat daftar kelas yang dibuat)
- ✅ Set Class Price (tentukan harga per jam)
- ✅ Add Class Description

### Jadwal Management
- ✅ Create One-Time Schedule (tambah jadwal sekali saja dengan tanggal spesifik)
- ✅ Create Weekly Schedule (tambah jadwal recurring mingguan, misal: setiap Kamis)
- ✅ View All Schedules (lihat semua jadwal yang dibuat)
- ✅ View Schedules by Date (lihat jadwal berdasarkan tanggal)
- ✅ Edit Schedule (ubah jadwal yang belum di-booking)
- ✅ Delete Schedule (hapus jadwal)
- ✅ View Schedule Status (available, booked, ongoing, finished)
- ✅ Set Time Range (jam mulai - jam selesai)

### Booking & Teaching
- ✅ View Dashboard with Stats (rating, penghasilan, upcoming sessions)
- ✅ View Upcoming Sessions (sesi mengajar yang akan datang)
- ✅ View Booked Sessions (jadwal yang sudah di-booking pelajar)
- ✅ View Student Name for Booked Schedule (lihat nama pelajar yang booking)
- ✅ View Booking Details
- ✅ Start Session (mulai mengajar)
- ✅ End Session (selesaikan sesi mengajar)
- ✅ Mark Session as Completed

### Teaching History
- ✅ View Teaching History (riwayat mengajar)
- ✅ View Student Feedback (lihat rating dan review dari pelajar)
- ✅ View Teaching Statistics (total jam mengajar, rata-rata rating)

### Earnings & Transactions
- ✅ View Total Earnings (total penghasilan)
- ✅ View Earnings per Session (penghasilan per sesi)
- ✅ View Transaction History (riwayat transaksi/penghasilan)
- ✅ View Payment Status per Booking

### Reviews & Ratings
- ✅ View Reviews Received (lihat review yang diterima dari pelajar)
- ✅ View Average Rating (rata-rata rating dari semua pelajar)
- ✅ Respond to Reviews

### Communication
- ✅ Access Chat List (lihat daftar pelajar yang bisa dihubungi)
- ✅ Open Chat Room with Student (buka chat room dengan pelajar)
- ✅ Send Message (kirim pesan ke pelajar)
- ✅ Receive Message (terima pesan dari pelajar)
- ✅ View Chat History

### Notifications
- ✅ Receive New Booking Notification
- ✅ Receive Session Reminder Notifications
- ✅ Receive Message Notifications
- ✅ Receive Review Notification

---

## 🔐 FITUR ADMIN (Administrator)

### Authentication
- ✅ Login Admin (hanya untuk email admin yang whitelist)
- ✅ Logout

### Dashboard & Statistics
- ✅ View Dashboard (homepage dengan statistik real-time)
- ✅ View Total Users Statistics (total pelajar, mentor, pending mentors)
- ✅ View Real-time User Count (jumlah user terbaru)
- ✅ View Statistics Charts/Graphs

### Mentor Verification Management
- ✅ View Mentor Pending List (daftar mentor yang menunggu verifikasi)
- ✅ View Mentor Detail (lihat profil lengkap mentor, verifikasi kualifikasi)
- ✅ Approve Mentor (verifikasi/approve mentor pending)
- ✅ Reject Mentor (tolak aplikasi mentor)
- ✅ View Mentor Rejection Reason

### Mentor Management
- ✅ View Verified Mentor List (daftar mentor yang sudah terverifikasi)
- ✅ View Mentor Profile Details
- ✅ Revoke Mentor Verification (cabut status verified kembali ke pending)
- ✅ View Mentor Statistics (rating, total penghasilan, jumlah student)
- ✅ View Mentor Reviews/Ratings

### Student Management
- ✅ View Student List (daftar semua pelajar terdaftar)
- ✅ View Student Details (profil lengkap pelajar)
- ✅ View Student Booking History
- ✅ View Student Contact Information

### Activity & Monitoring
- ✅ Monitor Active Sessions
- ✅ View Transaction Records
- ✅ View Booking Logs
- ✅ Access Firebase Database Directly (untuk troubleshooting)

### System Management
- ✅ Update User Status
- ✅ Manage User Roles
- ✅ View System Logs

---

## 🔄 CROSS-ROLE FEATURES (Shared Features)

### Authentication System
- ✅ Firebase Authentication (email/password)
- ✅ Session Management (track login status)
- ✅ Role-based Access Control

### Real-time Database
- ✅ Real-time Data Synchronization (Firebase Realtime DB)
- ✅ Real-time Notifications

### Chat System
- ✅ Chat Room Management (create/manage chat rooms)
- ✅ Message Persistence (simpan history chat)
- ✅ One-to-One Messaging

### Payment System
- ✅ Payment Processing
- ✅ Payment Verification
- ✅ Transaction Recording

### Notification System
- ✅ Push Notifications (Firebase Cloud Messaging)
- ✅ In-app Notifications
- ✅ Email Notifications (implicit)
- ✅ Session Reminders
- ✅ Booking Confirmations

### File Management
- ✅ Profile Photo Upload (Firebase Storage)
- ✅ Document Upload (certificates, etc.)

---

## 📊 USE CASE DIAGRAM STRUCTURE

### Primary Actors:
1. **Pelajar (Student)** - 25+ use cases
2. **Mentor (Instructor)** - 30+ use cases  
3. **Admin (Administrator)** - 15+ use cases

### System:
- **Mentorly Platform** - coordination of all features

### Key Dependencies:
- Pelajar → Mentor (booking, chat, review)
- Mentor → Admin (verification)
- Admin → Mentor & Pelajar (management)
- All → Firebase Backend (authentication, data, storage, messaging)

### Business Flows:
1. **Student Learning Flow**: Register → Browse → Book → Chat → Learn → Review
2. **Mentor Teaching Flow**: Register → Create Classes → Create Schedules → Wait for Bookings → Teach → Receive Payment → View Reviews
3. **Admin Moderation Flow**: Monitor → Verify Mentors → Manage Users → View Statistics

---

## 🔧 SUPPORTING SYSTEMS (Not Direct Use Cases)

- 🔐 Security System (encryption, Firebase Security Rules)
- 📱 Push Notification Service (FCM)
- 💳 Payment Gateway Integration
- 📧 Email Notification Service
- 📞 SMS 2FA (Two-Factor Authentication) - mentioned but not fully implemented
- 🎥 Video Call System (Agora SDK integrated)

---

## 📝 NOTES FOR USE CASE DIAGRAM

1. **Extend Relationships**: 
   - Book Session extends Payment Process
   - Submit Review extends View History

2. **Include Relationships**:
   - All authenticated actions include Session Management
   - All data updates include Real-time Sync

3. **Generalization**:
   - Pelajar dan Mentor keduanya extend User (shared auth, chat, notifications)

4. **Boundary**:
   - Mobile App (Flutter) & Web App (admin only)
   - Firebase Backend (invisible to users)

