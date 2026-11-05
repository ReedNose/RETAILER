import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/app_config.dart';
import 'format_dollars.dart';
import 'invoice_colors.dart';
import 'invoice_models.dart';
import 'pdf_header_cell.dart';
import 'pdf_table_cell.dart';
import 'pdf_total_row.dart';

/// Draws the invoice as PDF bytes, in the same look as the preorder page:
/// blue title and rule, light-blue "Bill to" box, green "New balance" box.
/// No tax. Totals in order: grand total, old balance, payments, new balance.
Future<Uint8List> build_invoice_pdf(InvoiceData invoice) async {
  final document = pw.Document();

  final table_rows = <pw.TableRow>[
    pw.TableRow(
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(width: 1.2, color: invoice_ink)),
      ),
      children: [
        pdf_header_cell('Product', align: pw.TextAlign.left),
        pdf_header_cell('Qty'),
        pdf_header_cell('Unit price'),
        pdf_header_cell('Total'),
      ],
    ),
    for (final line in invoice.lines)
      pw.TableRow(
        children: [
          pdf_table_cell(line.product_name, is_bold: true, align: pw.TextAlign.left),
          pdf_table_cell('${line.qty}'),
          pdf_table_cell(format_dollars(line.unit_price)),
          pdf_table_cell(format_dollars(line.line_total)),
        ],
      ),
  ];

  final payments_text = invoice.payments_received > 0
      ? '-${format_dollars(invoice.payments_received)}'
      : format_dollars(0);

  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(40, 44, 40, 40),
      build: (pw.Context context) => [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  shop_name,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: invoice_ink,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  shop_tagline,
                  style: pw.TextStyle(fontSize: 9, color: invoice_soft),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'INVOICE',
                  style: pw.TextStyle(
                    fontSize: 24,
                    letterSpacing: 2,
                    fontWeight: pw.FontWeight.bold,
                    color: invoice_blue,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  invoice.invoice_number,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: invoice_ink,
                  ),
                ),
                pw.Text(
                  DateFormat('d MMM yyyy').format(invoice.date),
                  style: pw.TextStyle(fontSize: 9.5, color: invoice_soft),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 14),
        pw.Container(
          height: 4,
          decoration: pw.BoxDecoration(
            color: invoice_blue,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
          ),
        ),
        pw.SizedBox(height: 18),
        pw.Align(
          alignment: pw.Alignment.centerLeft,
          child: pw.Container(
            width: 190,
            padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: pw.BoxDecoration(
              color: invoice_tint,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'BILL TO',
                  style: pw.TextStyle(fontSize: 8, letterSpacing: 0.8, color: invoice_soft),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  invoice.customer_name,
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: invoice_ink,
                  ),
                ),
                pw.Text(
                  invoice.customer_whatsapp_no,
                  style: pw.TextStyle(fontSize: 9.5, color: invoice_soft),
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(height: 20),
        pw.Table(
          columnWidths: {
            0: const pw.FlexColumnWidth(4),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(2),
          },
          border: pw.TableBorder(
            horizontalInside: pw.BorderSide(width: 0.6, color: invoice_line),
            bottom: pw.BorderSide(width: 0.6, color: invoice_line),
          ),
          children: table_rows,
        ),
        pw.SizedBox(height: 18),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Container(
            width: 225,
            child: pw.Column(
              children: [
                pdf_total_row('Grand total', format_dollars(invoice.grand_total), is_bold: true),
                pdf_total_row('Old balance', format_dollars(invoice.old_balance)),
                pdf_total_row('Payments received', payments_text),
                pw.SizedBox(height: 6),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  decoration: pw.BoxDecoration(
                    color: invoice_green,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'New balance',
                        style: pw.TextStyle(
                          fontSize: 10.5,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text(
                        format_dollars(invoice.new_balance),
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(height: 60),
        pw.Divider(thickness: 0.6, color: invoice_line),
        pw.SizedBox(height: 6),
        pw.Center(
          child: pw.Text(
            'Thank you for your order',
            style: pw.TextStyle(fontSize: 9, color: invoice_soft),
          ),
        ),
      ],
    ),
  );

  return document.save();
}
