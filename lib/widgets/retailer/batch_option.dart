import '../../core/batch_freshness.dart';
import '../../models/product.dart';
import '../../models/warehouse_batch.dart';
import '../shared/searchable_option.dart';

/// One batch in a picker. Day 2 batches are flagged so the retailer takes them first.
SearchableOption<String> batch_option({
  required WarehouseBatch batch,
  required Product? product,
  required DateTime today,
}) {
  final priority = is_priority_batch(
    batch_date: batch.batch_date,
    shelf_life_days: product?.shelf_life_days ?? 2,
    today: today,
  );
  final age = batch_age_label(batch.batch_date, today);
  return SearchableOption<String>(
    value: batch.batch_id,
    label: '${batch.batch_id} · ${batch.current_qty} units',
    subtitle: priority ? '⚠️ DAY 2 PRIORITY · $age' : age,
    leading: product?.emoji,
  );
}
