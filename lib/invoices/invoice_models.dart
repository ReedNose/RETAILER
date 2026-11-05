/// One printed line: all sales of one product on the invoice day, merged.
class InvoiceLine {
  const InvoiceLine({
    required this.sku,
    required this.product_name,
    required this.qty,
    required this.unit_price,
    required this.line_total,
  });

  final String sku;
  final String product_name;
  final int qty; // always positive
  final double unit_price; // average, because batches can carry different discounts
  final double line_total; // the exact sum of the sales, rounded to cents
}

/// Everything the invoice screen and the PDF need. No tax in this version.
class InvoiceData {
  const InvoiceData({
    required this.invoice_number,
    required this.date,
    required this.customer_name,
    required this.customer_whatsapp_no,
    required this.lines,
    required this.grand_total,
    required this.old_balance,
    required this.payments_received,
    required this.new_balance,
  });

  final String invoice_number;
  final DateTime date;
  final String customer_name;
  final String customer_whatsapp_no;
  final List<InvoiceLine> lines;
  final double grand_total; // sales on the invoice day
  final double old_balance; // owed before the invoice day
  final double payments_received; // paid on the invoice day
  final double new_balance; // old_balance + grand_total - payments_received
}
