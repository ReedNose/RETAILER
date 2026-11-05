import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:retail_preorder_app/core/batch_id_generator.dart';
import 'package:retail_preorder_app/core/date_helpers.dart';
import 'package:retail_preorder_app/core/input_parsing.dart';
import 'package:retail_preorder_app/core/morning_checklist.dart';
import 'package:retail_preorder_app/core/sku_helpers.dart';
import 'package:retail_preorder_app/core/suggest_allocations.dart';
import 'package:retail_preorder_app/data/mock/mock_retail_repository.dart';
import 'package:retail_preorder_app/models/purchase_line.dart';
import 'package:retail_preorder_app/models/pickup_allocation.dart';
import 'package:retail_preorder_app/models/warehouse_batch.dart';
import 'package:retail_preorder_app/state/retail_providers.dart';
import 'test_support.dart';

void main() {
  test('generated batch_id is new and keeps its sku before the underscore', () {
    final used = {'ML_1000'};
    final id = generate_batch_id('ML', used, random: Random(1));
    expect(used.contains(id), isFalse);
    expect(sku_from_batch_id(id), 'ML');
  });

  test('suggest_allocations takes the oldest batch first and splits across batches', () {
    final batches = [
      WarehouseBatch(batch_id: 'ML_2', vendor_id: 'V001', batch_date: DateTime(2026, 11, 4), current_qty: 5),
      WarehouseBatch(batch_id: 'ML_1', vendor_id: 'V001', batch_date: DateTime(2026, 11, 3), current_qty: 3),
    ];
    final picks = suggest_allocations(batches: batches, qty: 5, unit_price: 3.5);
    expect(picks.map((p) => p.batch_id).toList(), ['ML_1', 'ML_2']);
    expect(picks.map((p) => p.qty).toList(), [3, 2]);
  });

  test('suggest_allocations returns less than asked when stock runs short', () {
    final batches = [
      WarehouseBatch(batch_id: 'BR_1', vendor_id: 'V002', batch_date: DateTime(2026, 11, 3), current_qty: 2),
    ];
    final picks = suggest_allocations(batches: batches, qty: 5, unit_price: 6.5);
    expect(picks.fold(0, (sum, p) => sum + p.qty), 2);
  });

  test('typed input is parsed strictly', () {
    expect(parse_positive_int('0'), isNull);
    expect(parse_positive_int(' 3 '), 3);
    expect(parse_money('2,5'), 2.5);
    expect(parse_money('-1'), isNull);
  });

  test('morning checklist: to prep never goes below zero', () async {
    final container = demo_container();
    addTearDown(container.dispose);
    final snapshot = await container.read(retail_store_provider.future);
    final lines = build_morning_checklist(snapshot, date_only(DateTime.now()));
    expect(lines, isNotEmpty);
    for (final line in lines) {
      expect(line.to_buy_or_prep, greaterThanOrEqualTo(0));
    }
    // Seed: Maria wants 2 milk, David wants 1; 11 milk on the shelf.
    final milk = lines.firstWhere((l) => l.sku == 'ML');
    expect(milk.needed, 3);
    expect(milk.in_stock, 11);
    expect(milk.to_buy_or_prep, 0);
  });

  test('complete_pickup sells each allocation and closes the customer rows', () async {
    final container = demo_container();
    addTearDown(container.dispose);
    final before = await container.read(retail_store_provider.future);
    final today = date_only(DateTime.now());

    await container.read(retail_store_provider.notifier).complete_pickup(
      customer_id: 'C001',
      pickup_date: today,
      allocations: const [
        PickupAllocation(batch_id: 'ML_2402', qty: 2, unit_price: 3.5),
        PickupAllocation(batch_id: 'BR_2404', qty: 1, unit_price: 6.5),
      ],
    );

    final after = container.read(retail_store_provider).requireValue;
    expect(after.open_need_rows_on(today).any((r) => r.customer_id == 'C001'), isFalse);
    expect(after.batch_by_id('ML_2402')!.current_qty, 1);
    expect(after.batch_by_id('BR_2404')!.current_qty, 5);
    expect(after.ledger.length, before.ledger.length + 2);
  });

  test('two stock-ins of the same product get different batch ids', () async {
    final repo = MockRetailRepository();
    for (var i = 0; i < 2; i++) {
      await repo.save_purchase_invoice(
        vendor_id: 'V001',
        lines: const [PurchaseLine(sku: 'ML', qty: 1, unit_cost: 1)],
        paid: 0,
      );
    }
    final batch_ids = (await repo.fetch_snapshot())
        .warehouse
        .map((b) => b.batch_id)
        .where((id) => id.startsWith('ML_'))
        .toList();
    expect(batch_ids.toSet().length, batch_ids.length);
  });
}
