import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';

/// The row of dots that fills in as the PIN is typed.
class PinDots extends StatelessWidget {
  const PinDots({
    super.key,
    required this.length,
    required this.filled,
    this.has_error = false,
  });

  final int length;
  final int filled;
  final bool has_error;

  @override
  Widget build(BuildContext context) {
    final color = has_error ? AppColors.danger : AppColors.accent;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < length; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 9),
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < filled ? color : Colors.transparent,
              border: Border.all(
                color: (i < filled || has_error) ? color : AppColors.ink_faint,
                width: 1.6,
              ),
            ),
          ),
      ],
    );
  }
}

/// Big round number keys, so signing in never needs the system keyboard.
class PinPad extends StatelessWidget {
  const PinPad({
    super.key,
    required this.on_digit,
    required this.on_delete,
    this.enabled = true,
  });

  final ValueChanged<String> on_digit;
  final VoidCallback on_delete;
  final bool enabled;

  static const _key_size = 72.0;
  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
  ];

  Widget _digit_key(String digit) => _PadKey(
        semantic_label: digit,
        on_tap: enabled ? () => on_digit(digit) : null,
        child: Text(digit,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600)),
      );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 288,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final row in _rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [for (final digit in row) _digit_key(digit)],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: _key_size, height: _key_size),
              _digit_key('0'),
              _PadKey(
                semantic_label: 'Delete',
                plain: true,
                on_tap: enabled ? on_delete : null,
                child: const Icon(Icons.backspace_outlined, color: AppColors.ink_soft),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PadKey extends StatelessWidget {
  const _PadKey({
    required this.child,
    required this.on_tap,
    required this.semantic_label,
    this.plain = false,
  });

  final Widget child;
  final VoidCallback? on_tap;
  final String semantic_label;
  final bool plain;

  @override
  Widget build(BuildContext context) {
    final tap = on_tap;
    return Semantics(
      button: true,
      label: semantic_label,
      child: Material(
        color: plain ? Colors.transparent : AppColors.card,
        shape: CircleBorder(
          side: plain ? BorderSide.none : const BorderSide(color: AppColors.line),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: tap == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  tap();
                },
          child: SizedBox(
            width: PinPad._key_size,
            height: PinPad._key_size,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
