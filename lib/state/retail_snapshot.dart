import '../core/batch_freshness.dart';
import '../core/date_helpers.dart';
import '../core/first_or_null.dart';
import '../core/sku_helpers.dart';
import '../models/customer.dart';
import '../models/ledger_row.dart';
import '../models/need_list_row.dart';
import '../models/invoice_payment.dart';
import '../models/payment.dart';
import '../models/product.dart';
import '../models/vendor.dart';
import '../models/warehouse_batch.dart';

/// Everything in memory at once (tiny business), filtered in Dart.
class RetailSnapshot {
  const RetailSnapshot({
    required this.products,
    required this.vendors,
    required this.customers,
    required this.warehouse,
    required this.need_list,
    required this.ledger,
    required this.payments,
    this.invoice_payments = const [],
  });

  final List<Product> products;
  final List<Vendor> vendors;
  final List<Customer> customers;
  final List<WarehouseBatch> warehouse;
  final List<NeedListRow> need_list;
  final List<LedgerRow> ledger;
  final List<Payment> payments;
  final List<InvoicePayment> invoice_payments;

  /// Paid (purchase) or received (sales) so far on one invoice.
  double paid_on_invoice(String transaction_id) => invoice_payments
      .where((p) => p.transaction_id == transaction_id)
      .fold(0.0, (sum, p) => sum + p.amount);

  /// Customer-facing stock number: total across batches, no dates or vendors.
  int total_stock_for_sku(String sku) => warehouse
      .where((b) => sku_from_batch_id(b.batch_id) == sku)
      .fold(0, (sum, b) => sum + b.current_qty);

  Product? product_by_sku(String sku) =>
      first_where_or_null(products, (p) => p.sku == sku);

  /// Live batches for one product, oldest first. Oldest is Day 2, so it
  /// always sits at the top of every picker.
  List<WarehouseBatch> batches_for_sku(String sku) {
    final batches = warehouse.where((b) => b.sku == sku).toList();
    batches.sort((a, b) => a.batch_date.compareTo(b.batch_date));
    return batches;
  }

  WarehouseBatch? batch_by_id(String batch_id) =>
      first_where_or_null(warehouse, (b) => b.batch_id == batch_id);

  /// Every batch_id ever made, including batches already gone from the warehouse.
  Set<String> get all_batch_ids => {for (final row in ledger) row.batch_id};

  /// Open need-list rows for one pickup day.
  List<NeedListRow> open_need_rows_on(DateTime day) => need_list
      .where((r) => !r.is_done && is_same_date(r.pickup_date, day))
      .toList();

  int open_need_qty_for_sku(String sku, DateTime day) => open_need_rows_on(day)
      .where((r) => r.sku == sku)
      .fold(0, (sum, r) => sum + r.qty);

  /// Batches on their last day of shelf life (the Day 2 rule), oldest first.
  List<WarehouseBatch> priority_batches(DateTime today) {
    final found = warehouse
        .where((b) => is_priority_batch(
              batch_date: b.batch_date,
              shelf_life_days: product_by_sku(b.sku)?.shelf_life_days ?? 2,
              today: today,
            ))
        .toList();
    found.sort((a, b) => a.batch_date.compareTo(b.batch_date));
    return found;
  }

  /// Units on the shelf, all batches together.
  int get units_on_shelf => warehouse.fold(0, (sum, b) => sum + b.current_qty);

  /// What the shelf would bring in at the default retail prices.
  double get shelf_retail_value => warehouse.fold(
      0.0,
      (sum, b) =>
          sum + b.current_qty * (product_by_sku(b.sku)?.default_retail_price ?? 0.0));

  String customer_name(String customer_id) =>
      first_where_or_null(customers, (c) => c.customer_id == customer_id)
          ?.name ??
      'Unknown customer';

  String vendor_name(String vendor_id) =>
      first_where_or_null(vendors, (v) => v.vendor_id == vendor_id)?.name ??
      'Unknown vendor';
}
