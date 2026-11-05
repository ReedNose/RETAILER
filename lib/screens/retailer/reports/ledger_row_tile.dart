import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../invoices/format_dollars.dart';
import '../../../models/ledger_row.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_style.dart';
import '../../../widgets/shared/app_card.dart';

String transaction_type_label(TransactionType type) => switch (type) {
      TransactionType.sale => 'Sale',
      TransactionType.purchase => 'Purchase',
      TransactionType.spoilage => 'Spoilage',
    };

/// One ledger row, so every number on a report can be traced back to it.
class LedgerRowTile extends StatelessWidget {
  const LedgerRowTile({
    super.key,
    required this.row,
    required this.party_name,
    required this.product_name,
  });

  final LedgerRow row;
  final String party_name;
  final String product_name;

  @override
  Widget build(BuildContext context) {
    final color = switch (row.transaction_type) {
      TransactionType.sale => AppColors.fresh,
      TransactionType.purchase => AppColors.accent,
      TransactionType.spoilage => AppColors.priority,
    };
    final icon = switch (row.transaction_type) {
      TransactionType.sale => Icons.north_east_rounded,
      TransactionType.purchase => Icons.south_west_rounded,
      TransactionType.spoilage => Icons.delete_outline_rounded,
    };
    final qty_text = '${row.qty.abs()} × ${format_dollars(row.unit_price)}';

    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon: icon, color: color, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(party_name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text('$product_name · $qty_text',
                    style: const TextStyle(color: AppColors.ink_soft, fontSize: 12)),
                Text(
                  '${DateFormat('d MMM').format(row.date)} · '
                  '${transaction_type_label(row.transaction_type)} · ${row.batch_id}',
                  style: TextStyle(
                      color: color, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Text(format_dollars(row.total_amount),
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontFeatures: money_features)),
        ],
      ),
    );
  }
}
