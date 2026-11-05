import 'package:flutter/material.dart';

import '../../../core/batch_freshness.dart';
import '../../../invoices/format_dollars.dart';
import '../../../models/product.dart';
import '../../../models/warehouse_batch.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/shared/app_card.dart';

/// One batch on the shelf. Day 2 (priority) batches get the orange warning style.
/// [bought_qty] is what the batch started with, so the bar shows how much is left.
class InventoryBatchCard extends StatelessWidget {
  const InventoryBatchCard({
    super.key,
    required this.batch,
    required this.product,
    required this.today,
    required this.on_spoil,
    this.bought_qty,
  });

  final WarehouseBatch batch;
  final Product? product;
  final DateTime today;
  final VoidCallback on_spoil;
  final int? bought_qty;

  @override
  Widget build(BuildContext context) {
    final item = product;
    final priority = is_priority_batch(
      batch_date: batch.batch_date,
      shelf_life_days: item?.shelf_life_days ?? 2,
      today: today,
    );
    final accent = priority ? AppColors.priority : AppColors.fresh;
    final age = batch_age_label(batch.batch_date, today);
    final price_text = item == null ? '' : '  ·  ${format_dollars(item.default_retail_price)} each';
    final started = bought_qty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        color: priority ? AppColors.priority_bg : AppColors.card,
        border_color: priority ? accent.withAlpha(90) : AppColors.line,
        padding: const EdgeInsets.fromLTRB(14, 14, 10, 8),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: priority ? AppColors.card : AppColors.background,
                    shape: BoxShape.circle,
                  ),
                  child: Text(item?.emoji ?? '📦', style: const TextStyle(fontSize: 26)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item?.name ?? batch.sku,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text('${batch.batch_id}$price_text',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.ink_soft, fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${batch.current_qty}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                    const Text('left',
                        style: TextStyle(color: AppColors.ink_soft, fontSize: 11)),
                  ],
                ),
                const SizedBox(width: 4),
              ],
            ),
            if (started != null && started > 0) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: SoftBar(value: batch.current_qty / started, color: accent),
              ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                StatusPill(
                  text: priority ? 'DAY 2  ·  SELL FIRST' : age,
                  color: accent,
                  icon: priority
                      ? Icons.local_fire_department_rounded
                      : Icons.eco_rounded,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: on_spoil,
                  style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Spoil'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
