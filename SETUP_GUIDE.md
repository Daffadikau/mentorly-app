# Mentorly - Team Development Setup Guide

Welcome to the Mentorly project! This guide will help you and your friends get started with collaborative development.

## 📋 Prerequisites

Before you start, make sure you have installed:

- **Flutter SDK** (3.0.0 or higher)
  - [Download Flutter](https://flutter.dev/docs/get-started/install)
  
- **Dart SDK** (included with Flutter)

- **Git** (for version control)
  - [Download Git](https://git-scm.com/)

- **Android Studio** or **Xcode** (for emulator/device testing)

- **Code Editor**
  - [VS Code](https://code.visualstudio.com/) (recommended)
  - [Android Studio](https://developer.android.com/studio)
  - [IntelliJ IDEA](https://www.jetbrains.com/idea/)

## 🚀 Quick Start for Team Members

### 1. Clone the Repository

```bash
git clone <repository-url>
cd Mentorly
```

### 2. Install Dependencies

```bash
flutter pub get
```

This will download all required packages (Firebase, HTTP, shared_preferences, etc.)

### 3. Run the App

#### On Android:
```bash
flutter run
```

#### On iOS:
```bash
flutter run -d ios
```

#### On Web (if enabled):
```bash
flutter run -d web
```

## 🔧 Project Structure

```
lib/
├── main.dart                      # App entry point
├── firebase_options.dart          # Firebase configuration (auto-generated)
├── session_manager.dart           # Session & authentication handling
├── register_pelajar.dart          # Student registration
├── register_mentor.dart           # Mentor registration
├── login_pelajar.dart             # Student login
├── login_mentor.dart              # Mentor login
├── login_admin.dart               # Admin login
├── dashboard_pelajar.dart         # Student dashboard
├── dashboard_mentor.dart          # Mentor dashboard
├── dashboard_admin.dart           # Admin dashboard
├── profile_pelajar.dart           # Student profile
├── profile_mentor.dart            # Mentor profile
├── chat_detail.dart               # Chat messaging
├── tambah_jadwal_mentor.dart      # Add mentor schedule
├── review_mentor.dart             # Mentor reviews
└── ... (other pages)

assets/
├── images/                        # All images and graphics

android/                           # Android native code
ios/                               # iOS native code
```

## 🔥 Firebase Integration

This project uses **Firebase Realtime Database** for backend operations:

- **Pelajar (Students)**: `pelajar/` node
- **Mentor**: `mentor/` node  
- **Admin**: `admin/` node
- **Messages**: `pesan/` node
- **Schedules**: `jadwal_mentor/` node

### Firebase Configuration

Firebase is already configured in `firebase_options.dart`. The project is connected to:
- **Project ID**: `mentorly-66d07`
- **Database URL**: `https://mentorly-66d07-default-rtdb.firebaseio.com`

## 👥 Collaboration Workflow

### 1. Create a Feature Branch

```bash
git checkout -b feature/your-feature-name
```

Branch naming convention:
- `feature/` - New features
- `bugfix/` - Bug fixes
- `enhancement/` - Improvements

### 2. Make Your Changes

Edit files, test locally:

```bash
flutter run
```

### 3. Commit Your Changes

```bash
git add .
git commit -m "feat: add your feature description"
```

Commit message conventions:
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation
- `style:` - Code formatting
- `refactor:` - Code refactoring
- `test:` - Adding tests

### 4. Push to Remote

```bash
git push origin feature/your-feature-name
```

### 5. Create a Pull Request

Push your branch and create a Pull Request (PR) on GitHub/GitLab for code review.

## 📱 Firebase Realtime Database Structure

### Pelajar (Student) Node
```json
{
  "pelajar": {
    "push_id_1": {
      "email": "student@example.com",
      "phone": "628123456789",
      "password": "hashed_password",
      "created_at": "2024-12-28T10:00:00.000Z"
    }
  }
}
```

### Mentor Node
```json
{
  "mentor": {
    "push_id_1": {
      "email": "mentor@example.com",
      "nama_lengkap": "Mentor Name",
      "keahlian": "IPA",
      "status_verifikasi": "pending|verified",
      "created_at": "2024-12-28T10:00:00.000Z"
    }
  }
}
```

### Messages Node
```json
{
  "pesan": {
    "push_id_1": {
      "pelajar_id": "student_id",
      "mentor_id": "mentor_id",
      "message": "Hello",
      "sender": "pelajar|mentor",
      "timestamp": "2024-12-28T10:00:00.000Z"
    }
  }
}
```

## ⚠️ Important Notes

1. **Password Security**: Currently passwords are stored as plain text in Firebase. For production, implement:
   - Password hashing (bcrypt or similar)
   - Firebase Authentication

2. **Environment Variables**: 
   - Firebase config is in `firebase_options.dart` (auto-generated)
   - Keep sensitive keys secure

3. **Testing**: Always test locally before pushing:
   ```bash
   flutter test
   flutter analyze
   ```

4. **Build Issues**: If you encounter build issues:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

## 🐛 Troubleshooting

### Firebase Connection Issues
- Check internet connection
- Verify Firebase project is active
- Check security rules in Firebase Console

### Build Errors
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

### Dependency Issues
```bash
# Update pub dependencies
flutter pub upgrade
```

## 📚 Useful Commands

```bash
# Run the app
flutter run

# Run on specific device
flutter run -d <device-id>

# Run in release mode
flutter run --release

# Build APK for Android
flutter build apk

# Build IPA for iOS
flutter build ios

# Build for web
flutter build web

# Analyze code
flutter analyze

# Format code
flutter format .

# Get new dependencies
flutter pub get

# Upgrade dependencies
flutter pub upgrade
```

## 🔐 Git Best Practices

1. **Pull before pushing**:
   ```bash
   git pull origin master
   ```

2. **Avoid conflicts**: Work on different features/branches

3. **Keep commits atomic**: One feature per commit

4. **Never push to main directly**: Always use pull requests

5. **Update regularly**:
   ```bash
   git fetch origin
   git rebase origin/main
   ```

## 📖 Documentation

- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Dart Documentation](https://dart.dev/guides)

## 🤝 Getting Help

- Ask in the team chat/Discord
- Check existing issues on the repository
- Review code comments in relevant files

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Happy coding!** 🚀
