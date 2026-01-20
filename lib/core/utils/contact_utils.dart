import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUtils {
  static Future<void> makePhoneCall(String? phone) async {
    if (phone == null || phone.isEmpty) return;

    // Cleanup phone number (keep only digits and +)
    final cleanedPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri launchUri = Uri(scheme: 'tel', path: cleanedPhone);

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        // Fallback: try launching anyway
        await launchUrl(launchUri);
      }
    } catch (e) {
      debugPrint('Could not launch phone call: $e');
      throw 'No se pudo realizar la llamada';
    }
  }

  static Future<void> launchWhatsApp(String? phone) async {
    if (phone == null || phone.isEmpty) return;

    // Cleanup - remove + and non-digits
    var cleanedPhone = phone.replaceAll(RegExp(r'\D'), '');

    // Add country code if missing (Basic heuristic for Venezuela)
    // If it starts with '0' (e.g. 0414...), replace 0 with 58
    if (cleanedPhone.startsWith('0')) {
      cleanedPhone = '58${cleanedPhone.substring(1)}';
    } else if (cleanedPhone.length == 10 && !cleanedPhone.startsWith('58')) {
      // If it's just 414... (10 digits) and not 58..., assume it needs 58
      cleanedPhone = '58$cleanedPhone';
    }

    // Using wa.me link
    // Note: wa.me often redirects to different schemes, external app mode is best.
    final Uri launchUri = Uri.parse('https://wa.me/$cleanedPhone');

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: try launching anyway
        await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not launch WhatsApp: $e');
      throw 'No se pudo abrir WhatsApp';
    }
  }
}
