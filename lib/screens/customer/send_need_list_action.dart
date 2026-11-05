import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_config.dart';
import '../../core/date_helpers.dart';
import '../../core/whatsapp_message.dart';
import '../../models/app_user.dart';
import '../../services/whatsapp_launcher.dart';
import '../../state/cart_providers.dart';
import '../../state/retail_providers.dart';
import '../../theme/app_colors.dart';

/// "Send Order": 1) silent save to need_list, 2) WhatsApp handoff.
/// The save happens first, so the retailer has the order even if WhatsApp fails.
Future<void> send_need_list_action({
  required BuildContext context,
  required WidgetRef ref,
  required AppUser user,
}) async {
  final cart = Map<String, int>.from(ref.read(cart_provider));
  final snapshot = ref.read(retail_store_provider).valueOrNull;
  final customer_id = user.customer_id;
  if (cart.isEmpty || snapshot == null || customer_id == null) return;
  if (ref.read(is_sending_provider)) return; // double-tap guard

  ref.read(is_sending_provider.notifier).state = true;
  final messenger = ScaffoldMessenger.of(context);
  try {
    // Need-lists are for next-day pickup.
    final pickup_date = date_only(DateTime.now().add(const Duration(days: 1)));

    await ref.read(retail_store_provider.notifier).send_need_list(
          customer_id: customer_id,
          pickup_date: pickup_date,
          qty_by_sku: cart,
        );

    // Build the message in the shop's product order, not tap order.
    final lines = <NeedLine>[
      for (final p in snapshot.products)
        if (cart.containsKey(p.sku))
          (emoji: p.emoji, name: p.name, qty: cart[p.sku]!),
    ];
    final customer_name = snapshot.customer_name(customer_id);
    final message = build_need_list_message(
      customer_name: customer_name,
      pickup_date: pickup_date,
      lines: lines,
    );

    ref.read(cart_provider.notifier).clear();
    HapticFeedback.mediumImpact();
    final opened = await open_whatsapp(
      phone_no: retailer_whatsapp_no,
      message: message,
    );

    messenger.showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(
            opened ? Icons.check_circle_rounded : Icons.info_rounded,
            color: opened ? AppColors.brand : AppColors.priority,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(opened
                ? 'Order saved. Finish by pressing send in WhatsApp.'
                : "Order saved, but WhatsApp couldn't open."),
          ),
        ],
      ),
    ));
  } catch (error) {
    messenger.showSnackBar(SnackBar(content: Text('Could not send the order: $error')));
  } finally {
    ref.read(is_sending_provider.notifier).state = false;
  }
}
