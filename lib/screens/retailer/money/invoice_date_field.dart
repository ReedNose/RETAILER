import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/date_helpers.dart';
import '../../../theme/app_colors.dart';

/// One date box that opens the calendar. The invoice is for this day.
class InvoiceDateField extends StatelessWidget {
  const InvoiceDateField({super.key, required this.day, required this.on_changed});

  final DateTime day;
  final ValueChanged<DateTime> on_changed;

  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: day,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) on_changed(date_only(picked));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 6),
          child: Text('Invoice date',
              style: TextStyle(color: AppColors.ink_soft, fontSize: 12)),
        ),
        Material(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _pick(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat('EEE d MMM yyyy').format(day),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Icon(Icons.calendar_month_rounded, color: AppColors.ink_soft),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
