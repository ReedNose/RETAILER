import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../theme/app_colors.dart';

/// Same look as the preorder pill (soft track, white round buttons), but the
/// number can also be typed, because purchases come in big quantities.
class EntryQtyStepper extends StatelessWidget {
  const EntryQtyStepper({
    super.key,
    required this.controller,
    required this.on_changed,
  });

  final TextEditingController controller;
  final VoidCallback on_changed;

  int get _qty => int.tryParse(controller.text.trim()) ?? 0;

  void _set(int value) {
    controller.text = '$value';
    on_changed();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _RoundButton(
            icon: Icons.remove_rounded,
            on_tap: () {
              if (_qty > 1) _set(_qty - 1);
            },
          ),
          Expanded(
            child: TextField(
              controller: controller,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => on_changed(),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          _RoundButton(icon: Icons.add_rounded, on_tap: () => _set(_qty + 1)),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.on_tap});

  final IconData icon;
  final VoidCallback on_tap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        on_tap();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: AppColors.card,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Color(0x1A000000), blurRadius: 2, offset: Offset(0, 1)),
          ],
        ),
        child: Icon(icon, size: 20, color: AppColors.ink),
      ),
    );
  }
}
