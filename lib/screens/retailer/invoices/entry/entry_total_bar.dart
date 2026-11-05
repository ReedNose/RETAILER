import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../invoices/format_dollars.dart';
import '../../../../theme/app_colors.dart';

/// Bottom bar: the amount, an optional "paid / received now" box, and the
/// green Save button. Same family as the preorder Send Order bar.
class EntryTotalBar extends StatelessWidget {
  const EntryTotalBar({
    super.key,
    required this.total,
    required this.payment_label,
    required this.payment_controller,
    required this.save_label,
    required this.is_saving,
    required this.on_changed,
    required this.on_save,
  });

  final double total;
  final String payment_label; // "Paid now" or "Received now"
  final TextEditingController payment_controller;
  final String save_label;
  final bool is_saving;
  final VoidCallback on_changed;
  final VoidCallback on_save;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.line)),
        boxShadow: [
          BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(payment_label,
                      style: const TextStyle(color: AppColors.ink_soft, fontSize: 14)),
                ),
                SizedBox(
                  width: 128,
                  child: TextField(
                    controller: payment_controller,
                    textAlign: TextAlign.right,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                    onChanged: (_) => on_changed(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      prefixText: '\$ ',
                      isDense: true,
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Amount',
                          style: TextStyle(color: AppColors.ink_soft, fontSize: 12)),
                      Text(format_dollars(total),
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                          )),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: is_saving ? null : on_save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: is_saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(save_label,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 16)),
                            const SizedBox(width: 8),
                            const Icon(Icons.check_rounded, size: 20),
                          ],
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
