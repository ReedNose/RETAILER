import 'package:pdf/widgets.dart' as pw;

import 'invoice_colors.dart';

/// One "label ........ amount" row in the totals box.
pw.Widget pdf_total_row(String label, String amount, {bool is_bold = false}) {
  final style = pw.TextStyle(
    fontSize: is_bold ? 12 : 10.5,
    color: invoice_ink,
    fontWeight: is_bold ? pw.FontWeight.bold : pw.FontWeight.normal,
  );
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 4),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [pw.Text(label, style: style), pw.Text(amount, style: style)],
    ),
  );
}
