import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

import '../state/retail_snapshot.dart';
import 'build_ledger_invoice_pdf.dart';
import 'ledger_invoice.dart';

/// Builds the purchase or sales invoice PDF and opens the share sheet.
/// Returns false, and logs why, when anything goes wrong.
Future<bool> share_ledger_invoice_pdf(
  LedgerInvoice invoice,
  RetailSnapshot snapshot,
) async {
  try {
    final bytes = await build_ledger_invoice_pdf(invoice, snapshot);
    final file_name = '${invoice.transaction_id}.pdf';
    await Share.shareXFiles(
      [XFile.fromData(bytes, mimeType: 'application/pdf', name: file_name)],
      fileNameOverrides: [file_name],
      text: 'Invoice ${invoice.transaction_id}',
    );
    return true;
  } catch (error, stack) {
    debugPrint('share_ledger_invoice_pdf failed: $error\n$stack');
    return false;
  }
}
