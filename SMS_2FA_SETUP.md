# 🔐 2FA SMS Authentication untuk Registrasi Pelajar

## Overview
Sistem verifikasi 2-Factor Authentication (2FA) berbasis SMS untuk registrasi pelajar baru. Menggantikan verifikasi email dengan verifikasi nomor telepon yang lebih cepat dan reliable.

## Flow Registrasi

### 1. **Input Data Registrasi**
Pelajar memasukkan:
- Email
- Password (min 6 karakter)
- Nomor telepon (format: +62xxx untuk Indonesia)

### 2. **Verifikasi Nomor Telepon**
- Sistem mengirim kode 6 digit ke nomor telepon via SMS
- Kode berlaku selama 60 detik
- User dapat meminta kirim ulang setelah countdown selesai

### 3. **Input Kode Verifikasi**
- User memasukkan kode 6 digit yang diterima
- Sistem memverifikasi kode dengan Firebase Phone Auth
- Jika berhasil, akun langsung aktif

### 4. **Registrasi Selesai**
- Data user disimpan ke Firebase Realtime Database
- Status `phone_verified: true`
- User diarahkan ke halaman login

## Files Created/Modified

### New Files:
1. **lib/pelajar/phone_verification_page.dart**
   - Halaman input kode verifikasi
   - Countdown timer untuk kirim ulang (60 detik)
   - Auto-verification untuk Android
   - Error handling lengkap

### Modified Files:
1. **lib/pelajar/register_pelajar.dart**
   - Implementasi Firebase Phone Authentication
   - Validasi format nomor telepon (harus pakai +62)
   - Flow registrasi baru dengan SMS verification
   - Link phone credential dengan email account

## Firebase Setup Required

### 1. Enable Phone Authentication
```
Firebase Console → Authentication → Sign-in method → Phone → Enable
```

### 2. Add Test Phone Numbers (Development)
```
Firebase Console → Authentication → Sign-in method → Phone → Test phone numbers
Tambahkan: +1234567890 dengan kode: 123456
```

### 3. iOS Setup (Info.plist sudah configured)
```xml
<key>UIApplicationSupportsIndirectInputEvents</key>
<true/>
```

### 4. Android Setup (AndroidManifest.xml sudah configured)
- Permission: INTERNET, RECEIVE_SMS (opsional untuk auto-verify)
- SafetyNet API key (untuk production)

## Features

### ✅ Implemented:
- [x] Phone number validation (format +62xxx)
- [x] SMS code sending via Firebase
- [x] 6-digit verification code input
- [x] Resend code with countdown (60 seconds)
- [x] Auto-verification (Android only)
- [x] Link phone auth dengan email account
- [x] Save verified user to Firebase RTDB
- [x] Error handling untuk berbagai kasus

### 🔒 Security Features:
- [x] Code expires after 60 seconds
- [x] Rate limiting (too-many-requests protection)
- [x] Invalid phone number detection
- [x] Session management (auto sign-out after registration)

### 📱 User Experience:
- [x] Clear instructions untuk format nomor
- [x] Visual countdown untuk resend
- [x] Loading indicators
- [x] Error messages yang jelas
- [x] Opsi untuk ubah nomor telepon

## Usage

### Format Nomor Telepon:
```
Indonesia: +628123456789
USA:       +12025551234
UK:        +447911123456
```

### Testing (Development):
1. Gunakan test phone number dari Firebase Console
2. Atau gunakan nomor asli (akan terkirim SMS sungguhan)

### Production Considerations:
1. **SMS Quota**: Firebase memberikan quota gratis terbatas
2. **Cost**: SMS verification ada biayanya setelah quota habis
3. **Region Support**: Pastikan negara target support SMS verification
4. **Fraud Prevention**: Monitor untuk abuse/spam registrations

## Error Handling

### Common Errors:
| Error Code | Pesan | Solusi |
|------------|-------|--------|
| `invalid-phone-number` | Format nomor tidak valid | Gunakan format +62xxx |
| `too-many-requests` | Terlalu banyak percobaan | Tunggu beberapa menit |
| `invalid-verification-code` | Kode salah | Cek ulang kode dari SMS |
| `session-expired` | Kode expired | Minta kode baru |

## Database Structure

```json
{
  "pelajar": {
    "USER_UID": {
      "email": "user@example.com",
      "phone": "+628123456789",
      "created_at": "2026-01-02T10:30:00.000Z",
      "uid": "USER_UID",
      "email_verified": true,
      "phone_verified": true
    }
  }
}
```

## Benefits vs Email Verification

| Aspek | Email Verification | SMS 2FA |
|-------|-------------------|---------|
| Kecepatan | 1-5 menit | 5-30 detik |
| Success Rate | ~60% (spam folder) | ~95% |
| User Experience | Perlu buka email | Langsung di app |
| Security | Medium | High |
| Cost | Gratis | Berbayar (setelah quota) |
| Automation | Susah ditest | Mudah ditest |

## Next Steps

### Potential Improvements:
1. Add phone number formatting helper (auto-add +62)
2. Implement reCAPTCHA untuk production
3. Add analytics untuk track verification success rate
4. Implement SMS fallback jika WhatsApp verification gagal
5. Add multi-language support untuk SMS message

## Testing Checklist

- [ ] Test dengan nomor Indonesia (+62)
- [ ] Test dengan nomor internasional
- [ ] Test resend code functionality
- [ ] Test dengan kode salah
- [ ] Test dengan kode expired
- [ ] Test too-many-requests scenario
- [ ] Test invalid phone format
- [ ] Test registration completion
- [ ] Test database saving
- [ ] Test auto-verification (Android)

## Known Limitations

1. **iOS Auto-verification**: Tidak support (user harus manual input kode)
2. **SMS Delivery**: Bergantung pada operator dan negara
3. **Cost**: Ada biaya untuk SMS setelah quota Firebase habis
4. **Rate Limiting**: Max requests per phone number per periode waktu

## Support

Untuk troubleshooting:
1. Cek Firebase Console → Authentication → Usage
2. Cek logs untuk error codes
3. Verify phone authentication is enabled
4. Check test phone numbers configuration
