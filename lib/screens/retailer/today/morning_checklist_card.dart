import 'package:flutter/material.dart';

import '../../../models/morning_checklist_line.dart';
import '../../../state/retail_snapshot.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/shared/app_card.dart';

/// Needed vs in stock vs to prep, per product, for today's pickups.
/// Each product shows how much of the need the shelf already covers.
class MorningChecklistCard extends StatelessWidget {
  const MorningChecklistCard({
    super.key,
    required this.lines,
    required this.snapshot,
  });

  final List<MorningChecklistLine> lines;
  final RetailSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      shadow: true,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text('Morning checklist',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
              Icon(Icons.wb_sunny_rounded, color: AppColors.priority),
            ],
          ),
          const SizedBox(height: 14),
          if (lines.isEmpty)
            const Text('Nothing to prep. No open need-lists for today.',
                style: TextStyle(color: AppColors.ink_soft)),
          for (var i = 0; i < lines.length; i++) ...[
            if (i > 0) const Divider(height: 22),
            _ChecklistRow(line: lines[i], product_name: _name_for(lines[i].sku)),
          ],
        ],
      ),
    );
  }

  String _name_for(String sku) {
    final product = snapshot.product_by_sku(sku);
    return product == null ? sku : '${product.emoji} ${product.name}';
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.line, required this.product_name});

  final MorningChecklistLine line;
  final String product_name;

  @override
  Widget build(BuildContext context) {
    final to_buy = line.to_buy_or_prep;
    final is_ready = to_buy <= 0;
    final color = is_ready ? AppColors.fresh : AppColors.priority;
    final covered = line.needed == 0 ? 1.0 : line.in_stock / line.needed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(product_name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            ),
            StatusPill(
              text: is_ready ? 'Ready' : 'Prep $to_buy',
              color: color,
              icon: is_ready ? Icons.check_rounded : null,
            ),
          ],
        ),
        const SizedBox(height: 8),
        SoftBar(value: covered, color: color),
        const SizedBox(height: 5),
        Text('Need ${line.needed}  ·  In stock ${line.in_stock}',
            style: const TextStyle(color: AppColors.ink_soft, fontSize: 12)),
      ],
    );
  }
}
