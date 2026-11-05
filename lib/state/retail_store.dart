import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/retail_repository.dart';
import '../models/ledger_row.dart';
import '../models/pickup_allocation.dart';
import '../models/purchase_line.dart';
import 'retail_providers.dart';
import 'retail_snapshot.dart';

/// Holds the snapshot the screens read. Each write is one repository call (a whole
/// invoice is one call, so it saves in full or not at all), then the snapshot reloads.
class RetailStore extends AsyncNotifier<RetailSnapshot> {
  RetailRepository get _repo => ref.read(retail_repository_provider);

  @override
  Future<RetailSnapshot> build() => _repo.fetch_snapshot();

  Future<void> _reload() async => state = AsyncData(await _repo.fetch_snapshot());

  /// Pull-to-refresh. Keeps the old data on screen if the call fails.
  Future<void> refresh() async {
    try {
      await _reload();
    } catch (_) {
      // The screens keep showing the last good snapshot.
    }
  }

  Future<void> send_need_list({
    required String customer_id,
    required DateTime pickup_date,
    required Map<String, int> qty_by_sku,
  }) async {
    await _repo.add_need_list_rows(
      customer_id: customer_id,
      pickup_date: pickup_date,
      qty_by_sku: qty_by_sku,
    );
    await _reload();
  }

  /// New stock in, one line. The server makes the batch id.
  Future<void> add_stock({
    required String sku,
    required String vendor_id,
    required int qty,
    required double unit_cost,
  }) async {
    await _repo.save_purchase_invoice(
      vendor_id: vendor_id,
      lines: [PurchaseLine(sku: sku, qty: qty, unit_cost: unit_cost)],
      paid: 0,
    );
    await _reload();
  }

  /// One walk-in sale from one batch.
  Future<void> sell_from_batch({
    required String batch_id,
    required String customer_id,
    required int qty,
    required double unit_price,
  }) async {
    await _repo.save_sales_invoice(
      customer_id: customer_id,
      lines: [PickupAllocation(batch_id: batch_id, qty: qty, unit_price: unit_price)],
      received: 0,
    );
    await _reload();
  }

  /// Spoilage is valued at the batch's purchase cost, read from the snapshot.
  Future<void> log_spoilage({required String batch_id, required int qty}) async {
    await _repo.log_spoilage(
      batch_id: batch_id,
      qty: qty,
      original_purchase_cost: _purchase_cost_of(batch_id),
    );
    await _reload();
  }

  double _purchase_cost_of(String batch_id) {
    final snapshot = state.valueOrNull;
    if (snapshot == null) return 0;
    for (final row in snapshot.ledger) {
      if (row.batch_id == batch_id && row.transaction_type == TransactionType.purchase) {
        return row.unit_price;
      }
    }
    return 0;
  }

  /// Money received from a customer. Lowers their balance on the next invoice.
  Future<void> receive_payment({
    required String customer_id,
    required double amount,
  }) async {
    await _repo.add_payment(customer_id: customer_id, amount: amount);
    await _reload();
  }

  /// Paid (purchase invoice) or received (sales invoice) against one invoice.
  Future<void> record_invoice_payment({
    required String transaction_id,
    required double amount,
  }) async {
    await _repo.record_invoice_payment(transaction_id: transaction_id, amount: amount);
    await _reload();
  }

  /// Picked Up: the sales go in as one invoice, then the customer's open rows close.
  Future<void> complete_pickup({
    required String customer_id,
    required DateTime pickup_date,
    required List<PickupAllocation> allocations,
  }) async {
    if (allocations.isNotEmpty) {
      await _repo.save_sales_invoice(customer_id: customer_id, lines: allocations, received: 0);
    }
    await _repo.mark_need_list_done(customer_id: customer_id, pickup_date: pickup_date);
    await _reload();
  }

  /// A whole purchase invoice. Returns its transaction id.
  Future<String> save_purchase_invoice({
    required String vendor_id,
    required List<PurchaseLine> lines,
    double paid = 0,
  }) async {
    final transaction_id = await _repo.save_purchase_invoice(
      vendor_id: vendor_id,
      lines: lines,
      paid: paid,
    );
    await _reload();
    return transaction_id;
  }

  /// A whole sales invoice. Returns its transaction id.
  Future<String> save_sales_invoice({
    required String customer_id,
    required List<PickupAllocation> lines,
    double received = 0,
  }) async {
    final transaction_id = await _repo.save_sales_invoice(
      customer_id: customer_id,
      lines: lines,
      received: received,
    );
    await _reload();
    return transaction_id;
  }
}
