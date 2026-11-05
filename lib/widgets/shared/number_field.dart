import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';

/// Number-only box. Whole numbers for quantities, decimals for prices.
class NumberField extends StatelessWidget {
  const NumberField({
    super.key,
    required this.label,
    required this.controller,
    this.decimal = false,
    this.on_changed,
    this.width,
  });

  final String label;
  final TextEditingController controller;
  final bool decimal;
  final VoidCallback? on_changed;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: [
        FilteringTextInputFormatter.allow(decimal ? RegExp(r'[0-9.,]') : RegExp(r'[0-9]')),
      ],
      textAlign: TextAlign.center,
      onChanged: (_) => on_changed?.call(),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
    return width == null ? field : SizedBox(width: width, child: field);
  }
}
