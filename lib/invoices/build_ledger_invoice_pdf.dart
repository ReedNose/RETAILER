import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/app_config.dart';
import '../models/ledger_row.dart';
import '../state/retail_snapshot.dart';
import 'format_dollars.dart';
import 'invoice_colors.dart';
import 'ledger_invoice.dart';
import 'pdf_header_cell.dart';
import 'pdf_table_cell.dart';
import 'pdf_total_row.dart';
import 'round_money.dart';

/// PDF for one purchase or sales invoice (one transaction_id).
/// Lines show qty, unit price and amount; the totals are only the amount and
/// the payment: Paid on a purchase, Received on a sale.
Future<Uint8List> build_ledger_invoice_pdf(
  LedgerInvoice invoice,
  RetailSnapshot snapshot,
) async {
  final is_purchase = invoice.type == TransactionType.purchase;
  final party_name = is_purchase
      ? snapshot.vendor_name(invoice.party_id)
      : snapshot.customer_name(invoice.party_id);
  final paid = round_money(snapshot.paid_on_invoice(invoice.transaction_id));
  final payment_label = is_purchase ? 'Paid' : 'Received';

  final document = pw.Document();
  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(40, 44, 40, 40),
      build: (pw.Context context) => [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
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
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  is_purchase ? 'PURCHASE INVOICE' : 'INVOICE',
                  style: pw.TextStyle(
                    fontSize: 20,
                    letterSpacing: 1.5,
                    fontWeight: pw.FontWeight.bold,
                    color: invoice_blue,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  invoice.transaction_id,
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
                  is_purchase ? 'SUPPLIER' : 'BILL TO',
                  style: pw.TextStyle(fontSize: 8, letterSpacing: 0.8, color: invoice_soft),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  party_name,
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: invoice_ink,
                  ),
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
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(width: 1.2, color: invoice_ink)),
              ),
              children: [
                pdf_header_cell('Product', align: pw.TextAlign.left),
                pdf_header_cell('Qty'),
                pdf_header_cell('Unit price'),
                pdf_header_cell('Amount'),
              ],
            ),
            for (final row in invoice.rows)
              pw.TableRow(
                children: [
                  pdf_table_cell(
                    snapshot.product_by_sku(row.sku)?.name ?? row.sku,
                    is_bold: true,
                    align: pw.TextAlign.left,
                  ),
                  pdf_table_cell('${row.qty.abs()}'),
                  pdf_table_cell(format_dollars(row.unit_price)),
                  pdf_table_cell(format_dollars(row.total_amount)),
                ],
              ),
          ],
        ),
        pw.SizedBox(height: 18),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Container(
            width: 225,
            child: pw.Column(
              children: [
                pdf_total_row('Amount', format_dollars(invoice.total), is_bold: true),
                pdf_total_row(payment_label, format_dollars(paid)),
              ],
            ),
          ),
        ),
      ],
    ),
  );
  return document.save();
}
