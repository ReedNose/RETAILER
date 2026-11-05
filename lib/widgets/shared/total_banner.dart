import 'package:flutter/material.dart';

import '../../invoices/format_dollars.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_style.dart';

/// "Sale total  $17.50", shown under a form once the numbers are filled in.
class TotalBanner extends StatelessWidget {
  const TotalBanner({super.key, required this.label, required this.amount});

  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.accent_tint,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          ),
          Text(
            format_dollars(amount),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: AppColors.accent,
              fontFeatures: money_features,
            ),
          ),
        ],
      ),
    );
  }
}
