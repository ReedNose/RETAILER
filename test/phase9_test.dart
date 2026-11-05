import 'package:flutter_test/flutter_test.dart';
import 'package:retail_preorder_app/core/greeting.dart';
import 'package:retail_preorder_app/state/cart_providers.dart';
import 'package:retail_preorder_app/state/retail_providers.dart';

import 'test_support.dart';

void main() {
  test('greeting follows the hour', () {
    expect(greeting_for(DateTime(2026, 11, 5, 8)), 'Good morning');
    expect(greeting_for(DateTime(2026, 11, 5, 13)), 'Good afternoon');
    expect(greeting_for(DateTime(2026, 11, 5, 20)), 'Good evening');
  });

  test('cart set_all replaces the cart and caps quantities', () {
    final container = demo_container();
    addTearDown(container.dispose);
    final cart = container.read(cart_provider.notifier);

    cart.increment('ML');
    cart.set_all({'BR': 2, 'EG': 0, 'JU': 500});
    final items = container.read(cart_provider);
    expect(items.containsKey('ML'), isFalse);
    expect(items.containsKey('EG'), isFalse);
    expect(items['BR'], 2);
    expect(items['JU'], CartNotifier.max_qty_per_item);

    cart.remove('BR');
    expect(container.read(cart_provider).containsKey('BR'), isFalse);
  });

  test('snapshot helpers: priority batches and shelf totals', () async {
    final container = demo_container();
    addTearDown(container.dispose);
    final snapshot = await container.read(retail_store_provider.future);

    final priority = snapshot.priority_batches(DateTime.now());
    expect(priority, isNotEmpty);
    expect(snapshot.units_on_shelf, greaterThan(0));
    expect(snapshot.shelf_retail_value, greaterThan(0));
  });
}
