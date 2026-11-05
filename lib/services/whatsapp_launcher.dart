import 'package:url_launcher/url_launcher.dart';

/// Opens WhatsApp with a pre-filled message. Returns false if it could not open.
Future<bool> open_whatsapp({
  required String phone_no,
  required String message,
}) async {
  // wa.me wants digits only: no "+", spaces, or dashes.
  final digits = phone_no.replaceAll(RegExp(r'[^0-9]'), '');
  final uri = Uri.parse('https://wa.me/$digits?text=${Uri.encodeComponent(message)}');
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
