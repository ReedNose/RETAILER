import '../../core/batch_id_generator.dart';
import '../../core/date_helpers.dart';
import '../../core/first_or_null.dart';
import '../../models/app_user.dart';
import '../../models/invoice_payment.dart';
import '../../models/ledger_row.dart';
import '../../models/need_list_row.dart';
import '../../models/payment.dart';
import '../../models/pickup_allocation.dart';
import '../../models/purchase_line.dart';
import '../../models/warehouse_batch.dart';
import '../../state/retail_snapshot.dart';
import '../retail_repository.dart';
import 'seed_data.dart';

/// In-memory repository with the same rules as the backend. Everything resets on restart.
/// Used for demos only (see use_demo_data in retail_providers.dart).
class MockRetailRepository implements RetailRepository {
  MockRetailRepository() {
    final today = date_only(DateTime.now());
    _warehouse = build_seed_warehouse(today);
    _ledger = build_seed_ledger(today);
    _need_list = build_seed_need_list(today);
  }

  late List<WarehouseBatch> _warehouse;
  late List<LedgerRow> _ledger;
  late List<NeedListRow> _need_list;
  final List<Payment> _payments = [];
  final List<InvoicePayment> _invoice_payments = [];
  int _next_id = 100;

  String _new_id(String prefix) => '$prefix${++_next_id}';

  @override
  Future<AppUser> sign_in(String pin) async {
    final user = first_where_or_null(seed_users, (u) => u.pin_hash == pin);
    if (user == null) throw const WrongPin();
    return user;
  }

  @override
  void sign_out() {}

  @override
  Future<RetailSnapshot> fetch_snapshot() async => RetailSnapshot(
        products: seed_products,
        vendors: seed_vendors,
        customers: seed_customers,
        warehouse: List.of(_warehouse),
        need_list: List.of(_need_list),
        ledger: List.of(_ledger),
        payments: List.of(_payments),
        invoice_payments: List.of(_invoice_payments),
      );

  @override
  Future<void> add_need_list_rows({
    required String customer_id,
    required DateTime pickup_date,
    required Map<String, int> qty_by_sku,
  }) async {
    // Same rule as the backend: resending replaces only the OPEN rows for that day.
    final day = date_only(pickup_date);
    final now = DateTime.now();
    _need_list = [
      for (final row in _need_list)
        if (!(row.customer_id == customer_id && !row.is_done && is_same_date(row.pickup_date, day)))
          row,
      for (final entry in qty_by_sku.entries)
        if (entry.value > 0)
          NeedListRow(
            need_id: _new_id('N'),
            created_at: now,
            pickup_date: day,
            customer_id: customer_id,
            sku: entry.key,
            qty: entry.value,
            is_done: false,
          ),
    ];
  }

  @override
  Future<void> mark_need_list_done({
    required String customer_id,
    required DateTime pickup_date,
  }) async {
    _need_list = [
      for (final row in _need_list)
        (row.customer_id == customer_id && !row.is_done && is_same_date(row.pickup_date, pickup_date))
            ? row.marked_done()
            : row,
    ];
  }

  @override
  Future<String> save_purchase_invoice({
    required String vendor_id,
    required List<PurchaseLine> lines,
    required double paid,
  }) async {
    if (lines.isEmpty) throw StateError('Add at least one item.');
    final total = lines.fold(0.0, (sum, line) => sum + line.qty * line.unit_cost);
    if (paid > total + 0.005) throw StateError('That is more than the invoice amount');

    final transaction_id = _new_id('TRX');
    for (final line in lines) {
      final batch_id = generate_batch_id(line.sku, _all_batch_ids());
      _warehouse.add(WarehouseBatch(
        batch_id: batch_id,
        vendor_id: vendor_id,
        batch_date: date_only(DateTime.now()),
        current_qty: line.qty,
      ));
      _ledger.add(_ledger_row(
        transaction_id: transaction_id,
        type: TransactionType.purchase,
        source_type: SourceType.vendor,
        source_id: vendor_id,
        batch_id: batch_id,
        qty: line.qty,
        unit_price: line.unit_cost,
      ));
    }
    if (paid > 0) {
      await record_invoice_payment(transaction_id: transaction_id, amount: paid);
    }
    return transaction_id;
  }

  @override
  Future<String> save_sales_invoice({
    required String customer_id,
    required List<PickupAllocation> lines,
    required double received,
  }) async {
    if (lines.isEmpty) throw StateError('Add at least one item.');

    // Every line is checked before the first change, so a bad line changes nothing.
    final wanted = <String, int>{};
    for (final line in lines) {
      wanted[line.batch_id] = (wanted[line.batch_id] ?? 0) + line.qty;
    }
    for (final entry in wanted.entries) {
      final batch = first_where_or_null(_warehouse, (b) => b.batch_id == entry.key);
      final left = batch?.current_qty ?? 0;
      if (entry.value > left) throw StateError('Only $left left in ${entry.key}');
    }
    final total = lines.fold(0.0, (sum, line) => sum + line.qty * line.unit_price);
    if (received > total + 0.005) throw StateError('That is more than the invoice amount');

    final transaction_id = _new_id('TRX');
    var seq = 0; // tiny stagger so rows of the same invoice sort deterministically
    for (final line in lines) {
      _take_from_warehouse(line.batch_id, line.qty);
      _ledger.add(_ledger_row(
        transaction_id: transaction_id,
        type: TransactionType.sale,
        source_type: SourceType.customer,
        source_id: customer_id,
        batch_id: line.batch_id,
        qty: -line.qty,
        unit_price: line.unit_price,
        created_at: DateTime.now().add(Duration(milliseconds: seq++)),
      ));
    }
    if (received > 0) {
      await record_invoice_payment(transaction_id: transaction_id, amount: received);
    }
    return transaction_id;
  }

  @override
  Future<void> log_spoilage({
    required String batch_id,
    required int qty,
    required double original_purchase_cost,
  }) async {
    final batch = first_where_or_null(_warehouse, (b) => b.batch_id == batch_id);
    if (batch == null) throw StateError('Batch $batch_id is not in the warehouse.');
    _take_from_warehouse(batch_id, qty);
    _ledger.add(_ledger_row(
      type: TransactionType.spoilage,
      source_type: SourceType.vendor,
      source_id: batch.vendor_id,
      batch_id: batch_id,
      qty: -qty,
      unit_price: original_purchase_cost,
    ));
  }

  @override
  Future<void> add_payment({
    required String customer_id,
    required double amount,
  }) async {
    if (amount <= 0) throw StateError('A payment must be more than zero.');
    if (!seed_customers.any((c) => c.customer_id == customer_id)) {
      throw StateError('Unknown customer $customer_id.');
    }
    _add_customer_payment(customer_id, amount);
  }

  @override
  Future<void> record_invoice_payment({
    required String transaction_id,
    required double amount,
  }) async {
    if (amount <= 0) throw StateError('A payment must be more than zero.');
    final rows = _ledger
        .where((r) => r.transaction_id == transaction_id && r.transaction_type != TransactionType.spoilage)
        .toList();
    if (rows.isEmpty) throw StateError('Unknown invoice $transaction_id.');
    final total = rows.fold(0.0, (sum, r) => sum + r.total_amount);
    final paid = _invoice_payments
        .where((p) => p.transaction_id == transaction_id)
        .fold(0.0, (sum, p) => sum + p.amount);
    if (amount > total - paid + 0.005) {
      throw StateError('Only ${(total - paid).toStringAsFixed(2)} is still open.');
    }
    final now = DateTime.now();
    _invoice_payments.add(InvoicePayment(
      payment_id: _new_id('IP'),
      created_at: now,
      date: date_only(now),
      transaction_id: transaction_id,
      amount: amount,
    ));
    // A sales receipt also lowers the customer's balance.
    if (rows.first.transaction_type == TransactionType.sale) {
      _add_customer_payment(rows.first.source_id, amount);
    }
  }

  // ---- private helpers ----

  Set<String> _all_batch_ids() => {
        for (final batch in _warehouse) batch.batch_id,
        for (final row in _ledger) row.batch_id,
      };

  void _add_customer_payment(String customer_id, double amount) {
    final now = DateTime.now();
    _payments.add(Payment(
      payment_id: _new_id('P'),
      created_at: now,
      date: date_only(now),
      customer_id: customer_id,
      amount: amount,
    ));
  }

  /// Removes qty from a batch; deletes the row at 0 (the Zero-Qty Rule).
  void _take_from_warehouse(String batch_id, int qty) {
    final index = _warehouse.indexWhere((b) => b.batch_id == batch_id);
    if (index < 0) throw StateError('Batch $batch_id is not in the warehouse.');
    final batch = _warehouse[index];
    if (qty <= 0 || qty > batch.current_qty) {
      throw StateError('Cannot take $qty from $batch_id (has ${batch.current_qty}).');
    }
    if (qty == batch.current_qty) {
      _warehouse.removeAt(index);
    } else {
      _warehouse[index] = batch.with_qty(batch.current_qty - qty);
    }
  }

  LedgerRow _ledger_row({
    String? transaction_id,
    required TransactionType type,
    required SourceType source_type,
    required String source_id,
    required String batch_id,
    required int qty,
    required double unit_price,
    DateTime? created_at,
  }) {
    final now = created_at ?? DateTime.now();
    return LedgerRow(
      transaction_id: transaction_id ?? _new_id('L'),
      created_at: now,
      date: date_only(now),
      transaction_type: type,
      source_type: source_type,
      source_id: source_id,
      batch_id: batch_id,
      qty: qty,
      unit_price: unit_price,
      total_amount: qty.abs() * unit_price, // always positive
    );
  }
}
