import 'package:pdf/widgets.dart' as pw;

import 'invoice_colors.dart';

/// Small gray uppercase column title.
pw.Widget pdf_header_cell(String text, {pw.TextAlign align = pw.TextAlign.right}) =>
    pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 5),
      child: pw.Text(
        text.toUpperCase(),
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 8,
          letterSpacing: 0.8,
          color: invoice_soft,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
