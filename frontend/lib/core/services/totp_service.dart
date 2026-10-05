import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// RFC 6238 / RFC 4226 compliant TOTP (Time-Based One-Time Password) service.
/// Compatible with Google Authenticator, Microsoft Authenticator, Authy, Apple Passwords, etc.
class TotpService {
  static const String base32Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

  /// Generates a cryptographically secure random Base32 secret string.
  static String generateSecret({int byteLength = 20}) {
    final rand = Random.secure();
    final bytes = Uint8List(byteLength);
    for (int i = 0; i < byteLength; i++) {
      bytes[i] = rand.nextInt(256);
    }
    return base32Encode(bytes);
  }

  /// Encodes raw bytes into standard RFC 4648 Base32.
  static String base32Encode(Uint8List bytes) {
    int buffer = 0;
    int bitsLeft = 0;
    final sb = StringBuffer();

    for (final byte in bytes) {
      buffer = (buffer << 8) | byte;
      bitsLeft += 8;
      while (bitsLeft >= 5) {
        bitsLeft -= 5;
        final index = (buffer >> bitsLeft) & 0x1F;
        sb.write(base32Chars[index]);
      }
    }

    if (bitsLeft > 0) {
      final index = (buffer << (5 - bitsLeft)) & 0x1F;
      sb.write(base32Chars[index]);
    }

    return sb.toString();
  }

  /// Decodes a Base32 string into raw bytes.
  static Uint8List base32Decode(String input) {
    final sanitized = input.replaceAll('=', '').replaceAll(' ', '').toUpperCase();
    int buffer = 0;
    int bitsLeft = 0;
    final List<int> bytes = [];

    for (int i = 0; i < sanitized.length; i++) {
      final char = sanitized[i];
      final val = base32Chars.indexOf(char);
      if (val == -1) continue;

      buffer = (buffer << 5) | val;
      bitsLeft += 5;
      if (bitsLeft >= 8) {
        bitsLeft -= 8;
        bytes.add((buffer >> bitsLeft) & 0xFF);
      }
    }

    return Uint8List.fromList(bytes);
  }

  /// Generates the standard 6-digit TOTP code for a given secret at the specified timestamp.
  static String generateCode({
    required String secret,
    int? timestampSeconds,
    int digits = 6,
    int period = 30,
  }) {
    final time = timestampSeconds ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000);
    final counter = time ~/ period;

    final key = base32Decode(secret);
    final counterBytes = Uint8List(8);
    var temp = counter;
    for (int i = 7; i >= 0; i--) {
      counterBytes[i] = temp & 0xFF;
      temp = temp >> 8;
    }

    final hmac = Hmac(sha1, key);
    final digest = hmac.convert(counterBytes).bytes;

    final offset = digest[digest.length - 1] & 0x0F;
    final binary = ((digest[offset] & 0x7F) << 24) |
        ((digest[offset + 1] & 0xFF) << 16) |
        ((digest[offset + 2] & 0xFF) << 8) |
        (digest[offset + 3] & 0xFF);

    final modulo = pow(10, digits).toInt();
    final otp = binary % modulo;
    return otp.toString().padLeft(digits, '0');
  }

  /// Verifies a 6-digit code against a secret with time-drift tolerance (default +/- 1 period = 30s).
  static bool verifyCode({
    required String secret,
    required String code,
    int window = 1,
    int period = 30,
  }) {
    final cleanCode = code.trim().replaceAll(RegExp(r'\s+'), '');
    if (cleanCode.length != 6) return false;

    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    for (int i = -window; i <= window; i++) {
      final testTime = nowSeconds + (i * period);
      final generated = generateCode(secret: secret, timestampSeconds: testTime, period: period);
      if (generated == cleanCode) {
        return true;
      }
    }
    return false;
  }

  /// Builds the standard `otpauth://totp/...` URI formatted for QR code generation.
  static String getOtpAuthUri({
    required String userId,
    required String secret,
    String issuer = 'Sarrera Platform',
  }) {
    final encodedIssuer = Uri.encodeComponent(issuer);
    final encodedUser = Uri.encodeComponent(userId);
    return 'otpauth://totp/$encodedIssuer:$encodedUser?secret=$secret&issuer=$encodedIssuer&algorithm=SHA1&digits=6&period=30';
  }
}
