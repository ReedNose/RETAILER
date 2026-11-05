import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

import 'build_invoice_pdf.dart';
import 'invoice_models.dart';

/// Builds the PDF and opens the share sheet. The retailer picks WhatsApp and
/// then the customer's chat (a wa.me link cannot attach a file).
/// Returns false, and logs why, when anything goes wrong.
Future<bool> share_invoice_pdf(InvoiceData invoice) async {
  try {
    final bytes = await build_invoice_pdf(invoice);
    final file_name = '${invoice.invoice_number}.pdf';
    await Share.shareXFiles(
      [XFile.fromData(bytes, mimeType: 'application/pdf', name: file_name)],
      fileNameOverrides: [file_name],
      text: 'Invoice ${invoice.invoice_number} for ${invoice.customer_name}',
    );
    return true;
  } catch (error, stack) {
    debugPrint('share_invoice_pdf failed: $error\n$stack');
    return false;
  }
}
