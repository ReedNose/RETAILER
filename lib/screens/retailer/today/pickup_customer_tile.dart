import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/shared/app_card.dart';
import '../pickup/pickup_screen.dart';

/// One customer waiting for pickup today. Tap to open the Picked Up flow.
class PickupCustomerTile extends StatelessWidget {
  const PickupCustomerTile({
    super.key,
    required this.customer_id,
    required this.customer_name,
    required this.item_count,
    required this.pickup_date,
    this.summary = '',
  });

  final String customer_id;
  final String customer_name;
  final int item_count;
  final DateTime pickup_date;
  final String summary; // "🥛×3  🍞×2"

  @override
  Widget build(BuildContext context) {
    final initial = customer_name.isEmpty ? '?' : customer_name[0].toUpperCase();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        on_tap: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => PickupScreen(
            customer_id: customer_id,
            pickup_date: pickup_date,
          ),
        )),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.brand.withAlpha(31),
              child: Text(initial,
                  style: const TextStyle(
                      color: AppColors.brand_dark,
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customer_name,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    summary.isEmpty
                        ? '$item_count ${item_count == 1 ? 'item' : 'items'}'
                        : summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.ink_soft, fontSize: 13),
                  ),
                ],
              ),
            ),
            StatusPill(
              text: '$item_count ${item_count == 1 ? 'item' : 'items'}',
              color: AppColors.brand_dark,
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: AppColors.ink_faint),
          ],
        ),
      ),
    );
  }
}
