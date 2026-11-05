import 'package:flutter_test/flutter_test.dart';
import 'package:retail_preorder_app/core/batch_freshness.dart';
import 'package:retail_preorder_app/core/sku_helpers.dart';
import 'package:retail_preorder_app/data/mock/mock_retail_repository.dart';
import 'package:retail_preorder_app/models/pickup_allocation.dart';

void main() {
  test('sku is read from the first underscore only', () {
    expect(sku_from_batch_id('ML_2414'), 'ML');
    expect(sku_from_batch_id('ML_2414_x'), 'ML');
    expect(make_batch_id('ML', '2414'), 'ML_2414');
  });

  test('priority batch follows shelf_life_days - 1', () {
    final today = DateTime(2026, 11, 4);
    // shelf life 2: yesterday is priority, today is not
    expect(is_priority_batch(batch_date: DateTime(2026, 11, 3), shelf_life_days: 2, today: today), isTrue);
    expect(is_priority_batch(batch_date: DateTime(2026, 11, 4), shelf_life_days: 2, today: today), isFalse);
    // shelf life 3: yesterday is not yet priority
    expect(is_priority_batch(batch_date: DateTime(2026, 11, 3), shelf_life_days: 3, today: today), isFalse);
  });

  test('selling a whole batch deletes its warehouse row; ledger keeps history', () async {
    final repo = MockRetailRepository();
    final before = await repo.fetch_snapshot();
    final batch = before.warehouse.firstWhere((b) => b.batch_id == 'ML_2402');
    await repo.save_sales_invoice(
      customer_id: 'C001',
      lines: [PickupAllocation(batch_id: batch.batch_id, qty: batch.current_qty, unit_price: 3.0)],
      received: 0,
    );
    final after = await repo.fetch_snapshot();
    expect(after.warehouse.any((b) => b.batch_id == 'ML_2402'), isFalse);
    expect(after.ledger.last.total_amount, batch.current_qty * 3.0);
    expect(after.ledger.last.qty, -batch.current_qty);
  });

  test('spoilage is priced at purchase cost', () async {
    final repo = MockRetailRepository();
    await repo.log_spoilage(batch_id: 'BN_2411', qty: 1, original_purchase_cost: 1.50);
    final last = (await repo.fetch_snapshot()).ledger.last;
    expect(last.unit_price, 1.50);
    expect(last.total_amount, 1.50);
  });
}
