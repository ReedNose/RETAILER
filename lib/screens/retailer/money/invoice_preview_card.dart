import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/app_config.dart';
import '../../../invoices/format_dollars.dart';
import '../../../invoices/invoice_models.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_style.dart';
import '../../../widgets/shared/app_card.dart';

/// On-screen preview of exactly what the PDF will say.
class InvoicePreviewCard extends StatelessWidget {
  const InvoicePreviewCard({super.key, required this.invoice});

  final InvoiceData invoice;

  @override
  Widget build(BuildContext context) {
    final owes = invoice.new_balance > 0.005;
    return AppCard(
      shadow: true,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.accent_tint,
              borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(shop_name,
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(invoice.invoice_number,
                          style: const TextStyle(color: AppColors.ink_soft, fontSize: 12)),
                    ],
                  ),
                ),
                const StatusPill(text: 'INVOICE', color: AppColors.accent),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Billed to',
                    style: TextStyle(color: AppColors.ink_soft, fontSize: 12)),
                Text(invoice.customer_name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                Text(DateFormat('EEEE, d MMM yyyy').format(invoice.date),
                    style: const TextStyle(color: AppColors.ink_soft, fontSize: 13)),
                const SizedBox(height: 14),
                for (final line in invoice.lines) _LineRow(line: line),
                const Divider(height: 26),
                _AmountRow(label: 'Grand total', amount: invoice.grand_total, is_bold: true),
                _AmountRow(label: 'Old balance', amount: invoice.old_balance),
                _AmountRow(label: 'Payments received', amount: -invoice.payments_received),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: owes ? AppColors.priority_bg : AppColors.brand_tint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text('New balance',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      ),
                      Text(
                        format_dollars(invoice.new_balance),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          fontFeatures: money_features,
                          color: owes ? AppColors.priority : AppColors.fresh,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({required this.line});

  final InvoiceLine line;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.product_name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('${line.qty} × ${format_dollars(line.unit_price)}',
                    style: const TextStyle(color: AppColors.ink_soft, fontSize: 12)),
              ],
            ),
          ),
          Text(format_dollars(line.line_total),
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontFeatures: money_features)),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.amount,
    this.is_bold = false,
  });

  final String label;
  final double amount;
  final bool is_bold;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: is_bold ? FontWeight.w700 : FontWeight.w400,
      fontSize: is_bold ? 16 : 14,
      fontFeatures: money_features,
      color: is_bold ? AppColors.ink : AppColors.ink_soft,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(format_dollars(amount), style: style),
        ],
      ),
    );
  }
}
