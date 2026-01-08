import 'package:encrypt/encrypt.dart' as encrypt;

class EncryptionHelper {
  // 32 Karakter (32 bytes) untuk AES-256
  static final _key = encrypt.Key.fromUtf8('z3P9bV7xR2mN5qA8kL4jH1sD6fG0tY9u');

  // 16 Karakter (16 bytes) untuk IV
  static final _iv = encrypt.IV.fromUtf8('a1b2c3d4e5f6g7h8');

  static String encryptData(String text) {
    if (text.isEmpty) return text;
    final encrypter = encrypt.Encrypter(encrypt.AES(_key));
    final encrypted = encrypter.encrypt(text, iv: _iv);
    print('🔒 Encrypted: $text -> ${encrypted.base64}');
    return encrypted.base64;
  }

  static String decryptData(String encryptedText) {
    if (encryptedText.isEmpty) return encryptedText;
    try {
      final encrypter = encrypt.Encrypter(encrypt.AES(_key));
      final decrypted = encrypter.decrypt64(encryptedText, iv: _iv);
      print('🔓 Decrypted: $encryptedText -> $decrypted');
      return decrypted;
    } catch (e) {
      print('❌ Decrypt error: $e');
      return encryptedText;
    }
  }
}
