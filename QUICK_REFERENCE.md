# Mentorly - Quick Reference for Developers

## 🚀 Getting Started in 5 Minutes

### 1. Clone & Setup
```bash
git clone <repository-url>
cd Mentorly
flutter pub get
```

### 2. Run
```bash
flutter run
```

### 3. Make Changes & Commit
```bash
git checkout -b feature/your-feature
# ... make changes ...
git add .
git commit -m "feat: describe your change"
git push origin feature/your-feature
```

---

## 📁 File Locations

| Feature | Files |
|---------|-------|
| Student Registration | `lib/register_pelajar.dart` |
| Student Login | `lib/login_pelajar.dart` |
| Student Dashboard | `lib/dashboard_pelajar.dart` |
| Student Profile | `lib/profile_pelajar.dart` |
| Mentor Registration | `lib/register_mentor.dart` |
| Mentor Login | `lib/login_mentor.dart` |
| Mentor Dashboard | `lib/dashboard_mentor.dart` |
| Mentor Schedule | `lib/tambah_jadwal_mentor.dart` |
| Chat System | `lib/chat_detail.dart` |
| Admin Login | `lib/login_admin.dart` |
| Admin Dashboard | `lib/dashboard_admin.dart` |
| Session Management | `lib/session_manager.dart` |

---

## 🔥 Firebase Nodes

**Read/Write Data Example:**

```dart
import 'package:firebase_database/firebase_database.dart';

// Write data
final ref = FirebaseDatabase.instance.ref('pelajar');
final newRef = ref.push();
await newRef.set({
  'email': 'student@example.com',
  'phone': '628123456789',
  'created_at': DateTime.now().toIso8601String(),
});

// Read data
final snapshot = await ref.get();
if (snapshot.exists) {
  print(snapshot.value);
}

// Query data
final query = ref.orderByChild('email').equalTo('student@example.com');
final result = await query.get();
```

---

## 🔧 Common Commands

```bash
# Run app
flutter run

# Clean build
flutter clean
flutter pub get
flutter run

# Check code
flutter analyze

# Format code
flutter format .

# Test
flutter test

# Build APK
flutter build apk

# Build IOS
flutter build ios

# Git commands
git status           # Check status
git pull             # Get latest
git add .            # Stage changes
git commit -m "msg"  # Commit
git push             # Push to remote
```

---

## 📋 Commit Message Examples

```
feat: add password validation to login
fix: resolve Firebase timeout issue
docs: update README with setup steps
style: format chat_detail.dart
refactor: extract Firebase queries to service
perf: optimize message loading
test: add session manager tests
```

---

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| Build fails | `flutter clean && flutter pub get && flutter run` |
| Firebase not connecting | Check internet, verify Firebase active |
| Dependency issues | `flutter pub upgrade` |
| Port already in use | `flutter run -d <device-id>` |
| Widget not updating | Use `setState()` or consider `Provider` |

---

## 🎯 Before Pushing Code

- [ ] Code runs without errors
- [ ] No console warnings
- [ ] Code is formatted (`flutter format .`)
- [ ] No unused imports
- [ ] Tested on device/emulator
- [ ] Pull request has clear description

---

## 👥 Team Communication

- **Questions?** Ask in chat
- **Bug Found?** Create issue
- **Idea?** Discuss in PR
- **Help Needed?** Mention team member

---

## 🔐 Security Reminders

- ❌ Never commit API keys
- ❌ Never commit passwords
- ✅ Use environment variables
- ✅ Validate user input
- ✅ Check Firebase rules

---

## 📚 Resources

- [Flutter Docs](https://flutter.dev)
- [Firebase Docs](https://firebase.google.com/docs)
- [Dart Guide](https://dart.dev/guides)
- See `SETUP_GUIDE.md` for detailed setup
- See `CONTRIBUTING.md` for standards

---

**Happy coding! 🚀**

Last Updated: 2024-12-28
