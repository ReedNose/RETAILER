import 'package:flutter_test/flutter_test.dart';
import 'package:retail_preorder_app/core/whatsapp_message.dart';
import 'package:retail_preorder_app/state/cart_providers.dart';
import 'package:retail_preorder_app/state/retail_providers.dart';
import 'test_support.dart';

void main() {
  test('cart adds, removes, and drops a sku at zero', () {
    final container = demo_container();
    addTearDown(container.dispose);
    final cart = container.read(cart_provider.notifier);

    cart.increment('ML');
    cart.increment('ML');
    cart.increment('BR');
    expect(container.read(cart_item_count_provider), 3);

    cart.decrement('ML');
    cart.decrement('ML');
    expect(container.read(cart_provider).containsKey('ML'), isFalse);
    expect(container.read(cart_item_count_provider), 1);
  });

  test('whatsapp message lists items and total', () {
    final text = build_need_list_message(
      customer_name: 'Maria Santos',
      pickup_date: DateTime(2026, 11, 5),
      lines: [
        (emoji: '🥛', name: 'Whole Milk', qty: 2),
        (emoji: '🍞', name: 'Sourdough Bread', qty: 1),
      ],
    );
    expect(text, contains('Maria Santos'));
    expect(text, contains('Whole Milk x 2'));
    expect(text, contains('Total: 3 items'));
  });

  test('sending a need-list saves rows without changing stock', () async {
    final container = demo_container();
    addTearDown(container.dispose);
    final before = await container.read(retail_store_provider.future);

    await container.read(retail_store_provider.notifier).send_need_list(
          customer_id: 'C001',
          pickup_date: DateTime(2026, 11, 5),
          qty_by_sku: {'ML': 2, 'EG': 1},
        );

    final after = await container.read(retail_store_provider.future);
    expect(after.need_list.length, before.need_list.length + 2);
    expect(after.total_stock_for_sku('ML'), before.total_stock_for_sku('ML'));
    expect(after.ledger.length, before.ledger.length);
  });
}
