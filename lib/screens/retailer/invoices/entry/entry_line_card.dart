import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../invoices/format_dollars.dart';
import '../../../../models/product.dart';
import '../../../../theme/app_colors.dart';
import 'entry_line.dart';
import 'entry_qty_stepper.dart';

/// One item of the invoice: product, (batch), quantity, price and the amount.
/// White card, hairline border, soft shadow, like the preorder cards.
class EntryLineCard extends StatelessWidget {
  const EntryLineCard({
    super.key,
    required this.line,
    required this.product,
    required this.price_label,
    required this.on_pick_product,
    required this.on_remove,
    required this.on_changed,
    this.hint,
    this.batch_label,
    this.batch_is_priority = false,
    this.on_pick_batch,
  });

  final EntryLine line;
  final Product? product;
  final String price_label; // "Unit cost" or "Unit price"
  final VoidCallback on_pick_product;
  final VoidCallback on_remove;
  final VoidCallback on_changed;
  final String? hint; // small grey line under the name
  final String? batch_label; // sales only
  final bool batch_is_priority;
  final VoidCallback? on_pick_batch;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
        boxShadow: const [
          BoxShadow(color: Color(0x0D000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.accent_tint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(product?.emoji ?? '📦', style: const TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: on_pick_product,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product?.name ?? line.sku,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        if (hint != null)
                          Text(hint!,
                              style: const TextStyle(color: AppColors.ink_soft, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Remove item',
                onPressed: on_remove,
                icon: const Icon(Icons.close_rounded, color: AppColors.ink_soft),
              ),
            ],
          ),
          if (batch_label != null) ...[
            const SizedBox(height: 12),
            Material(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: on_pick_batch,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 18, color: AppColors.ink_soft),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(batch_label!,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                      if (batch_is_priority)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.priority_bg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('DAY 2',
                              style: TextStyle(
                                color: AppColors.priority,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              )),
                        ),
                      const Icon(Icons.unfold_more_rounded, size: 20, color: AppColors.ink_soft),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: EntryQtyStepper(controller: line.qty_controller, on_changed: on_changed),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 112,
                child: TextField(
                  controller: line.price_controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                  onChanged: (_) => on_changed(),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    labelText: price_label,
                    prefixText: '\$ ',
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Divider(height: 1, color: AppColors.line),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Amount',
                      style: TextStyle(color: AppColors.ink_soft, fontSize: 13)),
                ),
                Text(format_dollars(line.amount),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
