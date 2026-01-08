# 🚀 Quick Deploy Guide - Admin Dashboard Only

## One-Command Deploy

```bash
./deploy_admin.sh
```

Atau manual:

```bash
# 1. Copy admin files
mkdir -p admin_web
cp web/admin.html admin_web/
cp web/admin_register.html admin_web/

# 2. Deploy
firebase deploy --only hosting
```

## 📁 Struktur Hosting

Firebase hanya hosting folder `admin_web/` yang berisi:
- `admin.html` - Dashboard admin
- `admin_register.html` - Registrasi admin

**TIDAK** termasuk aplikasi Flutter (index.html)

## Access URLs

- **Admin Dashboard**: https://mentorly-66d07.web.app/admin
- **Admin Register**: https://mentorly-66d07.web.app/admin-register

## First Time Setup

1. **Buka halaman registrasi**:
   ```
   https://mentorly-66d07.web.app/admin-register
   ```

2. **Daftarkan admin pertama**:
   - Email: your-email@gmail.com
   - Password: (minimal 6 karakter)
   - Nama: Your Name
   - Role: Admin

3. **Login ke dashboard**:
   ```
   https://mentorly-66d07.web.app/admin
   ```

## Database Structure

```
admin/
  └── {uid}/
      ├── email: "admin@mentorly.com"
      ├── nama: "Admin Name"
      ├── role: "admin"
      └── created_at: "2026-01-08..."
```

## Security

✅ Protected dengan Firebase Auth
✅ Only registered admins can access
✅ Stored in `admin` node in Realtime Database
✅ Database rules enforce permissions

## Support

Check [ADMIN_WEB_SETUP.md](ADMIN_WEB_SETUP.md) for detailed documentation.
