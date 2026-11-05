import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/product.dart';
import '../../state/cart_providers.dart';
import '../../state/retail_providers.dart';
import '../../theme/app_colors.dart';
import 'quantity_pill.dart';

/// Opens the order review. [on_send] runs after the sheet closes.
Future<void> show_order_review_sheet({
  required BuildContext context,
  required String pickup_label,
  required VoidCallback on_send,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheet_context) =>
        OrderReviewSheet(pickup_label: pickup_label, on_send: on_send),
  );
}

/// Everything in the cart, with the same + and - pills, before it is sent.
class OrderReviewSheet extends ConsumerWidget {
  const OrderReviewSheet({
    super.key,
    required this.pickup_label,
    required this.on_send,
  });

  final String pickup_label;
  final VoidCallback on_send;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cart_provider);
    final snapshot = ref.watch(retail_store_provider).valueOrNull;
    final is_sending = ref.watch(is_sending_provider);
    final products = snapshot == null
        ? const <Product>[]
        : <Product>[
            for (final p in snapshot.products)
              if (cart.containsKey(p.sku)) p,
          ];
    final total = cart.values.fold(0, (sum, qty) => sum + qty);

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your order',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.event_rounded, size: 16, color: AppColors.ink_soft),
                  const SizedBox(width: 6),
                  Text(pickup_label,
                      style: const TextStyle(color: AppColors.ink_soft, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 12),
              if (products.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text('Nothing here yet. Close this and tap a product.',
                        style: TextStyle(color: AppColors.ink_soft)),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: products.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: AppColors.background,
                                shape: BoxShape.circle,
                              ),
                              child: Text(product.emoji, style: const TextStyle(fontSize: 24)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(product.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600, fontSize: 15)),
                            ),
                            SizedBox(
                              width: 128,
                              child: QuantityPill(
                                qty: cart[product.sku] ?? 0,
                                on_increment: () =>
                                    ref.read(cart_provider.notifier).increment(product.sku),
                                on_decrement: () =>
                                    ref.read(cart_provider.notifier).decrement(product.sku),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: (products.isEmpty || is_sending)
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          on_send();
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    products.isEmpty
                        ? 'Send Order'
                        : 'Send Order · $total ${total == 1 ? 'item' : 'items'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
