import '../core/date_helpers.dart';
import '../core/first_or_null.dart';
import '../state/retail_snapshot.dart';
import 'balance_before_date.dart';
import 'build_invoice_lines.dart';
import 'build_invoice_number.dart';
import 'invoice_models.dart';
import 'payments_on_date.dart';
import 'round_money.dart';
import 'sales_rows_for_customer_on.dart';

/// One customer, one day. Returns null when the customer is unknown or has no
/// sales that day (there is nothing to invoice).
///
/// grand_total   = sales on the day
/// old_balance   = owed before the day
/// new_balance   = old_balance + grand_total - payments received on the day
InvoiceData? build_invoice_data({
  required RetailSnapshot snapshot,
  required String customer_id,
  required DateTime day,
}) {
  final invoice_day = date_only(day);
  final customer = first_where_or_null(
    snapshot.customers,
    (c) => c.customer_id == customer_id,
  );
  if (customer == null) return null;

  final rows = sales_rows_for_customer_on(
    ledger: snapshot.ledger,
    customer_id: customer_id,
    day: invoice_day,
  );
  if (rows.isEmpty) return null;

  final lines = build_invoice_lines(
    rows: rows,
    product_name_of: (sku) => snapshot.product_by_sku(sku)?.name ?? sku,
  );
  // Summed from the printed lines, so the invoice always adds up on paper.
  final grand_total = round_money(lines.fold(0.0, (sum, line) => sum + line.line_total));

  final old_balance = balance_before_date(
    ledger: snapshot.ledger,
    payments: snapshot.payments,
    customer_id: customer_id,
    day: invoice_day,
  );
  final payments_received = payments_on_date(
    payments: snapshot.payments,
    customer_id: customer_id,
    day: invoice_day,
  );

  return InvoiceData(
    invoice_number: build_invoice_number(customer_id: customer_id, day: invoice_day),
    date: invoice_day,
    customer_name: customer.name,
    customer_whatsapp_no: customer.whatsapp_no,
    lines: lines,
    grand_total: grand_total,
    old_balance: old_balance,
    payments_received: payments_received,
    new_balance: round_money(old_balance + grand_total - payments_received),
  );
}
