import '../models/pickup_allocation.dart';
import '../models/warehouse_batch.dart';

/// Fills a need from batches, oldest first, so Day 2 stock goes out before fresh.
/// Returns less than [qty] when stock runs short; the screen shows the gap.
List<PickupAllocation> suggest_allocations({
  required List<WarehouseBatch> batches,
  required int qty,
  required double unit_price,
}) {
  final oldest_first = [...batches]
    ..sort((a, b) => a.batch_date.compareTo(b.batch_date));
  final picks = <PickupAllocation>[];
  var remaining = qty;
  for (final batch in oldest_first) {
    if (remaining <= 0) break;
    final take = remaining < batch.current_qty ? remaining : batch.current_qty;
    if (take <= 0) continue;
    picks.add(PickupAllocation(
      batch_id: batch.batch_id,
      qty: take,
      unit_price: unit_price,
    ));
    remaining -= take;
  }
  return picks;
}
