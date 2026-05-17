/// Indonesian phone-number normalizer/validator.
///
/// Canonical output = Wablas/E.164 digits-only form: `628xxxxxxxxx`
/// (country code 62 + mobile prefix 8 + 8..11 subscriber digits).
class PhoneIdResult {
  final bool valid;
  final String? canonical;
  final String? e164;
  final String? error;

  const PhoneIdResult._({
    required this.valid,
    this.canonical,
    this.e164,
    this.error,
  });

  factory PhoneIdResult.ok(String digits) => PhoneIdResult._(
        valid: true,
        canonical: digits,
        e164: '+$digits',
      );

  factory PhoneIdResult.invalid(String reason) =>
      PhoneIdResult._(valid: false, error: reason);
}

class PhoneId {
  /// Parse Indonesian phone string.
  ///
  /// Accepts: `+62 812-3456-7890`, `62 812 3456 7890`, `0812 3456 7890`,
  /// `0062-812-345-6789`, `812345678` (bare local mobile, no leading 0).
  /// Strips whitespace, dashes, dots, parens, slashes.
  static PhoneIdResult parse(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return PhoneIdResult.invalid('Nomor kosong.');
    }

    var digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return PhoneIdResult.invalid('Nomor tidak mengandung digit.');
    }

    digits = _stripCountryPrefix(digits);
    digits = _ensureCountryCode(digits);

    final lengthError = _validate(digits);
    if (lengthError != null) return PhoneIdResult.invalid(lengthError);

    return PhoneIdResult.ok(digits);
  }

  static String _stripCountryPrefix(String digits) {
    if (digits.startsWith('0062')) return '62${digits.substring(4)}';
    if (digits.startsWith('00')) return digits.substring(2);
    if (digits.startsWith('0')) return '62${digits.substring(1)}';
    return digits;
  }

  static String _ensureCountryCode(String digits) {
    if (digits.startsWith('62')) return digits;
    // Bare local mobile like '812345678' — assume Indonesian, prepend 62.
    if (digits.startsWith('8')) return '62$digits';
    return digits;
  }

  static String? _validate(String digits) {
    if (!digits.startsWith('62')) return 'Bukan nomor Indonesia.';
    if (!digits.startsWith('628')) return 'Bukan nomor seluler.';
    if (digits.length < 11 || digits.length > 14) {
      return 'Panjang nomor tidak valid.';
    }
    return null;
  }
}
