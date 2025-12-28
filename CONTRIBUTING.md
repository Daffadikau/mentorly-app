# Contributing to Mentorly

Thank you for contributing to Mentorly! Please follow these guidelines to ensure smooth collaboration.

## Code of Conduct

- Be respectful and professional
- Help others learn and grow
- Report issues constructively
- Celebrate wins together

## How to Contribute

### 1. Report Issues

Create an issue with:
- **Clear title** describing the problem
- **Description** of what happened
- **Steps to reproduce** (if applicable)
- **Expected vs actual behavior**
- **Screenshots** (if relevant)

### 2. Propose Features

Create an issue with:
- **Feature description**
- **Why it's needed**
- **Proposed implementation** (optional)
- **Alternative solutions** considered

### 3. Submit Code Changes

#### Step 1: Fork & Clone
```bash
git clone <repository-url>
cd Mentorly
```

#### Step 2: Create Feature Branch
```bash
git checkout -b feature/add-login-validation
```

#### Step 3: Make Changes
- Write clean, readable code
- Follow Dart/Flutter style guide
- Add comments for complex logic
- Test your changes locally

#### Step 4: Commit Changes
```bash
git add .
git commit -m "feat: add email validation to login"
```

#### Step 5: Push & Create PR
```bash
git push origin feature/add-login-validation
```

Go to GitHub/GitLab and create a Pull Request.

## Code Style Guidelines

### Dart/Flutter

1. **Naming Conventions**:
   - Classes: `PascalCase` (e.g., `LoginPage`)
   - Functions/variables: `camelCase` (e.g., `validateEmail()`)
   - Constants: `CONSTANT_CASE` (e.g., `MAX_ATTEMPTS`)
   - Files: `snake_case` (e.g., `login_page.dart`)

2. **Comments**:
   ```dart
   /// This is a documentation comment
   /// Used for public APIs
   
   // This is a single line comment
   
   /* This is a block comment
     For longer explanations */
   ```

3. **Formatting**:
   ```bash
   # Format all files
   flutter format .
   
   # Check analysis
   flutter analyze
   ```

4. **Code Example**:
   ```dart
   import 'package:flutter/material.dart';
   
   // Keep imports organized: dart, packages, relative
   import 'session_manager.dart';
   
   class LoginPage extends StatefulWidget {
     const LoginPage({super.key});
   
     @override
     State<LoginPage> createState() => _LoginPageState();
   }
   
   class _LoginPageState extends State<LoginPage> {
     final TextEditingController _emailController = TextEditingController();
     
     /// Validates email format
     bool _isValidEmail(String email) {
       return email.contains('@') && email.contains('.');
     }
     
     @override
     Widget build(BuildContext context) {
       return Scaffold(
         appBar: AppBar(title: const Text('Login')),
         body: Center(
           child: Text('Hello'),
         ),
       );
     }
     
     @override
     void dispose() {
       _emailController.dispose();
       super.dispose();
     }
   }
   ```

## Pull Request Process

1. **Update your branch**:
   ```bash
   git pull origin main
   ```

2. **Test thoroughly**:
   ```bash
   flutter clean
   flutter pub get
   flutter analyze
   flutter run
   ```

3. **Create descriptive PR**:
   - Clear title
   - Description of changes
   - Link related issues
   - Add screenshots (if UI changes)

4. **Address feedback**:
   - Respond to reviewer comments
   - Make requested changes
   - Update PR with new commits

5. **Merge**:
   - Ensure all checks pass
   - Get approval from at least one reviewer
   - Merge to main branch

## File Structure

When adding new features:

```
lib/
├── screens/          # Page/screen widgets
├── widgets/          # Reusable widgets
├── services/         # Firebase, API calls
├── models/           # Data models
├── utils/            # Utility functions
└── constants/        # App constants
```

### Example: Adding a New Feature

```
lib/
├── screens/
│   └── new_feature_page.dart
├── widgets/
│   └── new_feature_widget.dart
├── services/
│   └── new_feature_service.dart
└── models/
    └── new_feature_model.dart
```

## Testing

```bash
# Run tests
flutter test

# Run specific test
flutter test test/models/user_test.dart

# Test coverage
flutter test --coverage
```

## Database Changes

If you modify Firebase structure:

1. **Document the change** in this file
2. **Create migration notes** if needed
3. **Update SETUP_GUIDE.md** if structure changed
4. **Test with all user types**

## Deployment Checklist

Before merging to main:

- [ ] All tests pass
- [ ] No console errors/warnings
- [ ] Code formatted (`flutter format .`)
- [ ] No unused imports
- [ ] Firebase rules allow changes
- [ ] UI responsive on different screens
- [ ] Performance tested
- [ ] Documentation updated

## Communication

- **Questions?** Ask in team chat
- **Found a bug?** Create an issue
- **Have an idea?** Discuss in PRs
- **Stuck?** Reach out for help

## Branch Protection Rules

- `main` branch is protected
- Requires pull request reviews
- All checks must pass
- Linear history preferred

## Commit Message Template

```
<type>: <subject>

<body>

Fixes #<issue-number>
```

### Types:
- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation
- `style` - Code style
- `refactor` - Code refactoring
- `perf` - Performance improvement
- `test` - Adding tests
- `chore` - Build/dependency updates

### Example:
```
feat: add email verification for signup

Add email validation and verification step to signup flow.
- Check email format
- Send verification email
- Verify token before creating account

Fixes #42
```

## Performance Considerations

- Minimize widget rebuilds
- Lazy load data
- Cache API responses
- Optimize images
- Use const constructors
- Profile with DevTools

## Security

- Never commit sensitive keys
- Use environment variables
- Validate user input
- Hash passwords
- Check Firebase security rules
- Report vulnerabilities privately

---

**Thank you for helping make Mentorly better!** 🎉
