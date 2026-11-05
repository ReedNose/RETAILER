import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../theme/app_colors.dart';
import 'quantity_pill.dart';

/// No price on purpose: fewer things to think about means a faster order.
class ProductCard extends StatefulWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.stock,
    required this.qty,
    required this.on_increment,
    required this.on_decrement,
  });

  final Product product;
  final int stock; // total across batches, informational only
  final int qty;
  final VoidCallback on_increment;
  final VoidCallback on_decrement;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _is_pressed = false;

  @override
  Widget build(BuildContext context) {
    final in_cart = widget.qty > 0;
    final stock_text =
        widget.stock > 0 ? '${widget.stock} in stock' : "We'll get it for you";

    return GestureDetector(
      // Tapping the card body adds one; the pill handles the rest.
      onTapDown: (_) => setState(() => _is_pressed = true),
      onTapUp: (_) => setState(() => _is_pressed = false),
      onTapCancel: () => setState(() => _is_pressed = false),
      onTap: widget.on_increment,
      child: AnimatedScale(
        scale: _is_pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
          decoration: BoxDecoration(
            color: in_cart ? AppColors.accent_tint : AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: in_cart ? AppColors.accent : AppColors.line,
              width: in_cart ? 1.5 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x0D000000), blurRadius: 4, offset: Offset(0, 1)),
            ],
          ),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: in_cart ? AppColors.card : AppColors.background,
                      shape: BoxShape.circle,
                    ),
                    child: Text(widget.product.emoji, style: const TextStyle(fontSize: 32)),
                  ),
                  Positioned(
                    top: -2,
                    right: -10,
                    child: AnimatedScale(
                      scale: in_cart ? 1 : 0,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutBack,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        child: Text('${widget.qty}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.product.name,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: widget.stock > 0 ? AppColors.fresh : AppColors.ink_soft,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      stock_text,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.ink_soft, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              QuantityPill(
                qty: widget.qty,
                on_increment: widget.on_increment,
                on_decrement: widget.on_decrement,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
