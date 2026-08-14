# 🎓 Mentorly

A **mentoring marketplace app** built with Flutter + Firebase — students find and book mentors,
learn in 1-on-1 sessions, and pay in-app; mentors manage schedules and classes; admins oversee
the platform from a web dashboard.

## ✨ Features

**For students**
- Browse, search & filter mentors by expertise; view profiles, ratings, and class offerings
- Book sessions against real mentor availability (classes, dates, time slots)
- In-app **chat** and **video calls** with mentors
- Transactions & payment flow, session history, reviews

**For mentors**
- Manage profile, expertise, classes, and schedule availability
- Accept bookings, chat with students, run video sessions

**Platform**
- Email/password auth with **phone verification (SMS 2FA)**
- File & image upload, profile photos
- **Admin web dashboard** for managing users, mentors, and transactions

## 🛠️ Tech Stack

Flutter (Dart) · Firebase Auth / Firestore / Storage · Cloud messaging & SMS 2FA

## 🚀 Getting Started

```bash
flutter pub get
cp .env.example .env   # fill in your Firebase / service keys
flutter run
```

Detailed setup, architecture notes, and feature docs live in the repo's `*.md` guides —
start with [`SETUP_GUIDE.md`](SETUP_GUIDE.md) and [`QUICK_REFERENCE.md`](QUICK_REFERENCE.md).
