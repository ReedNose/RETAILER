import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';

/// Always-visible  -  n  +  pill: soft gray track, two white round buttons.
/// The minus is dimmed at 0 so the card never changes size.
class QuantityPill extends StatelessWidget {
  const QuantityPill({
    super.key,
    required this.qty,
    required this.on_increment,
    required this.on_decrement,
  });

  final int qty;
  final VoidCallback on_increment;
  final VoidCallback on_decrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _RoundButton(
            icon: Icons.remove_rounded,
            is_enabled: qty > 0,
            on_tap: on_decrement,
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Text(
              '$qty',
              key: ValueKey(qty),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          _RoundButton(icon: Icons.add_rounded, is_enabled: true, on_tap: on_increment),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.is_enabled,
    required this.on_tap,
  });

  final IconData icon;
  final bool is_enabled;
  final VoidCallback on_tap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: is_enabled
          ? () {
              HapticFeedback.selectionClick();
              on_tap();
            }
          : null,
      child: Opacity(
        opacity: is_enabled ? 1 : 0.3,
        child: Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: AppColors.card,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Color(0x1A000000), blurRadius: 2, offset: Offset(0, 1)),
            ],
          ),
          child: Icon(icon, size: 20, color: AppColors.ink),
        ),
      ),
    );
  }
}
