import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/shared/app_card.dart';
import '../inventory/add_stock_screen.dart';
import '../inventory/spoilage_screen.dart';
import '../money/receive_payment_screen.dart';
import '../sales/walk_in_sale_screen.dart';

/// The four things done most often, one tap from the Today tab.
class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    void open(Widget screen) {
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
    }

    return Row(
      children: [
        Expanded(
          child: _ActionTile(
            icon: Icons.add_box_rounded,
            label: 'Add stock',
            color: AppColors.accent,
            on_tap: () => open(const AddStockScreen()),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionTile(
            icon: Icons.point_of_sale_rounded,
            label: 'Walk-in sale',
            color: AppColors.brand_dark,
            on_tap: () => open(const WalkInSaleScreen()),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionTile(
            icon: Icons.payments_rounded,
            label: 'Payment',
            color: const Color(0xFF7C3AED),
            on_tap: () => open(const ReceivePaymentScreen()),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionTile(
            icon: Icons.delete_outline_rounded,
            label: 'Spoilage',
            color: AppColors.danger,
            on_tap: () => open(const SpoilageScreen()),
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.on_tap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback on_tap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      on_tap: on_tap,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Column(
        children: [
          IconBadge(icon: icon, color: color),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
