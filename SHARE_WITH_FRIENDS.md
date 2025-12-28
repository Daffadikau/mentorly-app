# 🚀 How to Share Mentorly with Your Friends

This guide explains how to set up a shared repository so your friends can collaborate on the project.

---

## Option 1: GitHub (Recommended)

### Step 1: Create a GitHub Repository

1. Go to [github.com](https://github.com)
2. Click **New Repository**
3. Name it: `mentorly` (or your preferred name)
4. Choose visibility: **Public** (for team) or **Private** (for closed team)
5. Click **Create Repository**

### Step 2: Add Remote to Your Local Project

```bash
cd /Users/dikau/Downloads/MentorlyApp/Mentorly

# Add your GitHub repository as remote
git remote add origin https://github.com/YOUR-USERNAME/mentorly.git

# Set main branch as default
git branch -M main

# Push your code
git push -u origin main
```

### Step 3: Share Link with Friends

Share this link: `https://github.com/YOUR-USERNAME/mentorly`

### Step 4: Friends Clone the Repository

Each friend runs:
```bash
git clone https://github.com/YOUR-USERNAME/mentorly.git
cd mentorly
flutter pub get
flutter run
```

### Step 5: Add Friends as Collaborators (for Private Repo)

1. Go to repository settings
2. Click **Collaborators**
3. Add friends by username
4. They'll receive an invitation

---

## Option 2: GitLab

### Step 1: Create GitLab Repository

1. Go to [gitlab.com](https://gitlab.com)
2. Click **New Project**
3. Choose **Create blank project**
4. Fill in project name: `mentorly`
5. Click **Create Project**

### Step 2: Push Your Code

```bash
cd /Users/dikau/Downloads/MentorlyApp/Mentorly
git remote add origin https://gitlab.com/YOUR-USERNAME/mentorly.git
git branch -M main
git push -u origin main
```

### Step 3: Share & Invite

Share repository URL with friends, then invite them as members.

---

## Option 3: Local Network (For Learning)

If you want to collaborate without internet:

### Setup on Your Computer (Server)

```bash
# Create a bare repository
mkdir -p ~/mentorly.git
cd ~/mentorly.git
git init --bare

# Share this folder on your network
# (macOS: System Preferences > Sharing > File Sharing)
```

### Friends Clone From You

```bash
git clone file:///path/to/mentorly.git
```

---

## After Repository is Shared

### 1. Team Workflow

**Your friends should:**

```bash
# Clone the repository
git clone <repository-url>
cd mentorly

# Setup Flutter
flutter pub get

# Create a branch for their work
git checkout -b feature/their-feature-name

# Make changes
# ... edit files ...

# Commit changes
git add .
git commit -m "feat: describe the change"

# Push to repository
git push origin feature/their-feature-name

# Create a Pull Request on GitHub/GitLab
```

### 2. You Review Their Work

1. Go to the repository on GitHub/GitLab
2. Find their Pull Request
3. Review the code
4. Request changes or approve
5. Merge when ready

### 3. Keep Your Local Copy Updated

```bash
git pull origin main
```

---

## Repository Structure for Team

```
mentorly/
├── main              # Production branch (protected)
├── develop           # Development branch
├── feature/*         # Feature branches (temporary)
└── bugfix/*          # Bug fix branches (temporary)
```

### Branch Protection (GitHub)

To prevent accidental pushes to main:

1. Settings > Branches
2. Add rule for `main`
3. Check "Require pull request reviews"
4. Check "Require status checks to pass"

---

## Communication for Collaboration

### 1. Create Issues for Tasks

On GitHub/GitLab:
- Click **Issues**
- Click **New Issue**
- Describe the task
- Assign to team members

### 2. Use Labels/Tags

- `bug` - Problem to fix
- `feature` - New feature
- `documentation` - Docs update
- `help wanted` - Need assistance
- `in progress` - Currently working

### 3. Discussion in Pull Requests

- Comment on specific lines
- Suggest changes
- Ask questions
- Celebrate when merged

---

## Best Practices for Team

### 1. Regular Communication

```bash
# Before starting work
"I'm working on [feature] in branch [branch-name]"

# When creating PR
"I've implemented [feature], please review"

# When merging
"Merged [feature] to main"
```

### 2. Keep Branches Updated

```bash
git fetch origin
git rebase origin/main
git push origin --force-with-lease
```

### 3. Code Review Process

1. Team member creates PR
2. Another member reviews
3. Approve or request changes
4. Merge when approved

### 4. Merge Strategy

```bash
# Don't push directly to main
git push origin feature/something  # Push to feature branch

# Then create Pull Request on GitHub/GitLab
```

---

## Troubleshooting Collaboration

### Merge Conflicts

```bash
# When pulling and conflicts occur
git status          # See conflicts
# Edit the conflicted files
git add .
git commit -m "resolve: merge conflicts"
git push
```

### Accidentally Pushed to Main?

```bash
# Revert the commit
git revert <commit-hash>
git push origin main
```

### Friend's Branch is Outdated?

They should run:
```bash
git fetch origin
git rebase origin/main
git push origin --force-with-lease
```

---

## Adding Team Members as Maintainers

### GitHub

1. Go to repository
2. Settings > Collaborators & teams
3. Add user with appropriate role:
   - **Admin**: Full access
   - **Maintain**: Can manage without delete
   - **Write**: Can push and PR
   - **Triage**: Can manage issues and PRs
   - **Read**: View-only

---

## Useful Team Commands

```bash
# See all branches
git branch -a

# See recent commits from team
git log --oneline -10

# See who changed what
git blame lib/login_pelajar.dart

# See branches by last update
git branch -vv

# Create a release/version
git tag -a v1.0.0 -m "Version 1.0.0"
git push origin v1.0.0
```

---

## Documentation for Your Team

Make sure your friends know:

1. **Read first:**
   - `SETUP_GUIDE.md` - How to set up
   - `QUICK_REFERENCE.md` - Quick commands
   - `CONTRIBUTING.md` - Code standards

2. **Important:**
   - Firebase configuration (done ✓)
   - Database structure (documented ✓)
   - Coding style (see CONTRIBUTING.md)
   - Branch naming (feature/bugfix/etc)

3. **Never commit:**
   - API keys
   - Passwords
   - Personal tokens

---

## Sample Team Invitation Message

```
Hey everyone! 🎉

I'm sharing the Mentorly project so we can work together!

Repository: https://github.com/YOUR-USERNAME/mentorly

To get started:
1. Clone: git clone https://github.com/YOUR-USERNAME/mentorly.git
2. Setup: cd mentorly && flutter pub get
3. Run: flutter run

Read SETUP_GUIDE.md and QUICK_REFERENCE.md first!

Let's build something awesome together! 🚀
```

---

## Next Steps

1. Choose your platform (GitHub recommended)
2. Create the repository
3. Push your code
4. Share with friends
5. Invite them as collaborators
6. Start collaborating!

---

**Happy team coding! 🎊**
