import 'package:pdf/widgets.dart' as pw;

import 'invoice_colors.dart';

/// One padded body cell of the invoice table.
pw.Widget pdf_table_cell(
  String text, {
  bool is_bold = false,
  pw.TextAlign align = pw.TextAlign.right,
}) =>
    pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 9, horizontal: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 10.5,
          color: invoice_ink,
          fontWeight: is_bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
