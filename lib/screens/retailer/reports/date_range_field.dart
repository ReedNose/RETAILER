import 'package:flutter/material.dart';

import '../../../core/date_helpers.dart';
import '../../../reports/report_quick_ranges.dart';
import '../../../theme/app_colors.dart';

/// Start and end pickers (inclusive) with quick picks. Empty means any date.
class DateRangeField extends StatelessWidget {
  const DateRangeField({
    super.key,
    required this.start,
    required this.end,
    required this.on_changed,
  });

  final DateTime? start;
  final DateTime? end;
  final void Function(DateTime? start, DateTime? end) on_changed;

  Future<void> _pick(BuildContext context, {required bool is_start}) async {
    final current = is_start ? start : end;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    final day = date_only(picked);
    // Keep the range valid: moving start past end pulls end along, and vice versa.
    if (is_start) {
      final end_now = end;
      on_changed(day, end_now != null && end_now.isBefore(day) ? day : end_now);
    } else {
      final start_now = start;
      on_changed(start_now != null && start_now.isAfter(day) ? day : start_now, day);
    }
  }

  void _quick(DateSpan span) => on_changed(span.start, span.end);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 6),
          child: Text('Date range',
              style: TextStyle(color: AppColors.ink_soft, fontSize: 12)),
        ),
        Row(
          children: [
            Expanded(
              child: _DateBox(
                label: 'From',
                value: start,
                onTap: () => _pick(context, is_start: true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _DateBox(
                label: 'To',
                value: end,
                onTap: () => _pick(context, is_start: false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionChip(
              label: const Text('Today'),
              onPressed: () => _quick(quick_range_today(now)),
            ),
            ActionChip(
              label: const Text('This week'),
              onPressed: () => _quick(quick_range_this_week(now)),
            ),
            ActionChip(
              label: const Text('This month'),
              onPressed: () => _quick(quick_range_this_month(now)),
            ),
            ActionChip(
              label: const Text('Any date'),
              onPressed: () => on_changed(null, null),
            ),
          ],
        ),
      ],
    );
  }
}

class _DateBox extends StatelessWidget {
  const _DateBox({required this.label, required this.value, required this.onTap});

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? 'Any'
        : '${value!.day.toString().padLeft(2, '0')}/${value!.month.toString().padLeft(2, '0')}/${value!.year}';
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.ink_soft, fontSize: 11)),
              Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
