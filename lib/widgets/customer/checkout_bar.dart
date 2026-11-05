import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Bottom bar with the item count and a green Send Order button. No prices.
/// Slides up when the cart has items, slides away when it is empty.
/// Tapping the count opens the order review.
class CheckoutBar extends StatelessWidget {
  const CheckoutBar({
    super.key,
    required this.item_count,
    required this.is_sending,
    required this.on_send,
    required this.on_review,
  });

  final int item_count;
  final bool is_sending;
  final VoidCallback on_send;
  final VoidCallback on_review;

  @override
  Widget build(BuildContext context) {
    final is_visible = item_count > 0;

    return IgnorePointer(
      ignoring: !is_visible,
      child: AnimatedSlide(
        offset: is_visible ? Offset.zero : const Offset(0, 1.5),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: is_visible ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
            decoration: const BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: AppColors.line)),
              boxShadow: [
                BoxShadow(color: Color(0x140F172A), blurRadius: 20, offset: Offset(0, -6)),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: on_review,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$item_count ${item_count == 1 ? 'item' : 'items'}',
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                            ),
                          ),
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Review order',
                                  style: TextStyle(
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                              Icon(Icons.keyboard_arrow_up_rounded,
                                  size: 18, color: AppColors.accent),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: is_sending ? null : on_send,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: is_sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Send Order',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
