// The ONLY thing the UI talks to. Two implementations: HttpRetailRepository (the Apps Script
// backend) and MockRetailRepository (in memory, for demos). A whole invoice is one call,
// so the backend saves all of it or none of it.
import '../models/app_user.dart';
import '../models/pickup_allocation.dart';
import '../models/purchase_line.dart';
import '../state/retail_snapshot.dart';

/// Thrown by sign_in when no user has that PIN.
class WrongPin implements Exception {
  const WrongPin();
}

abstract class RetailRepository {
  /// Checks a PIN and returns the user it belongs to. Throws WrongPin when nobody has it.
  Future<AppUser> sign_in(String pin);

  /// Forgets the signed-in user and any PIN kept for later calls.
  void sign_out();

  /// Everything this user may see, read in one call.
  Future<RetailSnapshot> fetch_snapshot();

  /// Customer sends (or resends) the list for one pickup day. Never touches stock.
  Future<void> add_need_list_rows({
    required String customer_id,
    required DateTime pickup_date,
    required Map<String, int> qty_by_sku,
  });

  /// Retailer taps Picked Up: closes this customer's open rows for the day.
  Future<void> mark_need_list_done({
    required String customer_id,
    required DateTime pickup_date,
  });

  /// One purchase invoice. Every line becomes a batch; all lines share one transaction id,
  /// which is returned.
  Future<String> save_purchase_invoice({
    required String vendor_id,
    required List<PurchaseLine> lines,
    required double paid,
  });

  /// One sales invoice. Every line takes stock from its named batch; all share one
  /// transaction id, which is returned.
  Future<String> save_sales_invoice({
    required String customer_id,
    required List<PickupAllocation> lines,
    required double received,
  });

  /// Expired or damaged stock, valued at the batch's purchase cost.
  Future<void> log_spoilage({
    required String batch_id,
    required int qty,
    required double original_purchase_cost,
  });

  /// Money received from a customer. Lowers their balance.
  Future<void> add_payment({
    required String customer_id,
    required double amount,
  });

  /// Paid (purchase) or received (sale) against one invoice, capped at what is open.
  Future<void> record_invoice_payment({
    required String transaction_id,
    required double amount,
  });
}
