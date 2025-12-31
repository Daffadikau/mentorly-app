# 🔑 PHP Backend Authentication Fix

## Problem Solved

Your mentor account (rhyno@email.com) exists in the **PHP MySQL database** but not in **Firebase Auth**, so Firebase login was failing with "email and password wrong".

## Solution Implemented

The login now uses a **hybrid authentication system**:

### Login Flow:
1. ✅ **Try Firebase Auth first** (for new mentors)
2. ⚠️ **If Firebase fails**, fallback to PHP database authentication  
3. ✅ **If PHP succeeds**, automatically create Firebase Auth account
4. ✅ **Sync data** between PHP and Firebase
5. ✅ **Allow login** regardless of which system authenticated

## Files Modified

### 1. `lib/mentor/login_mentor.dart`
- Added PHP authentication fallback
- Automatically creates Firebase account for PHP-authenticated users
- Better error handling with detailed messages
- Console logging for debugging

### 2. `PHP_BACKEND/login_mentor.php` (NEW)
- PHP endpoint for mentor authentication
- Verifies credentials against MySQL database
- Returns mentor data for syncing
- Handles multiple password hashing methods

## Setup Required

### Copy PHP File to Your Server

1. **Upload the file:**
   ```
   Copy: PHP_BACKEND/login_mentor.php
   To: /path/to/mentorly/login_mentor.php
   ```

2. **Update database credentials** in the file:
   ```php
   $host = 'localhost';      // Your MySQL host
   $dbname = 'mentorly';     // Your database name
   $username = 'root';       // Your MySQL username
   $password = '';           // Your MySQL password
   ```

3. **Verify table structure:**
   The script expects a `mentor` table with these columns:
   - `email` - Mentor email
   - `password` - Password (plain, MD5, SHA256, or bcrypt)
   - `status_verifikasi` or `status` or `verified` - Verification status
   - `nama_lengkap`, `nik`, `keahlian`, etc. - Profile data

## Testing Your Login

### 1. **Upload the PHP file** to your server

### 2. **Try logging in:**
   - Email: rhyno@email.com
   - Password: pass123

### 3. **Check console output:**
   You'll see messages like:
   - `⚠️ Firebase Auth failed (user-not-found), trying PHP backend...`
   - `✅ PHP authentication successful, creating Firebase account...`
   - `✅ Firebase Auth account created, verification email sent`
   - `✅ Mentor data synced from PHP backend to Firebase`

### 4. **What happens:**
   - First login: Uses PHP auth → Creates Firebase account → Sends verification email
   - Next login: Uses Firebase Auth directly (faster)

## Password Handling

The PHP script supports multiple password formats:
- ✅ Plain text (your current setup)
- ✅ MD5 hash
- ✅ SHA256 hash
- ✅ bcrypt (password_hash)

**IMPORTANT:** For production, you should hash passwords! But for now, plain text will work.

## Troubleshooting

### "Email atau password salah"
- ✅ **Check:** Is `login_mentor.php` uploaded to your server?
- ✅ **Check:** Are database credentials correct?
- ✅ **Check:** Does the email exist in your PHP database?
- ✅ **Check:** Console for detailed error messages

### "Email tidak terdaftar"
- The email doesn't exist in PHP database
- Check the exact email in your database
- Might have extra spaces or different casing

### "Password salah"
- Password in database doesn't match
- Check how passwords are stored (plain, MD5, etc.)
- Verify the exact password in your database

### "Koneksi timeout"
- PHP server is not running
- Check ApiConfig.dart for correct server URL
- Verify PHP server is accessible

## Debug Commands

### Check if PHP server is running:
```bash
# If using built-in PHP server
lsof -i :8080

# Or check your server logs
tail -f /path/to/php/error.log
```

### Test PHP endpoint directly:
```bash
curl -X POST http://localhost:8080/mentorly/login_mentor.php \
  -d "email=rhyno@email.com" \
  -d "password=pass123"
```

Should return:
```json
{
  "status": "success",
  "message": "Login berhasil",
  "verified": true,
  "mentor_data": { ... }
}
```

## Quick Test (No Server Setup)

If you can't set up the PHP file right now, you can:

1. **Manually check your database:**
   ```sql
   SELECT * FROM mentor WHERE email = 'rhyno@email.com';
   ```

2. **If mentor exists and is verified**, use the Debug Page from earlier:
   - Open Debug Verify Mentor Page
   - Enter email: rhyno@email.com
   - Click "Verify by Email"
   - Try login again

## Security Notes

⚠️ **For Development Only:**
- This allows plain-text password verification
- Automatically creates Firebase accounts

✅ **For Production:**
- Hash all passwords in database
- Add rate limiting
- Add additional validation
- Remove debug print statements

## Next Steps

1. ✅ Upload `login_mentor.php` to your PHP server
2. ✅ Update database credentials in the file
3. ✅ Test with rhyno@email.com / pass123
4. ✅ Check console for detailed debug output
5. ✅ Verify Firebase account was created
6. ✅ Future logins will use Firebase Auth directly

---

**Ready to test?** 
1. Upload the PHP file
2. Restart your app
3. Try logging in with rhyno@email.com / pass123
4. Watch the console output!
