/// Utility class for phone number normalization.
///
/// The Meta WhatsApp Cloud API requires phone numbers as pure digits
/// in international format without the '+' sign.
/// Example: "+58 424-123-4567" → "584241234567"
class PhoneUtils {
  /// Normalizes a phone number string to pure digits.
  ///
  /// Removes '+', spaces, hyphens, parentheses, and dots.
  /// Returns null if the input is null, empty, or results in
  /// fewer than 7 digits (considered an invalid phone number).
  static String? normalizeForWhatsApp(String? phone) {
    if (phone == null || phone.trim().isEmpty) return null;

    var digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');

    // Rule for Venezuela: if it starts with '0' and has 11 digits,
    // remove '0' and prepend '58'.
    if (digitsOnly.startsWith('0') && digitsOnly.length == 11) {
      digitsOnly = '58${digitsOnly.substring(1)}';
    }

    // A valid phone number should have at least 7 digits
    if (digitsOnly.length < 7) return null;

    return digitsOnly;
  }
}
