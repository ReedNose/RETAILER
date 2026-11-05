import 'package:flutter_riverpod/flutter_riverpod.dart';

/// sku -> qty. Lives only in memory until "Send Order".
class CartNotifier extends Notifier<Map<String, int>> {
  static const max_qty_per_item = 99;

  @override
  Map<String, int> build() => {};

  void increment(String sku) {
    final current = state[sku] ?? 0;
    if (current >= max_qty_per_item) return;
    state = {...state, sku: current + 1};
  }

  void decrement(String sku) {
    final current = state[sku] ?? 0;
    if (current <= 1) {
      state = {...state}..remove(sku);
    } else {
      state = {...state, sku: current - 1};
    }
  }

  /// Replaces the whole cart, for "change my order".
  void set_all(Map<String, int> items) {
    state = {
      for (final entry in items.entries)
        if (entry.value > 0)
          entry.key: entry.value > max_qty_per_item ? max_qty_per_item : entry.value,
    };
  }

  void remove(String sku) {
    if (!state.containsKey(sku)) return;
    state = {...state}..remove(sku);
  }

  void clear() => state = {};
}

final cart_provider =
    NotifierProvider<CartNotifier, Map<String, int>>(CartNotifier.new);

final cart_item_count_provider = Provider<int>(
  (ref) => ref.watch(cart_provider).values.fold(0, (sum, qty) => sum + qty),
);

/// True while an order is being saved, so a double tap cannot send it twice.
final is_sending_provider = StateProvider<bool>((ref) => false);
